import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfx/pdfx.dart';

enum InvoiceImageSource { camera, file }

class InvoiceScanService {
  InvoiceScanService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Returns the file path of the chosen invoice, or null if cancelled.
  /// Camera uses [ImagePicker]; file mode uses [FilePicker] and accepts
  /// PDF, JPG, and PNG documents.
  Future<String?> pickInvoiceFilePath({
    required InvoiceImageSource source,
    int imageQuality = 85,
  }) async {
    if (source == InvoiceImageSource.camera) {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
      );
      return image?.path;
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      return result?.files.single.path;
    }
  }

  /// Runs OCR on an image or PDF file, automatically selecting the best
  /// rotation from all four 90° candidates.
  ///
  /// PDFs are rendered to a PNG image of the first page before OCR.
  /// Each candidate is scored by checking that invoice footer keywords
  /// appear near the bottom and header keywords near the top.
  /// The first candidate that scores ≥ 3 is returned immediately; otherwise
  /// the highest-scoring candidate wins.
  Future<RecognizedText> recognizeFromFilePath(String filePath) async {
    final Uint8List bytes;
    if (filePath.toLowerCase().endsWith('.pdf')) {
      bytes = await _pdfFirstPageToBytes(filePath);
    } else {
      bytes = await File(filePath).readAsBytes();
    }

    final isPdf = filePath.toLowerCase().endsWith('.pdf');
    final exifCwDegrees = isPdf ? 0 : _requiredCwRotation(bytes);

    // Try all four 90° increments, starting from the EXIF-derived rotation
    // so the most likely correct orientation is checked first.
    final degreesToTry = [
      exifCwDegrees,
      (exifCwDegrees + 90) % 360,
      (exifCwDegrees + 270) % 360,
      (exifCwDegrees + 180) % 360,
    ];

    RecognizedText? best;
    int bestScore = -999;
    int bestRows = 0;

    for (final degrees in degreesToTry) {
      final path = await _rotatedTempPath(bytes, degrees);
      final result = await _ocr(path, originalPath: filePath);
      _deleteTempFile(path, filePath);

      final score = _orientationScore(result);
      final rows = _countTextRows(result);

      // ignore: avoid_print
      print('[InvoiceScan] rotation=$degrees° score=$score rows=$rows');

      if (score > bestScore || (score == bestScore && rows > bestRows)) {
        best = result;
        bestScore = score;
        bestRows = rows;
      }

      if (bestScore >= 3) break; // Clearly correct orientation — stop early.
    }

    return best!;
  }

  Future<String> recognizeTextFromFilePath(String filePath) async {
    final result = await recognizeFromFilePath(filePath);
    return result.text;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Renders the first page of a PDF to PNG bytes at 2× scale for OCR.
  Future<Uint8List> _pdfFirstPageToBytes(String pdfPath) async {
    final document = await PdfDocument.openFile(pdfPath);
    try {
      final page = await document.getPage(1);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
        backgroundColor: '#ffffff',
      );
      await page.close();
      return pageImage!.bytes;
    } finally {
      await document.close();
    }
  }

  /// Returns a score for how "right-side up" an OCR result looks.
  /// Footer keywords near the bottom and header keywords near the top score
  /// positively; the same keywords in the wrong position score negatively.
  int _orientationScore(RecognizedText result) {
    final entries = <(double, String)>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        entries.add((line.boundingBox.center.dy, line.text.toLowerCase()));
      }
    }
    if (entries.isEmpty) return 0;

    final maxY = entries.map((e) => e.$1).reduce((a, b) => a > b ? a : b);
    if (maxY == 0) return 0;

    int score = 0;
    for (final (y, text) in entries) {
      final rel = y / maxY; // 0 = top edge, 1 = bottom edge
      final isTop = rel < 0.35;
      final isBottom = rel > 0.65;

      if (text.contains('thank you') ||
          text.contains('banking') ||
          text.contains('returns') ||
          text.contains('warranty')) {
        if (isBottom) score += 2;
        if (isTop) score -= 3;
      }
      if (text.contains('tax invoice') ||
          text.contains('vat no') ||
          text.contains('reg no') ||
          text.contains('invoice no')) {
        if (isTop) score += 2;
        if (isBottom) score -= 3;
      }
    }
    return score;
  }

  Future<RecognizedText> _ocr(String path, {required String originalPath}) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      return await recognizer.processImage(InputImage.fromFilePath(path));
    } finally {
      recognizer.close();
    }
  }

  void _deleteTempFile(String path, String originalPath) {
    if (path != originalPath) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
  }

  /// Returns the number of distinct horizontal text rows in the OCR result.
  int _countTextRows(RecognizedText result) {
    final ys = <double>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        ys.add(line.boundingBox.center.dy);
      }
    }
    if (ys.isEmpty) return 0;

    ys.sort();
    int rows = 1;
    for (int i = 1; i < ys.length; i++) {
      if (ys[i] - ys[i - 1] > 8) rows++;
    }
    return rows;
  }

  /// Rotates [bytes] by [cwDegrees] clockwise and saves as a temp file.
  Future<String> _rotatedTempPath(Uint8List bytes, int cwDegrees) async {
    // Detect PNG vs JPEG by magic bytes so ML Kit reads the right format.
    final isPng = bytes.length >= 4 &&
        bytes[0] == 0x89 && bytes[1] == 0x50 &&
        bytes[2] == 0x4E && bytes[3] == 0x47;
    final ext = isPng ? 'png' : 'jpg';

    if (cwDegrees == 0) {
      final tempPath =
          '${Directory.systemTemp.path}/invoice_orig_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(tempPath).writeAsBytes(bytes);
      return tempPath;
    }

    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final src = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      int outW;
      int outH;

      switch (cwDegrees) {
        case 90:
          outW = src.height;
          outH = src.width;
          canvas.translate(src.height.toDouble(), 0);
          canvas.rotate(math.pi / 2);
        case 180:
          outW = src.width;
          outH = src.height;
          canvas.translate(src.width.toDouble(), src.height.toDouble());
          canvas.rotate(math.pi);
        case 270:
          outW = src.height;
          outH = src.width;
          canvas.translate(0, src.width.toDouble());
          canvas.rotate(3 * math.pi / 2);
        default:
          final tempPath =
              '${Directory.systemTemp.path}/invoice_orig_${DateTime.now().millisecondsSinceEpoch}.$ext';
          await File(tempPath).writeAsBytes(bytes);
          return tempPath;
      }

      canvas.drawImage(src, ui.Offset.zero, ui.Paint());
      final picture = recorder.endRecording();
      final rotated = await picture.toImage(outW, outH);
      final data = await rotated.toByteData(format: ui.ImageByteFormat.png);

      final tempPath =
          '${Directory.systemTemp.path}/invoice_rot${cwDegrees}_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(tempPath).writeAsBytes(data!.buffer.asUint8List());
      return tempPath;
    } catch (_) {
      final tempPath =
          '${Directory.systemTemp.path}/invoice_err_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(tempPath).writeAsBytes(bytes);
      return tempPath;
    }
  }

  /// Returns how many degrees clockwise to rotate the raw pixel data so that
  /// text is upright, based on the EXIF orientation tag.
  int _requiredCwRotation(Uint8List bytes) {
    final exif = _jpegExifOrientation(bytes);
    if (exif > 0) {
      const map = {
        1: 0,
        2: 0,
        3: 180,
        4: 180,
        5: 90,
        6: 90,
        7: 270,
        8: 270,
      };
      return map[exif] ?? 0;
    }

    final (rawW, rawH) = _jpegRawDimensions(bytes);
    if (rawW > 0 && rawH > 0 && rawW > rawH) return 90;
    return 0;
  }

  int _jpegExifOrientation(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return 0;

    int offset = 2;
    while (offset + 4 <= bytes.length) {
      if (bytes[offset] != 0xFF) break;
      final marker = bytes[offset + 1];
      final segLen = (bytes[offset + 2] << 8) | bytes[offset + 3];

      if (marker == 0xE1 && offset + 10 <= bytes.length) {
        final d = offset + 4;
        if (bytes[d] == 0x45 &&
            bytes[d + 1] == 0x78 &&
            bytes[d + 2] == 0x69 &&
            bytes[d + 3] == 0x66 &&
            bytes[d + 4] == 0x00 &&
            bytes[d + 5] == 0x00) {
          return _tiffOrientation(bytes, d + 6);
        }
      }

      if (marker == 0xDA) break;
      if (segLen < 2) break;
      offset += 2 + segLen;
    }

    return 0;
  }

  int _tiffOrientation(Uint8List bytes, int tiffStart) {
    if (tiffStart + 8 > bytes.length) return 0;

    final isLE = bytes[tiffStart] == 0x49 && bytes[tiffStart + 1] == 0x49;

    int u16(int pos) {
      if (pos + 2 > bytes.length) return 0;
      return isLE
          ? bytes[pos] | (bytes[pos + 1] << 8)
          : (bytes[pos] << 8) | bytes[pos + 1];
    }

    int u32(int pos) {
      if (pos + 4 > bytes.length) return 0;
      return isLE
          ? bytes[pos] |
              (bytes[pos + 1] << 8) |
              (bytes[pos + 2] << 16) |
              (bytes[pos + 3] << 24)
          : (bytes[pos] << 24) |
              (bytes[pos + 1] << 16) |
              (bytes[pos + 2] << 8) |
              bytes[pos + 3];
    }

    final ifd0 = tiffStart + u32(tiffStart + 4);
    if (ifd0 + 2 > bytes.length) return 0;

    final count = u16(ifd0);
    for (int i = 0; i < count; i++) {
      final e = ifd0 + 2 + i * 12;
      if (e + 12 > bytes.length) break;
      if (u16(e) == 0x0112) {
        return u16(e + 8);
      }
    }

    return 0;
  }

  (int, int) _jpegRawDimensions(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return (0, 0);
    }

    int offset = 2;
    while (offset + 4 <= bytes.length) {
      if (bytes[offset] != 0xFF) break;
      final marker = bytes[offset + 1];
      final segLen = (bytes[offset + 2] << 8) | bytes[offset + 3];

      if (marker >= 0xC0 &&
          marker <= 0xCF &&
          marker != 0xC4 &&
          marker != 0xC8 &&
          marker != 0xCC) {
        final sofBase = offset + 4;
        if (sofBase + 4 < bytes.length) {
          final h = (bytes[sofBase + 1] << 8) | bytes[sofBase + 2];
          final w = (bytes[sofBase + 3] << 8) | bytes[sofBase + 4];
          return (w, h);
        }
        break;
      }

      if (marker == 0xDA) break;
      if (segLen < 2) break;
      offset += 2 + segLen;
    }

    return (0, 0);
  }
}

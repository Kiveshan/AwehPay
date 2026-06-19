import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

enum InvoiceImageSource { camera, gallery }

class InvoiceScanService {
  InvoiceScanService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<XFile?> pickInvoiceImage({
    required InvoiceImageSource source,
    int imageQuality = 85,
  }) {
    final imageSource = source == InvoiceImageSource.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    return _picker.pickImage(
      source: imageSource,
      imageQuality: imageQuality,
    );
  }

  /// Runs OCR on the image, automatically trying the best rotation.
  ///
  /// Some Android devices apply EXIF orientation when decoding JPEG pixels
  /// (so pixels are already portrait-correct) while others do not. To handle
  /// both cases without knowing which device we are on, we:
  ///   1. Run OCR with the EXIF-derived rotation applied.
  ///   2. If the result looks rotated (very few long lines), run OCR again
  ///      with an additional 90° CW rotation.
  ///   3. Return the pass whose OCR produced more distinct horizontal rows.
  Future<RecognizedText> recognizeFromFilePath(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final exifCwDegrees = _requiredCwRotation(bytes);

    // Candidate A: EXIF-based rotation.
    final pathA = await _rotatedTempPath(bytes, exifCwDegrees);
    final resultA = await _ocr(pathA, originalPath: filePath);

    // Only try a second rotation when the image had landscape pixels
    // (i.e. some rotation was applied or the dimension heuristic triggered).
    // If we're already at 0° the image was portrait — no need to try again.
    if (exifCwDegrees == 0 && pathA == filePath) {
      return resultA;
    }

    // Candidate B: one extra 90° CW on top of the EXIF-based rotation.
    // This corrects for the double-rotation case where Flutter's codec
    // already applied the EXIF orientation before we rotated.
    final altDegrees = (exifCwDegrees + 90) % 360;
    final pathB = await _rotatedTempPath(bytes, altDegrees);
    final resultB = await _ocr(pathB, originalPath: filePath);

    // Prefer the result with more distinct text rows — more rows means
    // the text was horizontal (correct orientation) rather than vertical.
    final rowsA = _countTextRows(resultA);
    final rowsB = _countTextRows(resultB);

    _deleteTempFile(pathA, filePath);
    _deleteTempFile(pathB, filePath);

    return rowsB > rowsA ? resultB : resultA;
  }

  Future<String> recognizeTextFromFilePath(String filePath) async {
    final result = await recognizeFromFilePath(filePath);
    return result.text;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

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
  /// A higher count means the text lines are short and horizontal — the
  /// expected layout for a correctly-oriented invoice.
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

  /// Rotates [bytes] by [cwDegrees] clockwise and saves as a temp PNG.
  /// Returns the original [filePath] unchanged if no rotation is needed
  /// OR if [cwDegrees] is 0.
  Future<String> _rotatedTempPath(Uint8List bytes, int cwDegrees) async {
    if (cwDegrees == 0) {
      // Write bytes to a temp path so the caller always gets a deletable path.
      final tempPath =
          '${Directory.systemTemp.path}/invoice_orig_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
          // Should not happen, but fall through safely.
          final tempPath =
              '${Directory.systemTemp.path}/invoice_orig_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
      // On error, return original bytes as a temp file.
      final tempPath =
          '${Directory.systemTemp.path}/invoice_err_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(tempPath).writeAsBytes(bytes);
      return tempPath;
    }
  }

  /// Returns how many degrees clockwise to rotate the raw pixel data so that
  /// text is upright, based on the EXIF orientation tag.
  /// Falls back to a dimension-based heuristic when no valid EXIF is present.
  int _requiredCwRotation(Uint8List bytes) {
    final exif = _jpegExifOrientation(bytes);
    if (exif > 0) {
      const map = {
        1: 0,   // Normal
        2: 0,   // Flip horizontal (ignore mirror)
        3: 180, // Rotate 180°
        4: 180, // Flip vertical
        5: 90,  // Transpose
        6: 90,  // Portrait right-side up (most common)
        7: 270, // Transverse
        8: 270, // Portrait upside-down
      };
      return map[exif] ?? 0;
    }

    // No EXIF: landscape raw pixels → assume portrait photo → rotate 90° CW.
    final (rawW, rawH) = _jpegRawDimensions(bytes);
    if (rawW > 0 && rawH > 0 && rawW > rawH) return 90;
    return 0;
  }

  /// Reads the EXIF orientation tag (0x0112) from a JPEG APP1 segment.
  /// Returns the orientation value (1–8) or 0 if not found.
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

  /// Parses a TIFF header and returns the Orientation tag value, or 0.
  int _tiffOrientation(Uint8List bytes, int tiffStart) {
    if (tiffStart + 8 > bytes.length) return 0;

    final isLE =
        bytes[tiffStart] == 0x49 && bytes[tiffStart + 1] == 0x49;

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

  /// Reads raw pixel width and height from a JPEG SOF segment.
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

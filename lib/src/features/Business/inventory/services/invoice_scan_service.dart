import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfx/pdfx.dart';

part 'invoice_scan_service.rotation.dart';

enum InvoiceImageSource { camera, file }

class InvoiceScanService {
  InvoiceScanService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  // Opens the device camera or the file picker depending on the user's choice.
  // Returns the local file path of the selected image/PDF, or null if cancelled.
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
      // File mode — accepts PDF, JPG, and PNG invoices from storage.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      return result?.files.single.path;
    }
  }

  // Entry point for OCR. Converts the file to bytes, tries all four rotations,
  // scores each result, and returns the best-oriented RecognizedText.
  Future<RecognizedText> recognizeFromFilePath(String filePath) async {
    final Uint8List bytes;

    // PDFs must be rendered to a bitmap first; images are read directly.
    if (filePath.toLowerCase().endsWith('.pdf')) {
      bytes = await _pdfFirstPageToBytes(filePath);
    } else {
      bytes = await File(filePath).readAsBytes();
    }

    final isPdf = filePath.toLowerCase().endsWith('.pdf');
    // Read the EXIF rotation tag so we start with the most likely orientation.
    // PDFs don't have EXIF data, so we default to 0°.
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
      // Write a rotated copy to a temp file, run OCR, then delete it.
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

  // Convenience wrapper that returns just the plain text string from OCR.
  Future<String> recognizeTextFromFilePath(String filePath) async {
    final result = await recognizeFromFilePath(filePath);
    return result.text;
  }

  
  // Private helpers


  // Renders the first page of a PDF to PNG bytes at 2× scale.
  // Higher resolution gives ML Kit more pixels to work with, improving accuracy.
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

  // Scores how "right-side up" an OCR result is.
  // Footer words near the bottom add points; header words near the top add points.
  // The same words in the wrong position subtract points.
  int _orientationScore(RecognizedText result) {
    final entries = <(double, String)>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        // Collect the vertical centre position and lowercased text of every line.
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

      // These words typically appear in invoice footers.
      if (text.contains('thank you') ||
          text.contains('banking') ||
          text.contains('returns') ||
          text.contains('warranty')) {
        if (isBottom) score += 2;
        if (isTop) score -= 3;
      }
      // These words typically appear in invoice headers.
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

 
  // ML Kit processes the image entirely on-device — no network call is made.
  Future<RecognizedText> _ocr(String path, {required String originalPath}) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      return await recognizer.processImage(InputImage.fromFilePath(path));
    } finally {
      recognizer.close();
    }
  }

  // Deletes the rotated temp file after OCR is done, but never deletes the
  // original file that the user selected.
  void _deleteTempFile(String path, String originalPath) {
    if (path != originalPath) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
  }

  // Counts distinct horizontal text rows by checking the gap between consecutive
  // line centres. A gap > 8px means a new row. Used to break ties in orientation scoring.
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
}

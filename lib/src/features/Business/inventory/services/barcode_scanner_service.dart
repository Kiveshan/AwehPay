import 'dart:io';

import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeScannerService {
  // Accepts an optional BarcodeScanner so tests can inject a mock.
  BarcodeScannerService({BarcodeScanner? barcodeScanner})
      : _barcodeScanner = barcodeScanner ?? BarcodeScanner();

  final BarcodeScanner _barcodeScanner;

  // Finds the first available camera and opens it at medium resolution.
  // Audio is disabled because we only need video frames, not sound.
  Future<CameraController> initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No camera found on this device.');
    }

    final controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();
    return controller;
  }

  // Snaps a still frame, feeds it to ML Kit, then deletes the temp file.
  // Returns the first non-empty barcode string found, or null if nothing detected.
  Future<String?> captureAndScanBarcode(CameraController controller) async {
    final image = await controller.takePicture();

    // Wrap the saved image path so ML Kit can read it as an InputImage.
    final inputImage = InputImage.fromFilePath(image.path);

    // ML Kit processes the image on-device and returns all detected barcodes.
    final barcodes = await _barcodeScanner.processImage(inputImage);

    // Clean up the temp file immediately — we only need the decoded value.
    final imageFile = File(image.path);
    await imageFile.delete().catchError((_) => imageFile);

    // Return the raw string of the first valid barcode found.
    for (final barcode in barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  // Releases the ML Kit scanner resource when the screen is closed.
  void dispose() {
    _barcodeScanner.close();
  }
}

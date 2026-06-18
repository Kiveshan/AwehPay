import 'dart:io';

import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeScannerService {
  BarcodeScannerService({BarcodeScanner? barcodeScanner})
      : _barcodeScanner = barcodeScanner ?? BarcodeScanner();

  final BarcodeScanner _barcodeScanner;

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

  Future<String?> captureAndScanBarcode(CameraController controller) async {
    final image = await controller.takePicture();
    final inputImage = InputImage.fromFilePath(image.path);
    final barcodes = await _barcodeScanner.processImage(inputImage);

    final imageFile = File(image.path);
    await imageFile.delete().catchError((_) => imageFile);

    for (final barcode in barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  void dispose() {
    _barcodeScanner.close();
  }
}

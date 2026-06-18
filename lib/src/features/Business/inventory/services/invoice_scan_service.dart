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
    final imageSource =
        source == InvoiceImageSource.camera ? ImageSource.camera : ImageSource.gallery;

    return _picker.pickImage(
      source: imageSource,
      imageQuality: imageQuality,
    );
  }

  Future<RecognizedText> recognizeFromFilePath(String filePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      return await recognizer.processImage(
        InputImage.fromFilePath(filePath),
      );
    } finally {
      recognizer.close();
    }
  }

  Future<String> recognizeTextFromFilePath(String filePath) async {
    final result = await recognizeFromFilePath(filePath);
    return result.text;
  }
}

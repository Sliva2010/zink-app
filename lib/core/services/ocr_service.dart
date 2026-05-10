import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Сервис распознавания рукописного/печатного текста на фото.
class OcrService {
  OcrService._();

  // ML Kit V2: 'latin' покрывает латиницу и кириллицу.
  static final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  static Future<String?> pickAndRecognize({ImageSource source = ImageSource.camera}) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 92,
    );
    if (picked == null) return null;
    return recognizeFile(File(picked.path));
  }

  static Future<String> recognizeFile(File file) async {
    final input = InputImage.fromFile(file);
    final result = await _recognizer.processImage(input);
    return result.text.trim();
  }

  static Future<void> dispose() async {
    await _recognizer.close();
  }
}

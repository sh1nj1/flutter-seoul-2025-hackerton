import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiConfig {
  const GeminiConfig._();

  static String get apiKey => dotenv.env['GEMINI_API_KEY']?.trim() ?? '';

  static bool get hasKey => apiKey.isNotEmpty;
}

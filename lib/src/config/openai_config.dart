import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIConfig {
  const OpenAIConfig._();

  static String get apiKey => dotenv.env['OPENAI_API_KEY']?.trim() ?? '';

  static bool get hasKey => apiKey.isNotEmpty;
}

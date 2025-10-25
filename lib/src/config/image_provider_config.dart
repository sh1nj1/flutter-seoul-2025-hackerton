import 'package:flutter_dotenv/flutter_dotenv.dart';

enum ImageProviderType { openai, gemini }

class ImageProviderConfig {
  const ImageProviderConfig._();

  static ImageProviderType get provider {
    final String value =
        dotenv.env['IMAGE_PROVIDER']?.trim().toLowerCase() ?? 'openai';
    return value == 'gemini'
        ? ImageProviderType.gemini
        : ImageProviderType.openai;
  }
}

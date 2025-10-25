import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'src/config/gemini_config.dart';
import 'src/config/image_provider_config.dart';
import 'src/config/openai_config.dart';
import 'src/screens/canvas_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  final ImageProviderType provider = ImageProviderConfig.provider;
  if (provider == ImageProviderType.gemini) {
    if (!GeminiConfig.hasKey) {
      debugPrint(
        'Warning: IMAGE_PROVIDER is set to gemini but GEMINI_API_KEY is missing.',
      );
    }
  } else {
    if (!OpenAIConfig.hasKey) {
      debugPrint(
        'Warning: OPENAI_API_KEY is not set. Icon generation will fall back.',
      );
    }
  }
  runApp(const CalmdownApp());
}

class CalmdownApp extends StatelessWidget {
  const CalmdownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calmdown',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const CanvasScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'src/config/gemini_config.dart';
import 'src/screens/canvas_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  if (!GeminiConfig.hasKey) {
    debugPrint('Warning: GEMINI_API_KEY is not set. Icon generation will fail.');
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

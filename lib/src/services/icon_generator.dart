import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/gemini_config.dart';

class IconGenerator {
  IconGenerator({GenerativeModel? model})
      : _model = model ?? _buildModel();

  final GenerativeModel _model;

  static GenerativeModel _buildModel() {
    final String apiKey = GeminiConfig.apiKey;
    if (apiKey.isEmpty) {
      throw StateError('Missing Gemini API key.');
    }
    return GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  Future<Uint8List> generateIcon({
    required String prompt,
    required Uint8List sketchBytes,
  }) async {
    final Content sketchContent = Content.multi(<Part>[
      TextPart(prompt),
      DataPart('image/png', sketchBytes),
    ]);

    final GenerateContentResponse response =
        await _model.generateContent(<Content>[sketchContent]);

    if (response.candidates == null) {
      throw StateError('No candidates returned by Gemini.');
    }

    for (final Candidate candidate in response.candidates!) {
      for (final Part part in candidate.content.parts) {
        if (part is DataPart) {
          return Uint8List.fromList(part.bytes);
        }
      }
    }

    throw StateError('Gemini did not return an image.');
  }
}

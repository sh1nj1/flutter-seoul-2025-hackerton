import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/gemini_config.dart';
import '../config/image_provider_config.dart';
import '../config/openai_config.dart';

class IconGenerator {
  IconGenerator({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const String _endpoint = 'https://api.openai.com/v1/images/edits';
  static const String _openAIModel = 'gpt-image-1';
  static const String _geminiModelName = 'gemini-2.0-flash';
  static const String _geminiEndpointBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

  Future<Uint8List> generateIcon({
    required String prompt,
    required Uint8List sketchBytes,
  }) async {
    final ImageProviderType provider = ImageProviderConfig.provider;
    if (provider == ImageProviderType.gemini) {
      return _generateWithGemini(prompt: prompt, sketchBytes: sketchBytes);
    }
    final String apiKey = OpenAIConfig.apiKey;
    if (apiKey.isEmpty) {
      throw StateError('Missing OpenAI API key.');
    }

    final http.MultipartRequest request = http.MultipartRequest(
      'POST',
      Uri.parse(_endpoint),
    )
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = _openAIModel
      ..fields['prompt'] = prompt
      ..fields['n'] = '1'
      ..fields['size'] = '1024x1024'
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          sketchBytes,
          filename: 'sketch.png',
          contentType: MediaType('image', 'png'),
        ),
      );

    final http.StreamedResponse streamedResponse = await _client.send(request);
    final http.Response response = await http.Response.fromStream(streamedResponse);

    debugPrint('OpenAI response status: ${response.statusCode}');
    debugPrint('OpenAI response body: ${response.body}');

    if (response.statusCode != 200) {
      throw StateError('OpenAI error ${response.statusCode}: ${response.body}');
    }

    final Map<String, dynamic> payload =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> data = payload['data'] as List<dynamic>? ?? <dynamic>[];
    if (data.isEmpty) {
      throw StateError('OpenAI did not return any image data.');
    }
    final Map<String, dynamic>? first =
        data.first as Map<String, dynamic>?;
    final String? base64Image = first?['b64_json'] as String?;
    if (base64Image != null && base64Image.isNotEmpty) {
      return base64Decode(base64Image);
    }

    final String? imageUrl = first?['url'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final http.Response imageResponse = await _client.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode == 200) {
        return imageResponse.bodyBytes;
      }
      throw StateError(
        'OpenAI image download failed ${imageResponse.statusCode}: ${imageResponse.body}',
      );
    }

    throw StateError('OpenAI response missing image content.');
  }

  Future<Uint8List> _generateWithGemini({
    required String prompt,
    required Uint8List sketchBytes,
  }) async {
    final String apiKey = GeminiConfig.apiKey;
    if (apiKey.isEmpty) {
      throw StateError('Missing Gemini API key.');
    }

    final Uri url = Uri.parse(
      '$_geminiEndpointBase/$_geminiModelName:generateContent?key=$apiKey',
    );

    final Map<String, dynamic> body = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'user',
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{
              'inline_data': <String, dynamic>{
                'mime_type': 'image/png',
                'data': base64Encode(sketchBytes),
              },
            },
            <String, dynamic>{'text': prompt},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'response_modalities': <String>['IMAGE'],
      },
    };

    final http.Response response = await _client.post(
      url,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    debugPrint('Gemini response status: ${response.statusCode}');
    debugPrint('Gemini response body: ${response.body}');

    if (response.statusCode != 200) {
      throw StateError('Gemini error ${response.statusCode}: ${response.body}');
    }

    final Map<String, dynamic> payload =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> candidates =
        payload['candidates'] as List<dynamic>? ?? <dynamic>[];
    for (final dynamic candidate in candidates) {
      final Map<String, dynamic>? candidateMap =
          candidate as Map<String, dynamic>?;
      final Map<String, dynamic>? content =
          candidateMap?['content'] as Map<String, dynamic>?;
      final List<dynamic>? parts = content?['parts'] as List<dynamic>?;
      if (parts == null) {
        continue;
      }
      for (final dynamic part in parts) {
        final Map<String, dynamic>? partMap = part as Map<String, dynamic>?;
        final Map<String, dynamic>? inline =
            (partMap?['inlineData'] as Map<String, dynamic>?) ??
                (partMap?['inline_data'] as Map<String, dynamic>?);
        final String? data = inline?['data'] as String?;
        if (data != null && data.isNotEmpty) {
          return base64Decode(data);
        }
      }
    }

    throw StateError('Gemini did not return an image.');
  }

  void dispose() {
    _client.close();
  }
}

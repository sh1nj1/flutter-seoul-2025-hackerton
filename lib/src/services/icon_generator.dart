import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/openai_config.dart';

class IconGenerator {
  IconGenerator({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const String _endpoint = 'https://api.openai.com/v1/images/edits';
  static const String _model = 'gpt-image-1';

  Future<Uint8List> generateIcon({
    required String prompt,
    required Uint8List sketchBytes,
  }) async {
    final String apiKey = OpenAIConfig.apiKey;
    if (apiKey.isEmpty) {
      throw StateError('Missing OpenAI API key.');
    }

    final http.MultipartRequest request = http.MultipartRequest(
      'POST',
      Uri.parse(_endpoint),
    )
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = _model
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

  void dispose() {
    _client.close();
  }
}

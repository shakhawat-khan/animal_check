import 'dart:io';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

Future<String> sendImageToChatGPT(File imageFile, String prompt) async {
  final apiKey = dotenv.env['OPENAI_API_KEY'];
  const endpoint = 'https://api.openai.com/v1/chat/completions';

  // Decode original image
  final originalBytes = await imageFile.readAsBytes();
  final originalImage = img.decodeImage(originalBytes);

  // Resize image to reduce payload (e.g., max width 512)
  final resizedImage = img.copyResize(
    originalImage!,
    width: 512,
    interpolation: img.Interpolation.average,
  );

  // Encode resized image to JPEG with quality compression
  final resizedJpgBytes = img.encodeJpg(resizedImage, quality: 75);
  final base64Image = base64Encode(resizedJpgBytes);

  // Build request body
  final requestBody = {
    "model": "gpt-4-turbo",
    "messages": [
      {
        "role": "user",
        "content": [
          {"type": "text", "text": "is that a $prompt ?"},
          {
            "type": "image_url",
            "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
          }
        ]
      }
    ],
    "max_tokens": 1000
  };

  final response = await http.post(
    Uri.parse(endpoint),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(requestBody),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    debugPrint(response.body);
    return data['choices'][0]['message']['content'];
  } else {
    final error = jsonDecode(response.body);
    throw Exception('OpenAI Error: ${error['error']['message']}');
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class OCRService {
  final String apiKey;
  final http.Client client;

  OCRService({required this.apiKey, http.Client? client})
      : client = client ?? http.Client();

  Future<String> performOCR(String imageUrl) async {
    final url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

    final requestPayload = {
      "requests": [
        {
          "image": {
            "source": {"imageUri": imageUrl}
          },
          "features": [
            {"type": "DOCUMENT_TEXT_DETECTION"}
          ],
          "imageContext": {
            "languageHints": ["en-t-i0-handwrit"]
          }
        }
      ]
    };

    try {
      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final textAnnotations = data['responses'][0]['textAnnotations'];
        if (textAnnotations != null && textAnnotations.isNotEmpty) {
          String text = textAnnotations[0]['description'];

          text = text.replaceAll(RegExp(r'[ \t]+'), ' ').trim();

          // Remove hyphenation at line breaks
          text = text.replaceAll(RegExp(r'-\s*\n\s*'), '');

          // Add space after every comma and period
          text = text.replaceAllMapped(RegExp(r'([,.])(\S)'), (match) {
            return '${match.group(1)} ${match.group(2)}';
          });

          // Remove newline if the character before is not a period
          text = text.replaceAllMapped(RegExp(r'(?<!\.)\n'), (match) {
            return ' ';
          });

          return text;
        } else {
          return 'No text found in the image.';
        }
      } else {
        print('Error: ${response.statusCode} ${response.body}');
        throw Exception('Failed to perform OCR. Please try again later.');
      }
    } catch (e) {
      print('OCR Error: $e');
      throw Exception('Failed to perform OCR. Please try again later.');
    }
  }
}

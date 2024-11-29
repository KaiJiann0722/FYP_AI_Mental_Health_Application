import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class OCRService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000'; // Android emulator localhost
    } else {
      return 'http://192.168.100.164:8000'; // iOS simulator/physical device
    }
  }

  final http.Client client;

  OCRService({http.Client? client}) : client = client ?? http.Client();

  Future<String> performOCR(String imageUrl) async {
    try {
      // Debug logging for request
      print('Sending OCR request');
      print('Base URL: ${OCRService.baseUrl}');
      print('Full URL: ${OCRService.baseUrl}/ocr');
      print('Image URL being sent: $imageUrl');

      final response = await client
          .post(
        Uri.parse('${OCRService.baseUrl}/ocr'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'image_url': imageUrl,
        }),
      )
          .timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Request timed out after 60 seconds');
        },
      );

      // Detailed response logging
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['generated_text'] as String;
      } else if (response.statusCode == 404) {
        throw Exception(
            'OCR endpoint not found. Please verify the server URL and endpoint path.');
      } else {
        var errorMessage = 'Unknown error';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['detail'] ?? errorData['message'] ?? 'Unknown error';
        } catch (_) {
          errorMessage = response.body;
        }
        throw Exception('Server error (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      print('OCR Error: $e');
      throw Exception('OCR processing failed: ${e.toString()}');
    }
  }
}

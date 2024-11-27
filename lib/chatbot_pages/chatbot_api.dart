import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatBotApi {
  static const String _baseUrl = 'http://192.168.0.7:5000/api/chat';

  /// Sends a message to the chatbot and retrieves the response.
  static Future<String> sendMessage(String message) async {
    try {
      // Prepare the full URL and headers
      final uri = Uri.parse(_baseUrl);
      final headers = {
        'Content-Type': 'application/json',
        // Add API key if you implemented authentication
        // 'X-API-Key': 'your-api-key'
      };
      final body = jsonEncode({'question': message});

      // Send the POST request
      final response = await http
          .post(
        uri,
        headers: headers,
        body: body,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      // Check for success or failure
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? "Error: No response from chatbot";
      } else {
        print('Error Response: ${response.body}');
        return "Error: Server returned status ${response.statusCode}";
      }
    } on TimeoutException {
      return "Error: Request timed out. Please try again.";
    } catch (e) {
      print('Error details: $e');
      return "Error: Could not connect to chatbot server.";
    }
  }
}

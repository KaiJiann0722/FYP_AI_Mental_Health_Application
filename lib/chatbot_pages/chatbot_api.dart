// import 'dart:async';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ChatBotApi {
//   static const String _baseUrl = 'http://192.168.0.7:5000/api/chat';

//   /// Sends a message to the chatbot and retrieves the response.
//   static Future<String> sendMessage(String message) async {
//     try {
//       // Prepare the full URL and headers
//       final uri = Uri.parse(_baseUrl);
//       final headers = {
//         'Content-Type': 'application/json',
//         // Add API key if you implemented authentication
//         // 'X-API-Key': 'your-api-key'
//       };
//       final body = jsonEncode({'question': message});

//       // Send the POST request
//       final response = await http
//           .post(
//         uri,
//         headers: headers,
//         body: body,
//       )
//           .timeout(
//         const Duration(seconds: 30),
//         onTimeout: () {
//           throw TimeoutException('Request timed out');
//         },
//       );

//       // Check for success or failure
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['response'] ?? "Error: No response from chatbot";
//       } else {
//         print('Error Response: ${response.body}');
//         return "Error: Server returned status ${response.statusCode}";
//       }
//     } on TimeoutException {
//       return "Error: Request timed out. Please try again.";
//     } catch (e) {
//       print('Error details: $e');
//       return "Error: Could not connect to chatbot server.";
//     }
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'package:flutter_fyp/chatbot_pages/chat_history.dart';
import 'package:http/http.dart' as http;

class ChatBotApi {
  static const String _baseUrl = 'http://192.168.0.6:5000/api';

  /// Sends a message to the chatbot and retrieves the response along with updated conversation history.
  static Future<Map<String, String>> sendMessage(String message, {String? conversationHistory}) async {
    try {
      // Prepare the full URL and headers
      final uri = Uri.parse('$_baseUrl/chat');
      final headers = {
        'Content-Type': 'application/json',
      };

      // Prepare the request body
      final body = jsonEncode({
        'question': message,  // The message from the user
        'conversation_history': conversationHistory ?? ""  // Optional: previous conversation history
      });

      print("Sending request with body: $body");
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
                // Print the response and updated conversation history
        print("Received response: ${data['response']}");
        print("Updated conversation history: ${data['conversation_history']}");
        // Return response and updated conversation history in a map
        return {
          'response': data['response'] ?? "Error: No response from chatbot",
          'conversation_history': data['conversation_history'] ?? "",
        };
      } else {
        // If the server returned an error status, return it
        print('Error Response: ${response.body}');
        return {
          'response': "Error: Server returned status ${response.statusCode}",
          'conversation_history': conversationHistory ?? "",
        };
      }
    } on TimeoutException {
      // Handle timeout exception
      return {
        'response': "Error: Request timed out. Please try again.",
        'conversation_history': conversationHistory ?? "",
      };
    } catch (e) {
      // Handle other exceptions
      print('Error details: $e');
      return {
        'response': "Error: Could not connect to chatbot server.",
        'conversation_history': conversationHistory ?? "",
      };
    }
  }


   static Future<void> resetBackendHistory() async {
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/reset'), // Update with your reset endpoint
      headers: {
        'Content-Type': 'application/json', // Explicitly set the Content-Type
      },
      body: jsonEncode({}), // Send an empty JSON object
    );

    if (response.statusCode == 200) {
      print("Backend conversation history reset successfully.");
    } else {
      print("Failed to reset backend history: ${response.body}");
    }
  } catch (e) {
    print("Error resetting backend history: $e");
  }
}
}

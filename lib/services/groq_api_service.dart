import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqApiService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  final String apiKey;

  GroqApiService(this.apiKey);

  Future<String> summarizeJournalEntry(String journalText) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama3-70b-8192',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful assistant that summarizes journal entries concisely.'
            },
            {
              'role': 'user',
              'content':
                  'Summarize following journal entries, focusing on key themes and insights based on dates. Highlight any patterns or developments over time if the journal entry is part of a series:\n\n  $journalText'
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1024
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['choices'][0]['message']['content'].trim();
      } else {
        throw Exception('Failed to summarize journal entry: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error in API call: $e');
    }
  }
}

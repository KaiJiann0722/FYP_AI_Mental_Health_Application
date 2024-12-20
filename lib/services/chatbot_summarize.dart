import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatJournalService {
  final String apiKey;
  final String apiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  ChatJournalService({required this.apiKey});

  Future<Map<String, String>> convertChatToJournal(
      List<Map<String, String>> chatMessages) async {
    try {
      // Prepare the chat history for summarization
      String chatHistory = chatMessages
          .map((msg) => '${msg['sender']}: ${msg['content']}')
          .join('\n');

      // Construct the prompt for journal-style summarization
      String prompt = """
Please summarize the following chat conversation, focusing specifically on the user's input, into a structured journal-style entry.

1. Generate a concise and meaningful title that reflects the key theme of the user's conversation.
2. Focus on the key insights, emotional tone, and significant points raised by the user.
3. Provide both a title and a detailed journal entry, emphasizing the user's thoughts, feelings, and any requests or ideas expressed.

Format your response as follows:
Title: [Generated Title]  
Entry: [Generated Journal Entry]  

Chat History:  
$chatHistory
""";

      // Make API call to Gemini
      final response = await http.post(
        Uri.parse('$apiBaseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 500,
          }
        }),
      );

      // Check response
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        String rawResponse =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];

        return _parseJournalResponse(rawResponse);
      } else {
        throw Exception('Failed to generate journal: ${response.body}');
      }
    } catch (e) {
      return {
        'title': 'Conversation Reflection',
        'content': 'Unable to generate journal entry. Error: $e'
      };
    }
  }

  Map<String, String> _parseJournalResponse(String response) {
    // Split the response into title and entry
    final parts = response.split('\n');

    String title = 'Untitled Journal';
    String entry = 'No content generated';

    // Find and extract title
    final titleLine = parts.firstWhere((line) => line.startsWith('Title:'),
        orElse: () => 'Title: Conversation Reflection');
    title = titleLine.replaceFirst('Title:', '').trim();

    // Find and extract entry
    final entryIndex = parts.indexWhere((line) => line.startsWith('Entry:'));
    if (entryIndex != -1) {
      // Combine all lines after 'Entry:' as the full entry
      entry = parts.sublist(entryIndex + 1).join('\n').trim();
      if (entry.isEmpty) {
        entry = parts[entryIndex].replaceFirst('Entry:', '').trim();
      }
    }

    return {'title': title, 'content': entry};
  }
}

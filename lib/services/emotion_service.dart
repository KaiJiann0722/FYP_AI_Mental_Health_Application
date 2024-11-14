import 'dart:convert';
import 'dart:io'; // Import the dart:io package
import 'package:http/http.dart' as http;
import '../models/emotion.dart';

class EmotionService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/predict'; // Use 10.0.2.2 for Android Emulator
    } else {
      return 'http://127.0.0.1:8000/predict'; // Use localhost for iOS Simulator
    }
  }

  Future<List<Emotion>> analyzeEmotions(String text) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final Map<String, dynamic> emotionsData = data['emotions'];
        final List<Emotion> emotions = emotionsData.entries.map((entry) {
          return Emotion(
            emotion: entry.key,
            probability: entry.value.toDouble(),
          );
        }).toList();
        return emotions;
      } else {
        throw Exception('Failed to analyze emotions');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

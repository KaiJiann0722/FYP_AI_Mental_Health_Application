import 'dart:convert';
import 'dart:io'; // Import the dart:io package
import 'package:http/http.dart' as http;
import '../models/emotion.dart';

class EmotionService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/predict'; // Use host machine's IP address for Android Emulator
    } else {
      return 'http://192.168.100.164:8000/predict'; // Use host machine's IP address for iOS Simulator
    }
  }

  String getSentimentLabel(double compound) {
    if (compound >= 0.7) {
      return 'Super Positive';
    } else if (compound >= 0.2) {
      return 'Positive';
    } else if (compound > -0.2) {
      return 'Neutral';
    } else if (compound >= -0.7) {
      return 'Negative';
    } else {
      return 'Super Negative';
    }
  }

  Future<Map<String, dynamic>> analyzeEmotions(String text) async {
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

        final double compound = data['sentiment'];
        final String sentimentLabel = getSentimentLabel(compound);
        final Sentiment sentiment =
            Sentiment(compound: compound, label: sentimentLabel);

        return {
          'emotions': emotions,
          'sentiment': sentiment,
        };
      } else {
        throw Exception('Failed to analyze emotions');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Error: $e');
    }
  }
}

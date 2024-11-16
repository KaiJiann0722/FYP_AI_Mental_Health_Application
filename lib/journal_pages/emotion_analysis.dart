import 'package:flutter/material.dart';
import '../services/emotion_service.dart';
import '../models/emotion.dart';
import 'utils.dart';

class EmotionAnalysisPage extends StatefulWidget {
  final String journalEntry;
  final String journalId;

  EmotionAnalysisPage({required this.journalEntry, required this.journalId});

  @override
  _EmotionAnalysisPageState createState() => _EmotionAnalysisPageState();
}

class _EmotionAnalysisPageState extends State<EmotionAnalysisPage> {
  final EmotionService _emotionService = EmotionService();
  final DatabaseService _databaseService = DatabaseService();
  List<Emotion> _emotions = [];
  Sentiment? _sentiment;
  bool _isLoading = true;
  int _currentStep = 1; // Track the current step
  final steps = ['Journal', 'Emotion', 'Music']; // Define the steps

  Map<String, String> emotionToEmoji = {
    "admiration": "😊",
    "joy": "😃",
    "anger": "😠",
    "grief": "😔",
    "confusion": "😕",
    "amusement": "😄",
    "approval": "👍",
    "love": "❤️",
    "annoyance": "😒",
    "nervousness": "😓",
    "curiosity": "🤔",
    "caring": "😊",
    "desire": "😍",
    "excitement": "😆",
    "gratitude": "🙏",
    "optimism": "👍",
    "pride": "😊",
    "relief": "😄",
    "disappointment": "😞",
    "disapproval": "👎",
    "disgust": "🤢",
    "embarrassment": "😳",
    "fear": "😟",
    "remorse": "😔",
    "sadness": "😔",
    "surprise": "😮",
    "realization": "💡",
  };

  @override
  void initState() {
    super.initState();
    _analyzeEmotions();
  }

  Future<void> _analyzeEmotions() async {
    try {
      final result = await _emotionService.analyzeEmotions(widget.journalEntry);
      setState(() {
        _emotions = result['emotions'];
        _sentiment = result['sentiment'];
        _isLoading = false;
      });

      // Save emotions to Firestore
      await _databaseService.addEmotions(widget.journalId, _emotions);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Analysis'),
        backgroundColor: Colors.grey[100],
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProgressStepper(
                      currentStep: _currentStep,
                      steps: steps), // Add the progress stepper
                  const SizedBox(height: 24),
                  const Text(
                    'Emotion Analysis Results:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._emotions.map((emotion) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${emotion.emotion} ${emotionToEmoji[emotion.emotion] ?? ''}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              '${(emotion.probability * 100).toStringAsFixed(2)}%',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                  if (_sentiment != null) ...[
                    const Text(
                      'Sentiment Analysis:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sentiment: ${_sentiment!.label}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Compound Score: ${_sentiment!.compound}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      // Navigate to the next page or perform any action
                    },
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/emotion.dart';
import 'utils.dart';

class EmotionAnalysis extends StatelessWidget {
  final List<Emotion> emotions;
  final Sentiment sentiment;

  EmotionAnalysis({required this.emotions, required this.sentiment});

  @override
  Widget build(BuildContext context) {
    int _currentStep = 1; // Track the current step
    final steps = ['Journal', 'Emotion', 'Music']; // Define the steps
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Emotion Analysis'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressStepper(currentStep: _currentStep, steps: steps),
            const Text(
              'Emotion Analysis:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...emotions.map((emotion) => Padding(
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
              'Sentiment: ${sentiment.label}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Compound Score: ${sentiment.compound}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
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

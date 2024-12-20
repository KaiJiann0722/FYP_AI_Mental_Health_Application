import 'package:flutter/material.dart';
import '../models/emotion.dart';
import 'utils.dart';
import 'music_recommendation.dart';

class EmotionAnalysis extends StatelessWidget {
  final List<Emotion> emotions;
  final Sentiment sentiment;

  EmotionAnalysis({required this.emotions, required this.sentiment});

  @override
  Widget build(BuildContext context) {
    int currentStep = 1; // Track the current step
    final steps = ['Journal', 'Emotion', 'Music']; // Define the steps

    Emotion highestEmotion =
        emotions.reduce((a, b) => a.probability > b.probability ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: Text('Emotion Analysis'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProgressStepper(currentStep: currentStep, steps: steps),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emotion Analysis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...emotions
                          .map((emotion) => Container(
                                margin: EdgeInsets.only(bottom: 8),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              emotionToEmoji[emotion.emotion
                                                      .toLowerCase()] ??
                                                  '🤔',
                                              style: TextStyle(fontSize: 24),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              emotion.emotion,
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${(emotion.probability * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: emotion.probability,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sentiment Analysis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Overall Sentiment:',
                            style: TextStyle(fontSize: 16),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                sentiment.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: getSentimentColor(sentiment.label),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (sentiment.compound + 1) / 2, // normalize to 0-1
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          getSentimentColor(sentiment.label),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Polarity Score: ${sentiment.compound}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: getSentimentColor(sentiment.label),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('Get Music Recommendations button pressed');
                    // Navigate to music recommendation page with the highest emotion
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MusicRecommendationsPage(
                            highestEmotion: highestEmotion),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Get Music Recommendations',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

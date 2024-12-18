import 'package:flutter/material.dart';

enum SentimentLevel {
  superPositive,
  positive,
  neutral,
  negative,
  superNegative,
}

Map<SentimentLevel, IconData> sentimentIcons = {
  SentimentLevel.superPositive: Icons.sentiment_very_satisfied,
  SentimentLevel.positive: Icons.sentiment_satisfied,
  SentimentLevel.neutral: Icons.sentiment_neutral,
  SentimentLevel.negative: Icons.sentiment_dissatisfied,
  SentimentLevel.superNegative: Icons.sentiment_very_dissatisfied,
};

Map<SentimentLevel, Color> sentimentColors = {
  SentimentLevel.superPositive: Colors.green,
  SentimentLevel.positive: Colors.lightGreen,
  SentimentLevel.neutral: Colors.grey,
  SentimentLevel.negative: Colors.orange,
  SentimentLevel.superNegative: Colors.red,
};

SentimentLevel getSentimentLevel(double averageSentiment) {
  if (averageSentiment > 0.7) return SentimentLevel.superPositive;
  if (averageSentiment > 0.2) return SentimentLevel.positive;
  if (averageSentiment > -0.2) return SentimentLevel.neutral;
  if (averageSentiment > -0.7) return SentimentLevel.negative;
  return SentimentLevel.superNegative;
}

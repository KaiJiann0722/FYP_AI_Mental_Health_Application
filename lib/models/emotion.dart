// This file contains the model classes for Emotion and Sentiment
class Emotion {
  final String emotion;
  final double probability;

  Emotion({required this.emotion, required this.probability});

  factory Emotion.fromJson(Map<String, dynamic> json) {
    return Emotion(
      emotion: json['emotion'],
      probability: json['probability'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'probability': probability,
    };
  }
}

class Sentiment {
  final double compound;
  final String label;

  Sentiment({required this.compound, required this.label});

  factory Sentiment.fromJson(Map<String, dynamic> json) {
    return Sentiment(
      compound: json['compound'].toDouble(),
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'compound': compound,
      'label': label,
    };
  }
}

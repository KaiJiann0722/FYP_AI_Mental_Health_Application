import 'package:cloud_firestore/cloud_firestore.dart';

const String EMOTION_COLLECTION_REF = "emotion";

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

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addEmotions(String journalId, List<Emotion> emotions) async {
    List<Map<String, dynamic>> emotionsList =
        emotions.map((e) => e.toJson()).toList();
    await _firestore
        .collection(EMOTION_COLLECTION_REF)
        .doc(journalId)
        .set({'emotions': emotionsList});
  }

  Future<List<Emotion>?> getEmotions(String journalId) async {
    DocumentSnapshot doc = await _firestore
        .collection(EMOTION_COLLECTION_REF)
        .doc(journalId)
        .get();
    if (doc.exists) {
      List<dynamic> emotionsJson = doc['emotions'];
      return emotionsJson
          .map((e) => Emotion.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  Future<void> updateEmotions(String journalId, List<Emotion> emotions) async {
    List<Map<String, dynamic>> emotionsList =
        emotions.map((e) => e.toJson()).toList();
    await _firestore
        .collection(EMOTION_COLLECTION_REF)
        .doc(journalId)
        .update({'emotions': emotionsList});
  }

  Future<void> deleteEmotions(String journalId) async {
    await _firestore.collection(EMOTION_COLLECTION_REF).doc(journalId).delete();
  }

  Future<List<List<Emotion>>> getAllEmotions() async {
    QuerySnapshot querySnapshot =
        await _firestore.collection(EMOTION_COLLECTION_REF).get();
    return querySnapshot.docs.map((doc) {
      List<dynamic> emotionsJson = doc['emotions'];
      return emotionsJson
          .map((e) => Emotion.fromJson(e as Map<String, dynamic>))
          .toList();
    }).toList();
  }
}

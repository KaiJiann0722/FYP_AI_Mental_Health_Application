import 'package:cloud_firestore/cloud_firestore.dart';
import 'emotion.dart';

const String JOURNAL_COLLECTION_REF = "journal";

class Journal {
  final String title;
  final String content;
  final Timestamp entryDate;
  final String? imageUrl;
  final String userId;
  final List<Emotion>? emotions;
  final Sentiment? sentiment;

  Journal({
    required this.title,
    required this.content,
    required this.entryDate,
    this.imageUrl,
    required this.userId,
    this.emotions,
    this.sentiment,
  });

  // Convert a Journal object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'entryDate': entryDate,
      'imageUrl': imageUrl,
      'userId': userId,
      'emotions': emotions?.map((e) => e.toJson()).toList(),
      'sentiment': sentiment?.toJson(),
    };
  }

  // Create a Journal object from a JSON map
  factory Journal.fromJson(Map<String, dynamic> json) {
    return Journal(
      title: json['title'],
      content: json['content'],
      entryDate: json['entryDate'],
      imageUrl: json['imageUrl'],
      userId: json['userId'],
      emotions: json['emotions'] != null
          ? (json['emotions'] as List)
              .map((e) => Emotion.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      sentiment: json['sentiment'] != null
          ? Sentiment.fromJson(json['sentiment'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference<Journal> _journalRef;

  DatabaseService() {
    _journalRef = _firestore
        .collection(JOURNAL_COLLECTION_REF)
        .withConverter<Journal>(
          fromFirestore: (snapshot, _) => Journal.fromJson(snapshot.data()!),
          toFirestore: (journal, _) => journal.toJson(),
        );
  }

  FirebaseFirestore get firestore => _firestore;

  Stream<QuerySnapshot<Journal>> getJournalsByDateAndUser(
      DateTime selectedDate, String userId, String sortOrder) {
    DateTime startOfDay =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    DateTime endOfDay = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, 23, 59, 59, 999);
    return _journalRef
        .where('entryDate', isGreaterThanOrEqualTo: startOfDay)
        .where('entryDate', isLessThanOrEqualTo: endOfDay)
        .where('userId', isEqualTo: userId)
        .orderBy('entryDate', descending: sortOrder == 'Newest')
        .snapshots();
  }

  Stream<QuerySnapshot<Journal>> getJournals() {
    return _journalRef.snapshots();
  }

  Future<String> addJournal(Journal journal) async {
    DocumentReference<Journal> docRef = await _journalRef.add(journal);
    return docRef.id;
  }

  Future<Journal?> getJournalById(String journalId) async {
    DocumentSnapshot<Journal> docSnapshot =
        await _journalRef.doc(journalId).get();
    if (docSnapshot.exists) {
      return docSnapshot.data();
    }
    return null;
  }

  Future<void> updateJournal(String journalId, Journal journal) async {
    await _journalRef.doc(journalId).update(journal.toJson());
  }

  Future<void> deleteJournal(String journalId) async {
    await _journalRef.doc(journalId).delete();
  }

  Future<void> addEmotionsAndSentiment(
      String journalId, List<Emotion> emotions, Sentiment sentiment) async {
    List<Map<String, dynamic>> emotionsList =
        emotions.map((e) => e.toJson()).toList();
    Map<String, dynamic> sentimentJson = sentiment.toJson();

    await _journalRef.doc(journalId).update({
      'emotions': emotionsList,
      'sentiment': sentimentJson,
    });
  }

  Future<Map<String, dynamic>?> getEmotionsAndSentiment(
      String journalId) async {
    DocumentSnapshot<Journal> doc = await _journalRef.doc(journalId).get();
    if (doc.exists) {
      Map<String, dynamic>? data = doc.data()?.toJson();
      if (data != null) {
        List<dynamic> emotionsJson = data['emotions'];
        Map<String, dynamic> sentimentJson = data['sentiment'];

        List<Emotion> emotions = emotionsJson
            .map((e) => Emotion.fromJson(e as Map<String, dynamic>))
            .toList();
        Sentiment sentiment = Sentiment.fromJson(sentimentJson);

        return {
          'emotions': emotions,
          'sentiment': sentiment,
        };
      }
    }
    return null;
  }

  Future<void> updateEmotionsAndSentiment(
      String journalId, List<Emotion> emotions, Sentiment sentiment) async {
    List<Map<String, dynamic>> emotionsList =
        emotions.map((e) => e.toJson()).toList();
    Map<String, dynamic> sentimentJson = sentiment.toJson();

    await _journalRef.doc(journalId).update({
      'emotions': emotionsList,
      'sentiment': sentimentJson,
    });
  }

  Future<void> deleteEmotionsAndSentiment(String journalId) async {
    await _journalRef.doc(journalId).update({
      'emotions': FieldValue.delete(),
      'sentiment': FieldValue.delete(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllEmotionsAndSentiments() async {
    QuerySnapshot<Journal> querySnapshot = await _journalRef.get();
    return querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data().toJson();
      List<dynamic> emotionsJson = data['emotions'];
      Map<String, dynamic> sentimentJson = data['sentiment'];

      List<Emotion> emotions = emotionsJson
          .map((e) => Emotion.fromJson(e as Map<String, dynamic>))
          .toList();
      Sentiment sentiment = Sentiment.fromJson(sentimentJson);

      return {
        'emotions': emotions,
        'sentiment': sentiment,
      };
    }).toList();
  }

  Future<Emotion?> getHighestProbabilityEmotion(String journalId) async {
    DocumentSnapshot<Journal> doc = await _journalRef.doc(journalId).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data()!.toJson();
      List<dynamic> emotionsJson = data['emotions'];
      if (emotionsJson.isNotEmpty) {
        Map<String, dynamic> highestEmotionJson = emotionsJson.first;
        return Emotion.fromJson(highestEmotionJson);
      }
    }
    return null;
  }
}

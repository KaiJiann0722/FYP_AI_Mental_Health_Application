import 'package:cloud_firestore/cloud_firestore.dart';

const String JOURNAL_COLLECTION_REF = "journal";

class Journal {
  final String title;
  final String content;
  final Timestamp entryDate;
  final String? imageUrl;
  final String userId;

  Journal({
    required this.title,
    required this.content,
    required this.entryDate,
    this.imageUrl,
    required this.userId,
  });

  // Convert a Journal object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'entryDate': entryDate,
      'imageUrl': imageUrl,
      'userId': userId,
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

  Stream<QuerySnapshot<Journal>> getJournals() {
    return _journalRef.snapshots();
  }

  Future<String> addJournal(Journal journal) async {
    DocumentReference<Journal> docRef = await _journalRef.add(journal);
    return docRef.id;
  }
}

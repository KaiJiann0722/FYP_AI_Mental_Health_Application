import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class Songs {
  final String title;
  final String artist;
  final String emotion;
  final String trackId;
  String imageUrl;
  final String genre;

  Songs({
    required this.title,
    required this.artist,
    required this.emotion,
    required this.trackId,
    this.imageUrl = '',
    required this.genre,
  });

  factory Songs.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Songs(
      title: data['track_name'] ?? '',
      artist: data['artists'] ?? '',
      emotion: data['emotion'] ?? '',
      trackId: data['track_id'] ?? '',
      imageUrl: data['image_url'] ?? '',
      genre: data['track_genre'] ?? '',
    );
  }

  factory Songs.fromFirestore1(Map<String, dynamic> data) {
    return Songs(
      title: data['track_name'] ?? '',
      artist: data['artists'] ?? '',
      emotion: data['emotion'] ?? '',
      trackId: data['track_id'] ?? '',
      imageUrl: data['image_url'] ?? '',
      genre: data['track_genre'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'track_name': title,
      'artists': artist,
      'emotion': emotion,
      'track_id': trackId,
      'image_url': imageUrl,
      'track_genre': genre,
    };
  }

  static Future<String> getSpotifyAccessToken(
      String clientId, String clientSecret) async {
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization':
            'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret')),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      throw Exception('Failed to obtain access token');
    }
  }

  static Future<String> fetchSongImageUrl(
      String trackId, String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/tracks/$trackId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['album'] != null &&
          data['album']['images'] != null &&
          data['album']['images'].isNotEmpty) {
        return data['album']['images'][0]['url'];
      } else {
        throw Exception('No images found for track');
      }
    } else if (response.statusCode == 429) {
      // Rate limit exceeded, return null for the image
      print('Rate limit exceeded: ${response.statusCode} ${response.body}');
      return '';
    } else {
      print('Error fetching image: ${response.statusCode} ${response.body}');
      throw Exception('Failed to fetch song image');
    }
  }

  static Future<List<Songs>> getMusicRecommendations(String mood) async {
    // Get total count of songs matching the mood
    AggregateQuery countQuery = FirebaseFirestore.instance
        .collection('songs')
        .where('emotion', isEqualTo: mood)
        .count();

    AggregateQuerySnapshot countSnapshot = await countQuery.get();

    // Use null coalescing to ensure we have a non-null integer
    int totalMatchingSongs = countSnapshot.count ?? 0;

    // If no matching songs or less than 20, return an empty list or all available
    if (totalMatchingSongs == 0) {
      return [];
    }

    // Adjust random selection logic to work with smaller collections
    int songsToFetch = min(20, totalMatchingSongs);

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('songs')
        .where('emotion', isEqualTo: mood)
        .limit(songsToFetch)
        .get();

    // Shuffle the documents to randomize
    List<QueryDocumentSnapshot> shuffledDocs = querySnapshot.docs.toList()
      ..shuffle();

    return shuffledDocs.map((doc) => Songs.fromFirestore(doc)).toList();
  }

  static Future<List<Songs>> getSongsByMood(String mood) async {
    // Get total count of songs matching the mood
    AggregateQuery countQuery = FirebaseFirestore.instance
        .collection('songs')
        .where('emotion', isEqualTo: mood)
        .count();

    AggregateQuerySnapshot countSnapshot = await countQuery.get();

    // Use null coalescing to ensure we have a non-null integer
    int totalMatchingSongs = countSnapshot.count ?? 0;

    // If no matching songs, return an empty list
    if (totalMatchingSongs == 0) {
      return [];
    }

    // Calculate the number of songs to fetch (max 20)
    int songsToFetch = min(20, totalMatchingSongs);

    // Create a query to get random documents
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('songs')
        .where('emotion', isEqualTo: mood)
        .limit(songsToFetch)
        .get();

    // Convert documents to Songs objects
    return querySnapshot.docs.map((doc) => Songs.fromFirestore(doc)).toList();
  }

// Function to get songs for all emotions
  static Future<Map<String, List<Songs>>> getAllSongsByMood() async {
    List<String> emotions = ['Happy', 'Sad', 'Energetic', 'Calm'];

    Map<String, List<Songs>> songsByMood = {};

    for (String emotion in emotions) {
      songsByMood[emotion] = await getSongsByMood(emotion);
    }

    return songsByMood;
  }

  static Future<List<Songs>> getAllSongs() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('songs').get();

    return querySnapshot.docs.map((doc) => Songs.fromFirestore(doc)).toList();
  }

  static Future<List<Songs>> getRecommendations(
      String predClass, String clientId, String clientSecret) async {
    predClass = mapToEkmanEmotion(predClass);
    String mood;
    if (predClass == 'disgust') {
      mood = 'Sad';
    } else if (['happy', 'sad'].contains(predClass)) {
      mood = 'Happy';
    } else if (['fear', 'anger'].contains(predClass)) {
      mood = 'Calm';
    } else if (['surprise', 'neutral'].contains(predClass)) {
      mood = 'Energetic';
    } else {
      return [];
    }
    return await getMusicRecommendations(mood);
  }

  static Future<List<String>> getAllGenres() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('songs').get();

    Set<String> genres = {};
    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data['track_genre'] != null) {
        genres.add(data['track_genre']);
      }
    }
    return genres.toList();
  }

  static String mapToEkmanEmotion(String predClass) {
    const ekmanMapping = {
      "anger": ["anger", "annoyance", "disapproval"],
      "disgust": ["disgust"],
      "fear": ["fear", "nervousness"],
      "happy": [
        "joy",
        "amusement",
        "approval",
        "excitement",
        "gratitude",
        "love",
        "optimism",
        "relief",
        "pride",
        "admiration",
        "desire",
        "caring"
      ],
      "sad": ["sadness", "disappointment", "embarrassment", "grief", "remorse"],
      "surprise": ["surprise", "realization", "confusion", "curiosity"],
      "neutral": ["neutral"]
    };

    for (var entry in ekmanMapping.entries) {
      if (entry.value.contains(predClass.toLowerCase())) {
        return entry.key;
      }
    }
    return '';
  }
}

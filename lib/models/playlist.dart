import 'package:cloud_firestore/cloud_firestore.dart';
import 'songs.dart'; // Ensure you import the Songs model

class Playlist {
  final String id;
  final String name;
  final String description;
  final List<Songs> songs;
  final String userId;
  final DateTime createdAt;
  final String? imageUrl;

  Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.songs,
    required this.userId,
    required this.createdAt,
    this.imageUrl,
  });

  // Updated method to convert Firestore data to Playlist object
  factory Playlist.fromFirestore(DocumentSnapshot doc) {
    // Ensure we're working with a valid DocumentSnapshot
    if (!doc.exists) {
      throw Exception('Document does not exist');
    }

    // Safely cast the data
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    return Playlist(
      id: doc.id, // Use the document ID directly
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      // Safely handle songs list
      songs: data['songs'] != null
          ? List<Map<String, dynamic>>.from(data['songs'])
              .map((songData) => Songs.fromFirestore1(songData))
              .toList()
          : [],
      userId: data['userId'] ?? '',
      // Handle timestamp conversion safely
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      imageUrl: data['imageUrl'],
    );
  }

  // Updated method to fetch user playlists
  static Future<List<Playlist>> fetchUserPlaylists(String userId) async {
    try {
      // Directly query the playlists collection
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('playlists')
          .get();

      // Map query snapshots to Playlist objects
      return querySnapshot.docs.map((doc) {
        // Ensure we're passing a DocumentSnapshot
        return Playlist.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error in fetchUserPlaylists: $e');
      throw Exception('Failed to fetch playlists: ${e.toString()}');
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'songs': songs.map((song) => song.toFirestore()).toList(),
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
    };
  }

  // Static method to add a song to a playlist
  static Future<void> addSongToPlaylist(
      String userId, String playlistId, Songs song) async {
    try {
      DocumentReference playlistRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('playlists')
          .doc(playlistId);

      // Get the current playlist
      DocumentSnapshot doc = await playlistRef.get();

      if (doc.exists) {
        // Convert the document to a Playlist object
        Playlist playlist = Playlist.fromFirestore(doc);

        // Check if song already exists in the playlist
        bool songExists = playlist.songs.any((s) => s.trackId == song.trackId);
        if (songExists) {
          throw Exception('Song already exists in the playlist');
        }

        // Add the new song
        playlist.songs.add(song);

        // Update the playlist in Firestore
        await playlistRef.update(
            {'songs': playlist.songs.map((s) => s.toFirestore()).toList()});
      } else {
        throw Exception('Playlist not found');
      }
    } catch (e) {
      print('Error adding song to playlist: $e');
      rethrow;
    }
  }

  // Method to create a new playlist
  static Future<Playlist> createPlaylist({
    required String userId,
    required String name,
    String description = '',
    List<Songs>? initialSongs,
  }) async {
    try {
      // Create a reference to the new playlist document
      DocumentReference playlistRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('playlists')
          .doc();

      // Create the playlist object
      Playlist newPlaylist = Playlist(
        id: playlistRef.id,
        name: name,
        description: description,
        songs: initialSongs ?? [],
        userId: userId,
        createdAt: DateTime.now(),
      );

      // Save the playlist to Firestore
      await playlistRef.set(newPlaylist.toFirestore());

      return newPlaylist;
    } catch (e) {
      print('Error creating playlist: $e');
      rethrow;
    }
  }

  Future<void> addPlaylistToFirestore(Playlist playlist) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(playlist.userId)
          .collection('playlists')
          .doc(playlist.id)
          .set(playlist.toFirestore());
    } catch (e) {
      print('Error adding playlist to Firestore: $e');
    }
  }
}

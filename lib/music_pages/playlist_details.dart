import 'package:flutter/material.dart';
import '../models/playlist.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/songs.dart';
import 'dart:convert';
import 'edit_playlist.dart';

class PlaylistDetailsPage extends StatefulWidget {
  final String playlistId;

  PlaylistDetailsPage({required this.playlistId});

  @override
  _PlaylistDetailsPageState createState() => _PlaylistDetailsPageState();
}

class _PlaylistDetailsPageState extends State<PlaylistDetailsPage> {
  late Future<Playlist> _playlistFuture;

  @override
  void initState() {
    super.initState();
    _playlistFuture = _fetchPlaylist();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Playlist'),
              onTap: () {
                Navigator.of(context).pop(); // Close bottom sheet
                _editPlaylist();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title:
                  Text('Delete Playlist', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop(); // Close bottom sheet
                _showDeletePlaylistConfirmation();
              },
            ),
          ],
        );
      },
    );
  }

  void _editPlaylist() async {
    final playlist = await _playlistFuture;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            EditPlaylistPage(playlist: playlist, playlistId: widget.playlistId),
      ),
    );

    // If playlist was updated, refresh the page
    if (result == true) {
      setState(() {
        _playlistFuture = _fetchPlaylist();
      });
    }
  }

  void _showDeletePlaylistConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Playlist'),
          content: Text(
              'Are you sure you want to delete this playlist? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _deletePlaylist();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deletePlaylist() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      // Delete playlist from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('playlists')
          .doc(widget.playlistId)
          .delete();

      // Navigate back to previous screen
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playlist deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting playlist: $e')),
      );
    }
  }

  Future<Playlist> _fetchPlaylist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('playlists')
        .doc(widget.playlistId)
        .get();

    if (!doc.exists) throw Exception('Playlist not found');

    return Playlist.fromFirestore(doc);
  }

  void _showDeleteConfirmationDialog(Songs song) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Song'),
          content: Text(
              'Are you sure you want to delete this song from the playlist?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _removeSong(song); // Remove the song
              },
              child: Text('Delete'),
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
        title: Text('Playlist Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              _showOptionsMenu();
            },
          ),
        ],
      ),
      body: FutureBuilder<Playlist>(
        future: _playlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('Playlist not found'));
          }

          final playlist = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  height: 300,
                  decoration: playlist.imageUrl == null
                      ? BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.lightBlue.shade400,
                              Colors.lightBlue.shade700,
                            ],
                          ),
                        )
                      : null, // No gradient if there's an image
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background gradient remains the same
                      if (playlist.imageUrl != null)
                        Positioned.fill(
                          child: Opacity(
                            opacity: 1.0,
                            child: Image.memory(
                              base64Decode(playlist.imageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Positioned.fill(
                          child: Container(color: Colors.lightBlue.shade500),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Playlist Name
                            Text(
                              playlist.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 5),
                            // Playlist Description
                            Text(
                              playlist.description.isNotEmpty
                                  ? playlist.description
                                  : 'No description',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 5),
                            // Song Count
                            Row(
                              children: [
                                Icon(Icons.music_note,
                                    color: Colors.white70, size: 16),
                                SizedBox(width: 5),
                                Text(
                                  '${playlist.songs.length} Songs',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = playlist.songs[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _getEmotionColor(song.emotion),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                song.genre[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            song.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.artist,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getEmotionColor(song.emotion)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      song.emotion,
                                      style: TextStyle(
                                        color: _getEmotionColor(song.emotion),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      song.genre,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            onPressed: () {
                              _showDeleteConfirmationDialog(song);
                            },
                          ),
                          onTap: () {
                            openSpotify(song.trackId); // Open Spotify URL
                          },
                        ),
                      );
                    },
                    childCount: playlist.songs.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _removeSong(Songs song) async {
    final playlist = await _playlistFuture;
    setState(() {
      playlist.songs.remove(song);
    });

    // Update the playlist in Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('playlists')
          .doc(widget.playlistId)
          .update({
        'songs': playlist.songs.map((s) => s.toFirestore()).toList(),
      });
    }
  }

  void openSpotify(String trackId) async {
    final Uri webUrl = Uri.parse('https://open.spotify.com/track/$trackId');
    await _launchUrl(webUrl);
  }

  Future _launchUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  // Helper method to get color based on emotion
  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Colors.amber;
      case 'sad':
        return Colors.blue;
      case 'energetic':
        return Colors.red;
      case 'calm':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

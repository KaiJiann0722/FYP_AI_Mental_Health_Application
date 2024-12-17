import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/songs.dart';
import '../models/playlist.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddToPlaylistDialog extends StatefulWidget {
  final Songs song;

  const AddToPlaylistDialog({Key? key, required this.song}) : super(key: key);

  @override
  _AddToPlaylistDialogState createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<AddToPlaylistDialog> {
  final TextEditingController _playlistNameController = TextEditingController();
  final TextEditingController _playlistDescController = TextEditingController();

  List<Playlist> _userPlaylists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserPlaylists();
  }

  Future<void> _fetchUserPlaylists() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch user's playlists from Firestore
      QuerySnapshot playlistDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('playlists')
          .get();

      setState(() {
        _userPlaylists = playlistDocs.docs
            .map((doc) => Playlist.fromFirestore(doc))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching playlists: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addSongToPlaylist(Playlist playlist) async {
    try {
      await Playlist.addSongToPlaylist(
          playlist.userId, playlist.id, widget.song);

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Song added to ${playlist.name}'),
        backgroundColor: Colors.green,
      ));

      // Close the dialog
      Navigator.of(context).pop();
    } catch (e) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to add song to playlist'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _createNewPlaylist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_playlistNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Playlist name cannot be empty'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      // Create a new playlist
      final newPlaylist = Playlist(
        id: FirebaseFirestore.instance.collection('playlists').doc().id,
        name: _playlistNameController.text,
        description: _playlistDescController.text,
        songs: [widget.song],
        userId: user.uid,
        createdAt: DateTime.now(),
      );

      // Save the new playlist
      await newPlaylist.addPlaylistToFirestore(newPlaylist);

      // Close the dialog and show success
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Playlist ${newPlaylist.name} created'),
        backgroundColor: Colors.green,
      ));
      _fetchUserPlaylists();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to create playlist'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row with Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add to Playlist',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Existing Playlists Section
              Text(
                'Your Playlists',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _userPlaylists.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'No playlists found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics:
                              NeverScrollableScrollPhysics(), // Disable ListView's scrolling
                          itemCount: _userPlaylists.length,
                          itemBuilder: (context, index) {
                            final playlist = _userPlaylists[index];
                            return ListTile(
                              title: Text(playlist.name),
                              subtitle: Text('${playlist.songs.length} songs'),
                              trailing: IconButton(
                                icon:
                                    Icon(Icons.add_circle, color: Colors.green),
                                onPressed: () => _addSongToPlaylist(playlist),
                              ),
                            );
                          },
                        ),

              Divider(height: 32),

              // Create New Playlist Section
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => _buildCreatePlaylistDialog(),
                      );
                    },
                    child: Text('Create New Playlist'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Create New Playlist Dialog
  Widget _buildCreatePlaylistDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Playlist',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _playlistNameController,
              decoration: InputDecoration(
                labelText: 'Playlist Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _playlistDescController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _createNewPlaylist,
                  child: Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _playlistNameController.dispose();
    _playlistDescController.dispose();
    super.dispose();
  }
}

// Extension method to show the dialog easily from SongDetailsPage
extension AddToPlaylistExtension on BuildContext {
  void showAddToPlaylistDialog(Songs song) {
    showDialog(
      context: this,
      builder: (context) => AddToPlaylistDialog(song: song),
    );
  }
}

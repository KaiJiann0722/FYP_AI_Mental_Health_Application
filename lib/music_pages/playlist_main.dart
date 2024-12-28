import 'package:flutter/material.dart';
import '../models/playlist.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'playlist_details.dart';

enum SortOption { newest, oldest, nameAtoZ, nameZtoA }

class PlaylistMainPage extends StatefulWidget {
  const PlaylistMainPage({Key? key}) : super(key: key);

  @override
  _PlaylistMainPageState createState() => _PlaylistMainPageState();
}

class _PlaylistMainPageState extends State<PlaylistMainPage> {
  bool _isGridView = false;

  final TextEditingController _playlistNameController = TextEditingController();
  final TextEditingController _playlistDescController = TextEditingController();

  List<Playlist> playlists = [];
  SortOption _sortOption = SortOption.newest;
  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _fetchUserPlaylists();
  }

  Future<void> _fetchUserPlaylists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('playlists')
          .get();

      setState(() {
        playlists = querySnapshot.docs.map((doc) {
          return Playlist.fromFirestore(doc);
        }).toList();
        _sortPlaylists(); // Sort playlists after fetching
        _isLoading = false; // Set loading to false after fetching
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // Ensure loading is set to false even on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch playlists'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sortPlaylists() {
    setState(() {
      switch (_sortOption) {
        case SortOption.newest:
          playlists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case SortOption.oldest:
          playlists.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case SortOption.nameAtoZ:
          playlists.sort((a, b) => a.name.compareTo(b.name));
          break;
        case SortOption.nameZtoA:
          playlists.sort((a, b) => b.name.compareTo(a.name));
          break;
      }
    });
  }

  @override
  void dispose() {
    _playlistNameController.dispose();
    _playlistDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Playlists',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Sorting Dropdown
          PopupMenuButton<SortOption>(
            icon: Icon(
              Icons.sort,
            ),
            onSelected: (SortOption option) {
              setState(() {
                _sortOption = option;
                _sortPlaylists();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortOption.newest,
                child: Text('Newest First'),
              ),
              PopupMenuItem(
                value: SortOption.oldest,
                child: Text('Oldest First'),
              ),
              PopupMenuItem(
                value: SortOption.nameAtoZ,
                child: Text('Name (A-Z)'),
              ),
              PopupMenuItem(
                value: SortOption.nameZtoA,
                child: Text('Name (Z-A)'),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: playlists.isEmpty
                  ? _buildEmptyState()
                  : _isGridView
                      ? _buildGridView()
                      : _buildListView(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePlaylistDialog,
        backgroundColor: Colors.lightBlue,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.lightBlue,
          ),
          SizedBox(height: 16),
          Text(
            'Loading Playlists...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music,
            size: 100,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 20),
          Text(
            'No Playlists Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Tap the + button to create your first playlist',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return _buildPlaylistCard(playlist, isGrid: true);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return _buildPlaylistCard(playlist, isGrid: false);
      },
    );
  }

  Widget _buildPlaylistCard(Playlist playlist, {bool isGrid = true}) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistDetailsPage(playlistId: playlist.id),
          ),
        );

        await _fetchUserPlaylists();
      },
      child: isGrid ? _buildGridCard(playlist) : _buildListCard(playlist),
    );
  }

  Widget _buildGridCard(Playlist playlist) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade100,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Center(
              child: Icon(
                Icons.music_note,
                size: 60,
                color: Colors.lightBlue.shade300,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  Text(
                    '${playlist.songs.length} Songs',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Date Created: ${playlist.createdAt.toString().split(' ')[0]}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(Playlist playlist) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.lightBlue.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              Icons.music_note,
              size: 30,
              color: Colors.lightBlue.shade300,
            ),
          ),
        ),
        title: Text(
          playlist.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${playlist.songs.length} Songs',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Date Created: ${playlist.createdAt.toLocal().toString().split(' ')[0]}',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.lightBlue,
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    // Reset controllers
    _playlistNameController.clear();
    _playlistDescController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create New Playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _playlistNameController,
                decoration: InputDecoration(
                  hintText: 'Playlist Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _playlistDescController,
                decoration: InputDecoration(
                  hintText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // font color
              ),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _createNewPlaylist,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue, // background color
                foregroundColor: Colors.white, // font color
              ),
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewPlaylist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to create a playlist'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate playlist name
    if (_playlistNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playlist name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Create a new playlist
      final newPlaylist = Playlist(
        id: FirebaseFirestore.instance.collection('playlists').doc().id,
        name: _playlistNameController.text.trim(),
        description: _playlistDescController.text.trim(),
        songs: [], // Start with an empty list of songs
        userId: user.uid,
        createdAt: DateTime.now(),
      );

      // Save the new playlist to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('playlists')
          .doc(newPlaylist.id)
          .set(newPlaylist.toFirestore());

      // Close the dialog
      Navigator.of(context).pop();
      _fetchUserPlaylists();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playlist ${newPlaylist.name} created'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the list of playlists
      _fetchUserPlaylists();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create playlist: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

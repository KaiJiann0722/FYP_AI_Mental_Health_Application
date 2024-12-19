import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_fyp/models/songs.dart';
import 'package:url_launcher/url_launcher.dart';
import 'song_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'playlist_main.dart';

class MusicMainPage extends StatefulWidget {
  @override
  _MusicMainPageState createState() => _MusicMainPageState();
}

class _MusicMainPageState extends State<MusicMainPage> {
  Map<String, List<Songs>> moodSongs = {};
  List<Songs> allSongs = [];
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedEmotion = 'All';
  String _selectedGenre = 'All';
  List<String> _emotions = ['All', 'Happy', 'Sad', 'Energetic', 'Calm'];
  // Comprehensive genre list
  final List<String> _genres = [
    'All',
    'acoustic',
    'alternative',
    'anime',
    'british',
    'cantopop',
    'classical',
    'dance',
    'emo',
    'guitar',
    'indie',
    'jazz',
    'latin',
    'malay',
    'mandopop',
    'metal',
    'piano',
    'pop',
    'r-n-b',
    'rock',
    'study',
    'soul',
    'world-music'
  ];

  DocumentSnapshot? lastDocument;
  bool isLoading = false;
  bool hasMore = true;

  final Map<String, EmotionConfig> _emotionConfigs = {
    'All': EmotionConfig(color: Colors.grey, icon: Icons.music_note),
    'Happy': EmotionConfig(
        color: Colors.yellow[700]!, icon: Icons.sentiment_very_satisfied),
    'Sad': EmotionConfig(
        color: Colors.blue[900]!, icon: Icons.sentiment_dissatisfied),
    'Energetic': EmotionConfig(color: Colors.red, icon: Icons.bolt),
    'Calm': EmotionConfig(color: Colors.green, icon: Icons.spa),
  };

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  void _loadSongs() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    Query query = FirebaseFirestore.instance.collection('songs');

    if (_selectedEmotion != 'All') {
      query = query.where('emotion', isEqualTo: _selectedEmotion);
    }

    if (_selectedGenre != 'All') {
      query = query.where('track_genre', isEqualTo: _selectedGenre);
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      lastDocument = querySnapshot.docs.last;
      allSongs.addAll(
          querySnapshot.docs.map((doc) => Songs.fromFirestore(doc)).toList());
    }

    if (querySnapshot.docs.length < 10000) {
      hasMore = false;
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    allSongs.clear(); // Clear the list to free up memory
    super.dispose();
  }

  List<Songs> _filterSongs() {
    return allSongs.where((song) {
      bool matchesSearch =
          song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              song.artist.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesEmotion =
          _selectedEmotion == 'All' || song.emotion == _selectedEmotion;
      bool matchesGenre =
          _selectedGenre == 'All' || song.genre == _selectedGenre;
      return matchesSearch && matchesEmotion && matchesGenre;
    }).toList();
  }

  Widget _buildGenreChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: _genres.map((genre) {
            bool isSelected = _selectedGenre == genre;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(
                  genre,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.lightBlue, // Vibrant selection color

                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation:
                    isSelected ? 4 : 1, // Subtle elevation for selected chip
                avatar: _buildGenreIcon(genre), // Add an icon for each genre
                onSelected: (bool selected) {
                  setState(() {
                    _selectedGenre = genre;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Icon _buildGenreIcon(String genre) {
    switch (genre.toLowerCase()) {
      case 'all':
        return Icon(Icons.library_music, color: Colors.blue);
      case 'acoustic':
        return Icon(Icons.music_note, color: Colors.brown);
      case 'alternative':
        return Icon(Icons.electric_bolt, color: Colors.purple);
      case 'anime':
        return Icon(Icons.animation, color: Colors.pink);
      case 'british':
        return Icon(Icons.flag, color: Colors.lightBlue);
      case 'cantopop':
        return Icon(Icons.music_note, color: Colors.orange);
      case 'classical':
        return Icon(Icons.piano, color: Colors.brown[700]);
      case 'dance':
        return Icon(Icons.nightlife, color: Colors.deepPurple);
      case 'emo':
        return Icon(Icons.mood, color: Colors.black);
      case 'guitar':
        return Icon(Icons.music_note, color: Colors.amber);
      case 'indie':
        return Icon(Icons.album, color: Colors.teal);
      case 'jazz':
        return Icon(Icons.music_note, color: Colors.deepOrange);
      case 'latin':
        return Icon(Icons.festival, color: Colors.red);
      case 'malay':
        return Icon(Icons.music_note, color: Colors.green);
      case 'mandopop':
        return Icon(Icons.queue_music, color: Colors.red);
      case 'metal':
        return Icon(Icons.electric_bolt, color: Colors.grey[800]);
      case 'piano':
        return Icon(Icons.piano, color: Colors.indigo);
      case 'pop':
        return Icon(Icons.star, color: Colors.pink);
      case 'r-n-b':
        return Icon(Icons.queue_music, color: Colors.purple);
      case 'rock':
        return Icon(Icons.rocket, color: Colors.red);
      case 'study':
        return Icon(Icons.book, color: Colors.blue);
      case 'soul':
        return Icon(Icons.favorite, color: Colors.red);
      case 'world-music':
        return Icon(Icons.public, color: Colors.green);
      default:
        return Icon(Icons.music_note, color: Colors.grey);
    }
  }

  Widget _buildEmotionChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: _emotions.map((emotion) {
            bool isSelected = _selectedEmotion == emotion;
            EmotionConfig config = _emotionConfigs[emotion]!;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(emotion),
                selected: isSelected,
                selectedColor: config.color.withOpacity(0.3),
                avatar: Icon(
                  config.icon,
                  color: isSelected ? config.color : Colors.grey,
                ),
                onSelected: (bool selected) {
                  setState(() {
                    _selectedEmotion = emotion;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSongList() {
    List<Songs> filteredSongs = _filterSongs();

    if (filteredSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No songs found',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredSongs.length,
      itemBuilder: (context, index) {
        Songs song = filteredSongs[index];
        EmotionConfig config =
            _emotionConfigs[song.emotion] ?? _emotionConfigs['All']!;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: config.color.withOpacity(0.2),
              child: Icon(config.icon, color: config.color),
            ),
            title: Text(
              song.title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SongDetailsPage(
                  song: song,
                  userId: FirebaseAuth.instance.currentUser!.uid,
                ),
              ),
            ),
            subtitle: Text(
              '${song.artist}\n${song.emotion} • ${song.genre}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.play_circle_fill,
                color: Colors.green,
              ),
              onPressed: () => openSpotify(song.trackId),
            ),
          ),
        );
      },
    );
  }

  void _clearResources() {
    _searchQuery = '';
    _selectedEmotion = 'All';
    _selectedGenre = 'All';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emotion Music',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.playlist_play),
            onPressed: () {
              _clearResources();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlaylistMainPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Songs',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          _buildEmotionChips(),
          _buildGenreChips(),
          SizedBox(height: 8),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!isLoading &&
                    scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                  _loadSongs();
                }
                return false;
              },
              child: _buildSongList(),
            ),
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void openSpotify(String trackId) async {
    final Uri webUrl = Uri.parse('https://open.spotify.com/track/$trackId');
    await _launchUrl(webUrl);
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}

// Helper class to manage emotion configurations
class EmotionConfig {
  final Color color;
  final IconData icon;

  EmotionConfig({required this.color, required this.icon});
}

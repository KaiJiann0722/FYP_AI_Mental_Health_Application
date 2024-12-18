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
    'afrobeat',
    'alternative',
    'ambient',
    'anime',
    'bluegrass',
    'blues',
    'british',
    'cantopop',
    'classical',
    'dance',
    'deep-house',
    'disco',
    'dub',
    'dubstep',
    'edm',
    'electronic',
    'emo',
    'folk',
    'funk',
    'guitar',
    'heavy-metal',
    'hip-hop',
    'house',
    'indie',
    'jazz',
    'latin',
    'malay',
    'mandopop',
    'metal',
    'piano',
    'pop',
    'progressive-house',
    'punk',
    'r-n-b',
    'reggae',
    'reggaeton',
    'rock',
    'singer-songwriter',
    'ska',
    'sleep',
    'study',
    'soul',
    'synth-pop',
    'techno',
    'trance',
    'trip-hop',
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
        return Icon(Icons.music_note, color: Colors.grey);
      case 'pop':
        return Icon(Icons.music_note, color: Colors.pink);
      case 'jazz':
        return Icon(Icons.piano, color: Colors.brown);
      case 'electronic':
      case 'edm':
      case 'techno':
      case 'house':
        return Icon(Icons.electric_bolt, color: Colors.teal);
      case 'hiphop':
      case 'rap':
        return Icon(Icons.radio, color: Colors.deepOrange);
      case 'country':
        return Icon(Icons.star, color: Colors.yellow);
      case 'blues':
        return Icon(Icons.music_note_outlined, color: Colors.blue);
      case 'folk':
        return Icon(Icons.nature_people, color: Colors.green);
      case 'metal':
        return Icon(Icons.bolt, color: Colors.grey);
      case 'indie':
        return Icon(Icons.album, color: Colors.indigo);
      case 'punk':
        return Icon(Icons.warning, color: Colors.red);
      case 'reggae':
        return Icon(Icons.sunny, color: Colors.green);
      case 'soul':
        return Icon(Icons.favorite, color: Colors.red);
      case 'funk':
        return Icon(Icons.star_border, color: Colors.purple);
      case 'ambient':
        return Icon(Icons.cloud, color: Colors.lightBlue);
      case 'latin':
        return Icon(Icons.place, color: Colors.red);
      case 'brazilian':
        return Icon(Icons.sports_soccer, color: Colors.green);
      case 'french':
        return Icon(Icons.location_city, color: Colors.blue);
      case 'german':
        return Icon(Icons.flag, color: Colors.black);
      case 'spanish':
        return Icon(Icons.terrain, color: Colors.red);
      case 'indian':
        return Icon(Icons.palette, color: Colors.orange);
      case 'japanese':
        return Icon(Icons.wb_sunny, color: Colors.red);
      case 'korean':
        return Icon(Icons.stars, color: Colors.blue);
      case 'turkish':
        return Icon(Icons.landscape, color: Colors.green);
      case 'gospel':
        return Icon(Icons.church, color: Colors.purple);
      case 'opera':
        return Icon(Icons.theater_comedy, color: Colors.blue);
      case 'singersongwriter':
        return Icon(Icons.mic, color: Colors.orange);
      case 'dubstep':
        return Icon(Icons.waves, color: Colors.blue);
      case 'trance':
        return Icon(Icons.blur_circular, color: Colors.purple);
      case 'happy':
        return Icon(Icons.sentiment_very_satisfied, color: Colors.yellow);
      case 'sad':
        return Icon(Icons.sentiment_dissatisfied, color: Colors.blue);
      case 'chill':
        return Icon(Icons.beach_access, color: Colors.lightBlue);
      case 'party':
        return Icon(Icons.celebration, color: Colors.pink);
      case 'anime':
        return Icon(Icons.animation, color: Colors.purple);
      case 'videogame':
        return Icon(Icons.gamepad, color: Colors.green);
      case 'lofi':
        return Icon(Icons.music_off, color: Colors.brown);
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
              icon: Icon(Icons.open_in_new),
              onPressed: () => openSpotify(song.trackId),
            ),
          ),
        );
      },
    );
  }

  void _clearResources() {
    // Clear any lists or dispose of any controllers here
    allSongs.clear();
    lastDocument = null;
    isLoading = false;
    hasMore = true;
    _searchQuery = '';
    _selectedEmotion = 'All';
    _selectedGenre = 'All';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mood Music'),
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

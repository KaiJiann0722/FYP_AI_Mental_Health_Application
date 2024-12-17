import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emotion.dart';
import '../models/songs.dart'; // Import the Songs class
import '../music_pages/song_details.dart'; // Import the SongDetailsPage
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/playlist.dart'; // Import the Playlist class
import 'package:firebase_auth/firebase_auth.dart';
import '../layout_pages/nav_menu.dart';
import 'utils.dart';

class MusicRecommendationsPage extends StatefulWidget {
  final Emotion highestEmotion;
  final String clientId =
      '742fb2419cd547beb7ee0db6ab9f1ab8'; // Replace with your Spotify client ID
  final String clientSecret =
      'b06ebf32a97b42bda6cb5a7f5c314977'; // Replace with your Spotify client secret

  const MusicRecommendationsPage({Key? key, required this.highestEmotion})
      : super(key: key);

  @override
  _MusicRecommendationsPageState createState() =>
      _MusicRecommendationsPageState();
}

class _MusicRecommendationsPageState extends State<MusicRecommendationsPage> {
  late Future<List<Songs>> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = Songs.getRecommendations(
        widget.highestEmotion.emotion, widget.clientId, widget.clientSecret);
  }

  void _regenerateSongs() {
    setState(() {
      _recommendationsFuture = Songs.getRecommendations(
          widget.highestEmotion.emotion, widget.clientId, widget.clientSecret);
    });
  }

  void _saveToPlaylist(List<Songs> songs) async {
    Playlist playlist = Playlist(
      id: FirebaseFirestore.instance.collection('playlists').doc().id,
      name: 'My Playlist',
      description:
          'A collection of songs based on ${widget.highestEmotion.emotion}',
      songs: songs,
      userId: FirebaseAuth
          .instance.currentUser!.uid, // Replace with the actual user ID
      createdAt: DateTime.now(),
    );
    await playlist.addPlaylistToFirestore(playlist);
  }

  @override
  Widget build(BuildContext context) {
    int currentStep = 2; // Track the current step
    final steps = ['Journal', 'Emotion', 'Music']; // Define the steps

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Recommendations'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => NavMenu()), // Redirect to JournalMainPage
            (Route<dynamic> route) => false, // Remove all previous routes
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressStepper(currentStep: currentStep, steps: steps),
            const SizedBox(height: 24),
            Text(
              'Based on your emotion ${widget.highestEmotion.emotion}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            FutureBuilder<List<Songs>>(
              future: _recommendationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No recommendations available'));
                } else {
                  return Column(
                    children: [
                      _buildMoodSection('Recommended Songs', snapshot.data!),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _regenerateSongs,
                        child: Text('Regenerate Songs'),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => _saveToPlaylist(snapshot.data!),
                        child: Text('Save to Playlist'),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSection(String title, List<Songs> songs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            itemBuilder: (context, index) {
              return _buildSongCard(songs[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSongCard(Songs song) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongDetailsPage(
              song: song,
              userId: FirebaseAuth.instance.currentUser!.uid,
            ),
          ),
        ),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1.5, // Consistent image aspect ratio
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: song.imageUrl.isNotEmpty
                      ? Image.network(song.imageUrl, fit: BoxFit.cover)
                      : Center(child: Icon(Icons.music_note, size: 40)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        song.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            song.emotion,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

// music_recommendations_page.dart
import 'package:flutter/material.dart';
import '../models/songs.dart';

class MusicRecommendationsPage extends StatelessWidget {
  const MusicRecommendationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Recommendations'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Based on your mood...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _buildMoodSection('Happy Vibes', [
              Songs(
                title: 'Happy',
                artist: 'Pharrell Williams',
                imageUrl: 'https://example.com/happy.jpg',
                mood: '😊 Uplifting',
              ),
              Songs(
                title: 'Good Life',
                artist: 'OneRepublic',
                imageUrl: 'https://example.com/goodlife.jpg',
                mood: '✨ Energetic',
              ),
            ]),
            SizedBox(height: 20),
            _buildMoodSection('Calm & Relaxing', [
              Songs(
                title: 'Weightless',
                artist: 'Marconi Union',
                imageUrl: 'https://example.com/weightless.jpg',
                mood: '😌 Peaceful',
              ),
              Songs(
                title: 'River Flows in You',
                artist: 'Yiruma',
                imageUrl: 'https://example.com/river.jpg',
                mood: '🌊 Serene',
              ),
            ]),
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
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(child: Icon(Icons.music_note, size: 40)),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    song.artist,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      song.mood,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmotionController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch the frequency of emotions for each date
  Future<Map<String, Map<String, int>>> fetchEmotionFrequencies() async {
    Map<String, Map<String, int>> emotionFrequencies = {};

    try {
      // Query all journal entries
      QuerySnapshot snapshot = await _firestore.collection('journal').get();

      // Iterate through each document in the snapshot
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Ensure the entryDate and emotions are properly fetched
        if (data['entryDate'] == null || data['emotions'] == null) continue;

        // Extract date and emotions
        DateTime entryDate = (data['entryDate'] as Timestamp).toDate();
        String dateKey = DateFormat('yyyy-MM-dd').format(entryDate);
        List emotions = data['emotions'];

        // Initialize map for the date if not already present
        if (!emotionFrequencies.containsKey(dateKey)) {
          emotionFrequencies[dateKey] = {};
        }

        // Process each emotion in the entry
        for (var emotionData in emotions) {
          if (emotionData is Map && emotionData.containsKey('emotion')) {
            String emotion = emotionData['emotion'] ?? 'Unknown';

            // Print the fetched emotion
            print('Fetched emotion: $emotion');

            // Increment the frequency for the detected emotion
            if (emotionFrequencies[dateKey]!.containsKey(emotion)) {
              emotionFrequencies[dateKey]![emotion] =
                  emotionFrequencies[dateKey]![emotion]! + 1;
            } else {
              emotionFrequencies[dateKey]![emotion] = 1;
            }
          }
        }
      }
    } catch (e) {
      // Handle errors and print error message
      print('Error fetching emotion data: $e');
    }

    return emotionFrequencies;
  }
}

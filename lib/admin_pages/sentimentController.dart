import 'package:cloud_firestore/cloud_firestore.dart';

class SentimentController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all journals and extract the userId
  Future<List<String>> fetchUserIdsFromJournals() async {
    try {
      // Get the 'journals' collection from Firestore
      QuerySnapshot snapshot = await _firestore.collection('journal').get();

      // Set to store unique user IDs
      Set<String> userIdsSet = Set<String>();

      // Iterate through the documents
      for (var doc in snapshot.docs) {
        // Assuming each journal document has a 'userId' field
        String userId = doc['userId'];

        // Add userId to the set (duplicates will be ignored)
        userIdsSet.add(userId);
      }

      // Convert the set to a list
      List<String> userIds = userIdsSet.toList();

      print("Fetched Unique User Data: $userIds");
      return userIds;
    } catch (e) {
      print('Error fetching user IDs: $e');
      return [];
    }
  }

  Future<Map<String, String>> fetchUserDetails(String userId) async {
    try {
      // Get the user document based on the userId
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (userSnapshot.exists) {
        // Extract the firstName and lastName from the document
        String firstName = userSnapshot['firstName'];
        String lastName = userSnapshot['lastName'];

        // Return the user details as a Map
        return {'firstName': firstName, 'lastName': lastName};
      } else {
        print('User not found for userId: $userId');
        return {}; // Return empty if user is not found
      }
    } catch (e) {
      print('Error fetching user details: $e');
      return {}; // Return empty in case of error
    }
  }

  Future<List<String>> fetchUserDetailsForAllJournals() async {
    List<String> userFullNames = []; // List to store full names

    try {
      // Fetch unique userIds from journals
      List<String> userIds = await fetchUserIdsFromJournals();

      // For each userId, fetch their details (firstName, lastName)
      for (String userId in userIds) {
        Map<String, String> userDetails = await fetchUserDetails(userId);

        if (userDetails.isNotEmpty) {
          String firstName = userDetails['firstName'] ?? 'N/A';
          String lastName = userDetails['lastName'] ?? 'N/A';

          // Combine first and last name
          String fullName = '$firstName $lastName';

          // Add full name to the list
          userFullNames.add(fullName);

          // Optionally print user details
          print('User ID: $userId, Full Name: $fullName');
        }
      }
    } catch (e) {
      print('Error fetching user details for all journals: $e');
    }

    // Return the list of full names
    return userFullNames;
  }

  // Fetch sentiment data for each user
  Future<Map<String, dynamic>> fetchSentimentOverview(String userId) async {
    try {
      // Query all journal entries from Firestore
      QuerySnapshot snapshot = await _firestore.collection('journal').get();
      print(
          "Snapshot documents: ${snapshot.docs.map((doc) => doc.data()).toList()}");

      // Map to store sentiment data for the specific user
      Map<String, dynamic> userSentimentData = {
        'positive': 0,
        'neutral': 0,
        'negative': 0,
        'compoundScores': <double>[],
        'dates': <DateTime>[],
      };

      for (var doc in snapshot.docs) {
        // Extract necessary information from each journal entry
        String entryUserId = doc['userId'];
        double compoundScore = doc['sentiment']['compound'];
        String sentimentLabel = doc['sentiment']['label'];
        Timestamp entryDate = doc['entryDate'];
        DateTime dateTime = entryDate.toDate();

        // Filter by userId
        if (entryUserId == userId) {
          // Update sentiment counts and scores for the user
          if (sentimentLabel == 'Positive') {
            userSentimentData['positive']++;
          } else if (sentimentLabel == 'Neutral') {
            userSentimentData['neutral']++;
          } else if (sentimentLabel == 'Negative') {
            userSentimentData['negative']++;
          }

          // Add compound score and entry date
          userSentimentData['compoundScores']?.add(compoundScore);
          userSentimentData['dates']?.add(dateTime);
        }
      }

      print("Fetched Sentiment Data for User $userId: $userSentimentData");
      return userSentimentData;
    } catch (e) {
      print('Error fetching sentiment data: $e');
      return {};
    }
  }

  // Calculate average sentiment score for each user
  double calculateAverageSentiment(List<double> compoundScores) {
    if (compoundScores.isEmpty) return 0.0;
    double totalScore = compoundScores.reduce((a, b) => a + b);
    double avgSentiment = totalScore / compoundScores.length;
    print("Calculated AVG SENTIMENT $avgSentiment");
    return avgSentiment;
  }
}

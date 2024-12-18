import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/journal_model.dart';

class JournalFormatter {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getFormattedJournalContent(String journalId, String userName,
      String journalContent, String sentiment) async {
    try {
      // Retrieve the journal by ID
      Journal? journal = await _databaseService.getJournalById(journalId);

      if (journal == null) {
        return 'Journal not found.';
      }

      // Format the journal content
      String formattedContent = '''
My name is $userName and this is my journal,
"$journalContent"
I am feeling $sentiment now.
''';

      // Print the formatted content
      // print('Formatted Journal Content: $formattedContent');

      return formattedContent;
    } catch (e) {
      print('Error: $e');
      return 'Error retrieving or formatting journal content: $e';
    }
  }

  Future<String> fetchUserName(String userId) async {
    try {
      // Get the user document based on the userId
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (userSnapshot.exists) {
        // Extract the firstName and lastName from the document
        String firstName = userSnapshot['firstName'];
        String lastName = userSnapshot['lastName'];

        // Combine firstName and lastName into a full name
        String userName = '$firstName $lastName';
        return userName;
      } else {
        print('User not found for userId: $userId');
        return 'Unknown User'; // Return default value if user not found
      }
    } catch (e) {
      print('Error fetching username: $e');
      return 'Error'; // Return error if something goes wrong
    }
  }
}

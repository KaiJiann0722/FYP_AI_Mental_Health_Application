import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatHistory {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save the user input and bot response in the chatHistory collection
  Future<void> saveChatPair(
      String conversationId, String userMessage, String botResponse) async {
    try {
      // Get the current user
      User? user = _auth.currentUser;
      if (user == null) {
        print('No user is logged in');
        return;
      }

      String uid = user.uid;

      // Create a reference to the user's document in the 'users' collection
      DocumentReference userDoc = _firestore.collection('users').doc(uid);

      // Create a reference to the specific conversation in the 'chatHistory' sub-collection
      DocumentReference chatHistoryDoc =
          userDoc.collection('chatHistory').doc(conversationId);

      // Check if the conversation document exists
      DocumentSnapshot conversationSnapshot = await chatHistoryDoc.get();
      if (!conversationSnapshot.exists) {
        print('Conversation with ID $conversationId does not exist.');
        return;
      }

      // Prepare the conversation pair object
      var chatPair = {
        'userMessage': userMessage,
        'botResponse': botResponse,
        'timestamp': Timestamp.now(), // Timestamp for the chat pair
      };

      // Update the conversation array and the document timestamp
      await chatHistoryDoc.update({
        'conversation': FieldValue.arrayUnion(
            [chatPair]), // Adds chatPair to the conversation array
        'timestamp':
            FieldValue.serverTimestamp(), // Update the document timestamp
      });

      print(
          'Chat pair saved to conversation $conversationId with updated timestamp.');
    } catch (e) {
      print('Error saving chat pair: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getConversationIds() async {
    try {
      // Get the current user
      User? user = _auth.currentUser;
      if (user == null) {
        print('No user is logged in');
        return [];
      }

      String uid = user.uid;
      print('Current user ID: $uid'); // Debugging line

      // Retrieve all conversations from the chatHistory collection
      var result = await _firestore
          .collection('users')
          .doc(uid)
          .collection('chatHistory')
          .orderBy('timestamp', descending: true)
          .get();

      print(
          'Number of documents found: ${result.docs.length}'); // Debugging line

      List<Map<String, dynamic>> conversationList = [];

      for (var doc in result.docs) {
        print('ChatHistory document ID: ${doc.id}'); // Print the document ID

        // Retrieve the conversation field, even if it is empty
        var conversation = doc['conversation'] as List<dynamic>? ?? [];

        // Add conversation ID to the list even if the conversation is empty
        conversationList.add({
          'conversationId': doc.id, // Add the conversation ID
          'hasMessages':
              conversation.isNotEmpty, // Flag if the conversation has messages
          'lastUpdated': doc['timestamp'], // Include the last updated timestamp
        });
      }

      print('Retrieved conversation list: $conversationList');
      return conversationList;
    } catch (e) {
      print('Error retrieving conversation IDs: $e');
      return [];
    }
  }

  // Retrieve the chat history (user and bot messages stored as pairs) from the chatHistory collection
  Future<List<Map<String, dynamic>>> getChatHistory(
      String conversationId) async {
    try {
      // Get the current user
      User? user = _auth.currentUser;
      if (user == null) {
        print('No user is logged in');
        return [];
      }

      String uid = user.uid;
      print('Current user ID: $uid'); // Debugging line

      // Retrieve the specific conversation by its document ID (conversationId)
      var doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('chatHistory')
          .doc(conversationId) // Get the specific conversation document
          .get();

      // Check if the document exists
      if (doc.exists) {
        // Extract the 'conversation' field which should contain an array of user input and bot responses
        var conversation = doc['conversation'] as List<dynamic>? ?? [];

        List<Map<String, dynamic>> conversationList = [];

        // Process each item in the conversation
        for (var entry in conversation) {
          var userInput = entry['userMessage'] ?? '';
          var response = entry['botResponse'] ?? '';
          var timestamp = entry['timestamp'] ?? '';

          // Add user message and bot response to the conversation list
          conversationList.add({
            'sender': 'user',
            'text': userInput,
            'timestamp': timestamp,
          });

          conversationList.add({
            'sender': 'bot',
            'text': response,
            'timestamp': timestamp,
          });
        }

        print('Retrieved conversation: $conversationList');
        return conversationList;
      } else {
        print('Conversation with ID $conversationId not found.');
        return [];
      }
    } catch (e) {
      print('Error retrieving chat history: $e');
      return [];
    }
  }

  Future<String?> createNewConversation() async {
    try {
      // Get the current user
      User? user = _auth.currentUser;
      if (user == null) {
        print('No user is logged in');
        return null;
      }

      String uid = user.uid;
      print('Current user ID: $uid'); // Debugging line

      // Create a new conversation document with an empty conversation array
      var newConversationRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('chatHistory')
          .add({
        'conversation': [], // Initialize the conversation as an empty list
        'timestamp': FieldValue.serverTimestamp(), // Add a timestamp
      });

      print('New conversation created with ID: ${newConversationRef.id}');
      return newConversationRef.id; // Return the new conversation ID
    } catch (e) {
      print('Error creating new conversation: $e');
      return null;
    }
  }
}

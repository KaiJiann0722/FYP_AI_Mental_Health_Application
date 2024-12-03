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

// to save chat title
  Future<void> saveChatTitle(String conversationId, String title) async {
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
        print(
            'Conversation with ID $conversationId does not exist. Creating it now.');

        // Create the conversation document with the title
        await chatHistoryDoc.set({
          'title': title,
          'conversation': [], // Initialize with an empty conversation array
          'timestamp': FieldValue.serverTimestamp(), // Set timestamp
        });
        print('Conversation $conversationId created with title: $title');
        return;
      }

      // Update the title of the existing conversation
      await chatHistoryDoc.update({
        'title': title,
        'timestamp':
            FieldValue.serverTimestamp(), // Update the document timestamp
      });

      print('Title updated for conversation $conversationId: $title');
    } catch (e) {
      print('Error saving title: $e');
    }
  }

  Future<String?> getChatTitle(String conversationId) async {
    try {
      // Get the current user
      User? user = _auth.currentUser;
      if (user == null) {
        print('No user is logged in');
        return null;
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
        return null;
      }

      // Retrieve the title field
      Map<String, dynamic>? data =
          conversationSnapshot.data() as Map<String, dynamic>?;
      String? title = data?['title'] as String?;

      if (title != null && title.isNotEmpty) {
        print('Title retrieved for conversation $conversationId: $title');
        return title;
      } else {
        print('Conversation $conversationId has no title set.');
        return null;
      }
    } catch (e) {
      print('Error retrieving title for conversation $conversationId: $e');
      return null;
    }
  }

  // Get list of conversation IDS from a user
  Future<List<Map<String, dynamic>>> getConversationIds() async {
    try {
      // Get the current user
      User? user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      String uid = user.uid;

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

  // Retrieve the chat history from selected conversation IDs
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
      var doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('chatHistory')
          .doc(conversationId)
          .get();

      if (doc.exists) {
        var conversation = doc['conversation'] as List<dynamic>? ?? [];
        List<Map<String, dynamic>> conversationList = [];

        for (var entry in conversation) {
          var userInput = entry['userMessage'] ?? '';
          var response = entry['botResponse'] ?? '';
          var timestamp = entry['timestamp'] ?? '';

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

        return conversationList;
      } else {
        print('Conversation not found.');
        return [];
      }
    } catch (e) {
      print('Error retrieving chat history: $e');
      return [];
    }
  }

//Create new conversation for the user
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

      // Retrieve the list of existing conversations
      var conversations =
          await getConversationIds(); // Get existing conversations

      // Determine the next available conversation number
      int nextConversationNumber = conversations.length + 1;

      // Create a new title for the conversation (e.g., "Conversation 1", "Conversation 2", etc.)
      String newConversationTitle = 'Conversation $nextConversationNumber';

      // Create a new conversation document with an empty conversation array
      var newConversationRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('chatHistory')
          .add({
        'conversation': [], // Initialize the conversation as an empty list
        'timestamp': FieldValue.serverTimestamp(), // Add a timestamp
        'title': newConversationTitle, // Add the generated title
      });

      print(
          'New conversation created with ID: ${newConversationRef.id} and title: $newConversationTitle');

      // Optionally, you can store this new title in the `conversationMap` or any other structure you use
      // You could also immediately add the conversationId to the list of conversations in your UI.

      return newConversationRef.id; // Return the new conversation ID
    } catch (e) {
      print('Error creating new conversation: $e');
      return null;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/chatbot_summarize.dart';

class ChatSummaryPage extends StatefulWidget {
  const ChatSummaryPage({Key? key}) : super(key: key);

  @override
  _ChatSummaryPageState createState() => _ChatSummaryPageState();
}

class _ChatSummaryPageState extends State<ChatSummaryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatJournalService _chatJournalService = ChatJournalService(
    apiKey: 'AIzaSyDPUKqTPKkyNq1YLouYY4s4aoRAi3ERdS0',
  );

  Stream<QuerySnapshot>? _conversationsStream;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _conversationsStream = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('chatHistory')
            .orderBy('timestamp', descending: true)
            .snapshots();
      });
    }
  }

  Future<void> _showConversationPreview(DocumentSnapshot conversation) async {
    // Extract full conversation details
    List<dynamic> conversationMessages = conversation['conversation'] ?? [];

    // Show bottom sheet with conversation preview
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) =>
          _buildConversationPreviewSheet(conversationMessages, conversation.id),
    );
  }

  Widget _buildConversationPreviewSheet(
      List<dynamic> conversationMessages, String conversationId) {
    // Normalize conversation messages to ensure both user and bot messages are displayed
    List<Map<String, dynamic>> normalizedMessages = [];

    for (var message in conversationMessages) {
      // Handle scenarios where message structure might vary
      if (message is Map) {
        if (message.containsKey('userMessage')) {
          normalizedMessages
              .add({'sender': 'User', 'message': message['userMessage']});
        }

        if (message.containsKey('botResponse')) {
          normalizedMessages
              .add({'sender': 'Bot', 'message': message['botResponse']});
        }
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Conversation Preview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlue,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: normalizedMessages.length,
                  itemBuilder: (context, index) {
                    var message = normalizedMessages[index];
                    bool isUser = message['sender'] == 'User';

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['sender'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isUser ? Colors.blue : Colors.green,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            message['message'] ?? '',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: Icon(Icons.import_contacts),
                  label: Text(
                    'Import to Journal',
                    style: TextStyle(fontSize: 18),
                  ),
                  onPressed: () async {
                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Center(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.lightBlue,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Generating Journal...',
                                  style: TextStyle(
                                    color: Colors.lightBlue,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    try {
                      // Convert to required format for journal service
                      List<Map<String, String>> chatMessages =
                          normalizedMessages.map<Map<String, String>>((entry) {
                        return {
                          'sender': entry['sender'].toString(),
                          'content': (entry['message'] ?? '').toString()
                        };
                      }).toList();

                      // Generate journal entry
                      final journalResult = await _chatJournalService
                          .convertChatToJournal(chatMessages);

                      // Close loading dialog
                      Navigator.of(context, rootNavigator: true).pop();

                      // Close bottom sheet
                      Navigator.pop(context);

                      // Return to previous page with journal result
                      Navigator.pop(context, journalResult);
                    } catch (e) {
                      // Close loading dialog
                      Navigator.of(context, rootNavigator: true).pop();

                      // Show error snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to generate journal: $e'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Conversation History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _conversationsStream,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.lightBlue,
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 100,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No conversations found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // Conversation list
          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var conversation = snapshot.data!.docs[index];

              // Extract first message for title
              String firstMessage = '';
              if (conversation['conversation'] is List &&
                  (conversation['conversation'] as List).isNotEmpty) {
                firstMessage =
                    (conversation['conversation'][0]['userMessage'] ?? '')
                        .toString()
                        .trim();
                if (firstMessage.length > 50) {
                  firstMessage = firstMessage.substring(0, 50) + '...';
                }
              }

              // Format timestamp
              String formattedDate =
                  _formatTimestamp(conversation['timestamp']);

              return InkWell(
                onTap: () => _showConversationPreview(conversation),
                child: Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    title: Text(
                      firstMessage.isNotEmpty
                          ? firstMessage
                          : 'Conversation ${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Date: $formattedDate',
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: Icon(
                      Icons.preview_rounded,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper method to format timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown date';

    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM d, yyyy').format(dateTime);
  }
}

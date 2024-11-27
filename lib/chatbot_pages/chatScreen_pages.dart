import 'package:flutter/material.dart';
import 'package:flutter_fyp/chatbot_pages/chat_history.dart';
import 'chatbot_api.dart';
import 'chat_typingIndicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool isLoading = false;
  final ChatHistory _chatHistory = ChatHistory();
  List<String> conversationList = [];
  String? currentConversationId; // Track the current active conversation

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  // Fetch the conversations and auto load the first one or create a new conversation
  Future<void> _fetchConversations({bool refresh = false}) async {
    try {
      final conversations = await _chatHistory.getConversationIds();

      final conversationIds = conversations
          .map((conversation) => conversation['conversationId'] as String)
          .toList();

      setState(() {
        if (refresh) {
          // If it's a refresh, reset the conversation list completely
          conversationList.clear();
        }

        conversationList
            .addAll(conversationIds); // Add the fetched conversations

        // Automatically select the first conversation or create a new one if none exist
        if (conversationList.isNotEmpty && currentConversationId == null) {
          currentConversationId = conversationList.first;
          _loadConversation(currentConversationId!);
        }
      });
    } catch (e) {
      print("Error fetching conversations: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0.0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Move the selected conversation to the top

  // Send the message and get the bot's response
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isNotEmpty && currentConversationId != null) {
      setState(() {
        _messages.add({'sender': 'user', 'text': messageText});
        isLoading = true;
      });
      _messageController.clear();
      _scrollToBottom();

      // Send the user's message to the chatbot API and get the response
      final botResponse = await ChatBotApi.sendMessage(messageText);

      setState(() {
        _messages.add({'sender': 'bot', 'text': botResponse});
        isLoading = false;
      });

      // Save the chat pair to the current conversation
      await _chatHistory.saveChatPair(
          currentConversationId!, messageText, botResponse);

      _scrollToBottom();
      _fetchConversations(refresh: true);
    } else if (currentConversationId == null) {
      print('No active conversation selected.');
    }
  }

  // Load the chat history for the selected conversation
  Future<void> _loadConversation(String conversationId) async {
    setState(() {
      _messages.clear();
      isLoading = true;
      currentConversationId =
          conversationId; // Update the current conversation ID
    });

    try {
      final history = await _chatHistory.getChatHistory(conversationId);
      setState(() {
        if (history.isNotEmpty) {
          _messages.addAll(history.map((entry) {
            return {
              'sender': entry['sender']?.toString() ?? '',
              'text': entry['text']?.toString() ?? '',
              'timestamp': entry['timestamp']?.toString() ?? '',
            };
          }).toList());
        }
        isLoading = false;
      });
    } catch (e) {
      print('Error loading conversation: $e');
      setState(() {
        isLoading = false;
      });
    }
    _scrollToBottom();
  }

  // Start a new conversation and set it as the active one
  Future<void> _startNewConversation() async {
    try {
      final newConversationId = await _chatHistory.createNewConversation();
      if (newConversationId != null) {
        setState(() {
          conversationList.add(newConversationId);
          currentConversationId =
              newConversationId; // Set new conversation as active
        });
        _loadConversation(newConversationId); // Load the new conversation
      }
    } catch (e) {
      print('Error starting a new conversation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ChatBot"),
      ),
      drawer: StatefulBuilder(
        builder: (context, setState) {
          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Text(
                    'Conversations',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                // Loop through conversations and make the selected one unclickable
                for (var i = 0; i < conversationList.length; i++)
                  ListTile(
                    title: Text('Conversation ${i + 1}'),
                    onTap: currentConversationId == conversationList[i]
                        ? null // Disable the current conversation
                        : () {
                            Navigator.pop(context); // Close the drawer
                            _loadConversation(conversationList[
                                i]); // Load selected conversation
                          },
                    tileColor: currentConversationId == conversationList[i]
                        ? Colors.grey[300] // Highlight the active conversation
                        : null,
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Start New Conversation'),
                  onTap: () async {
                    await _startNewConversation();
                    setState(() {}); // Trigger the drawer update
                    Navigator.pop(context); // Close the drawer
                  },
                ),
              ],
            ),
          );
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (isLoading && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          TypingIndicator(),
                        ],
                      ),
                    ),
                  );
                }
                final message = _messages[index];
                final isUserMessage = message['sender'] == 'user';

                double maxWidth = MediaQuery.of(context).size.width * 0.6;

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Align(
                    key: ValueKey<String>(message['text'] ?? ''),
                    alignment: isUserMessage
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      decoration: BoxDecoration(
                        color:
                            isUserMessage ? Colors.blue[100] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Text(
                        message['text'] ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

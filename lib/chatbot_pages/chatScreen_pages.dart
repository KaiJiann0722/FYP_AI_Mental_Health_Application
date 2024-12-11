import 'package:flutter/material.dart';
import 'package:flutter_fyp/chatbot_pages/chatHistoryNavScreen_pages';
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
  bool _isLoadingConversations = true;
  bool isLoading = false;
  final ChatHistory _chatHistory = ChatHistory();
  List<String> conversationList = [];
  List<String> conversationTitles = [];
  // Initialize a map to store conversation ids and titles
  Map<String, String> conversationMap = {};
  String? currentConversationId; // Track the current active conversation
  String currentConversationHistory = '';

  @override
  void initState() {
    super.initState();
    fetchConversations();
  }

  // Fetch the conversations and auto load the first one or create a new conversation
  Future<void> fetchConversations({bool refresh = false}) async {
    try {
      setState(() {
        _isLoadingConversations = true;
      });

      if (refresh) {
        conversationMap.clear();
        conversationList.clear();
        conversationTitles.clear();
      }

      // Fetch the list of conversation IDs
      final conversations = await _chatHistory.getConversationIds();
      print('Conversations fetched: $conversations');

      if (conversations.isEmpty) {
        // If no conversations exist, create a new one
        await _startNewConversation();
      }

      // Loop through each conversationId and fetch its title
      for (int i = 0; i < conversations.length; i++) {
        final conversationId = conversations[i]['conversationId'];

        // Fetch the title for the conversation
        String? title = await _chatHistory.getChatTitle(conversationId);

        // If no title is found, use the default "Conversation X"
        if (title == null || title.isEmpty) {
          title = "Conversation ${i + 1}";

          // Save the default title to Firestore using your saveChatTitle method
          await _chatHistory.saveChatTitle(conversationId, title);
        }

        // Add the conversation ID and its title to the map
        conversationMap[conversationId] = title;

        print('Conversation $i: ID = $conversationId, Title = $title');
      }

      if (mounted) {
        setState(() {
          // Store the conversation IDs and titles in the map
          conversationList = conversationMap.keys.toList();
          conversationTitles = conversationMap.values.toList();

          // Select the next conversation if there are any
          if (conversationList.isNotEmpty) {
            if (currentConversationId == null) {
              currentConversationId = conversationList
                  .first; // Load the first conversation if it's the first time
              _loadConversation(currentConversationId!);
            } else {
              // If a conversation is deleted, select the next one
              if (!conversationList.contains(currentConversationId)) {
                currentConversationId =
                    conversationList.isNotEmpty ? conversationList.first : null;
                if (currentConversationId != null) {
                  _loadConversation(currentConversationId!);
                }
              }
            }
          }

          _isLoadingConversations = false;
        });
      }
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
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'user', 'text': messageText});
          isLoading = true;
        });
      }

      // Clear the message input field and scroll to the bottom
      _messageController.clear();
      _scrollToBottom();

      try {
        // Retrieve the conversation history from Firestore
        List<Map<String, dynamic>> conversationHistory =
            await _chatHistory.getChatHistory(currentConversationId!);

        // Check if conversationHistory is empty or not before formatting
        String formattedHistory =
            formatConversationHistory(conversationHistory);

        print("Sending conversation history: $formattedHistory");

        // Send the user's message to the chatbot API and get the response
        final botResponse = await ChatBotApi.sendMessage(messageText,
            conversationHistory: formattedHistory);

        // Extract the bot response from model's response
        String response =
            botResponse['response'] ?? 'Error: No response from chatbot';
        String updatedConversationHistory =
            botResponse['conversation_history'] ?? formattedHistory;

        print("Bot Response: $response");

        if (mounted) {
          setState(() {
            _messages.add({'sender': 'bot', 'text': response});
            isLoading = false;
          });
        }

        // Save the chat pair to the current conversation
        await _chatHistory.saveChatPair(
            currentConversationId!, messageText, response);

        // Update the conversation history with the new conversation
        currentConversationHistory = updatedConversationHistory;

        _scrollToBottom();
        //fetchConversations(refresh: true);
      } catch (e) {
        print('Error during sending message: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else if (currentConversationId == null) {
      print('No active conversation selected.');
    }
  }

//Format conversation history format to feed to model
  String formatConversationHistory(
      List<Map<String, dynamic>> conversationHistory) {
    if (conversationHistory.isEmpty) return '';

    StringBuffer formattedHistory = StringBuffer();

    // Iterate through messages and format them
    for (var entry in conversationHistory) {
      if (entry['sender'] == 'user') {
        formattedHistory.write('User: ${entry['text']}\n');
      } else if (entry['sender'] == 'bot') {
        formattedHistory.write('Chatbot: ${entry['text']}\n');
      }
    }

    return formattedHistory.toString();
  }

  // Load the chat history for the selected conversation
  Future<void> _loadConversation(String conversationId) async {
    ChatBotApi.resetBackendHistory();

    if (mounted) {
      setState(() {
        _messages.clear();
        isLoading = true;
        currentConversationId = conversationId;
      });
    }

    try {
      final history = await _chatHistory.getChatHistory(conversationId);

      print("Chat history for conversation ID $conversationId: $history");

      if (mounted) {
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
      }
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
        // Add the new conversation ID and title to the conversationMap
        setState(() {
          // Add new conversation ID and default title to the conversationMap
          final newTitle =
              "Conversation ${conversationMap.length + 1}"; // Incremental title based on existing conversation count
          conversationMap[newConversationId] = newTitle;

          // Add the new conversation ID to the conversationList
          conversationList.add(newConversationId);
          currentConversationId =
              newConversationId; // Set the new conversation as the current one
        });

        // Load the new conversation after adding it
        _loadConversation(newConversationId);
      }
    } catch (e) {
      print('Error starting a new conversation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConversations) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("ChatBot"),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading Conversations..."),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("ChatBot"),
      ),
      drawer: ConversationDrawer(
        conversationMap: conversationMap,
        currentConversationId: currentConversationId,
        onSelectConversation: (selectedConversation) {
          print('Selected conversation ID: $selectedConversation');
          _loadConversation(
              selectedConversation); // Call the method to load conversation
          setState(() {}); // Trigger state update
        },
        onStartNewConversation: () async {
          await _startNewConversation();
          setState(() {}); // Trigger state update
        },
        fetchConversations: fetchConversations,
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

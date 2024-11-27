import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import '../models/journal_model.dart';
import 'utils.dart';
import '../services/emotion_service.dart';
import '../models/emotion.dart';
import 'emotion_analysis.dart';

class CreateJournal extends StatefulWidget {
  @override
  _CreateJournalState createState() => _CreateJournalState();
}

class _CreateJournalState extends State<CreateJournal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _entryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService();
  final EmotionService _emotionService = EmotionService();

  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  XFile? _image;

  int _currentStep = 0; // Track the current step
  final steps = ['Journal', 'Emotion', 'Music']; // Define the steps

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _timeController.text = DateFormat('HH:mm').format(DateTime.now());
    _initSpeech();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _entryController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _entryController.text += _lastWords;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? selectedImage = await _picker.pickImage(source: source);
    if (selectedImage != null) {
      setState(() {
        _image = selectedImage;
      });
    }
  }

  Future<void> _addJournalToFirebase() async {
    if (_titleController.text.isEmpty || _entryController.text.isEmpty) {
      _showErrorDialog('Please enter a title and journal entry.');
      return;
    }

    String? base64Image;
    if (_image != null) {
      final bytes = await File(_image!.path).readAsBytes();
      base64Image = base64Encode(bytes);
    }

    // Parse date and time from controllers
    DateTime date = DateFormat('yyyy-MM-dd').parse(_dateController.text);
    TimeOfDay time = TimeOfDay(
      hour: int.parse(_timeController.text.split(":")[0]),
      minute: int.parse(_timeController.text.split(":")[1]),
    );

    // Combine date and time into a single DateTime object
    DateTime dateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    // Get the current user's ID
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      _showErrorDialog('User not logged in.');
      return;
    }

    Journal journal = Journal(
      title: _titleController.text,
      content: _entryController.text,
      entryDate: Timestamp.fromDate(dateTime), // Use Timestamp for entryDate
      imageUrl: base64Image, // Store the base64 string in the imageUrl field
      userId: userId,
      emotions: null,
      sentiment: null,
    );

    try {
      // Analyze emotions and sentiment
      final analysisResult =
          await _emotionService.analyzeEmotions(_entryController.text);
      final List<Emotion> emotions = analysisResult['emotions'];
      final Sentiment sentiment = analysisResult['sentiment'];

      // Update journal with emotions and sentiment
      journal = Journal(
        title: journal.title,
        content: journal.content,
        entryDate: journal.entryDate,
        imageUrl: journal.imageUrl,
        userId: journal.userId,
        emotions: emotions,
        sentiment: sentiment,
      );

      // Save journal entry with emotions and sentiment
      await _databaseService.addJournal(journal);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmotionAnalysis(
              emotions: emotions,
              sentiment: sentiment,
            ),
          ),
        );
        _clearTextFields();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to predict emotions and sentiment: $e')),
      );
    }
  }

  void _clearTextFields() {
    _titleController.clear();
    _entryController.clear();
    _dateController.clear();
    _timeController.clear();
    _image = null;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Journal'),
        backgroundColor: Colors.grey[100],
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressStepper(
                currentStep: _currentStep,
                steps: steps), // Add the progress stepper
            const SizedBox(height: 24),
            const Text(
              'Journal Title',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Enter Journal Title',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Entry Date and Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _timeController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Journal Entry',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  TextField(
                    controller: _entryController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: 'Enter your journal entry here...',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_camera_outlined,
                                color: Colors.grey),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.mic_none_rounded,
                                color: Colors.grey),
                            onPressed: _speechToText.isNotListening
                                ? _startListening
                                : _stopListening,
                          ),
                          IconButton(
                            icon: const Icon(Icons.file_upload_outlined,
                                color: Colors.grey),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Media Attachment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: _image == null ? 50 : 250,
                    width: double.infinity,
                    child: _image == null
                        ? Center(child: Text('No image selected.'))
                        : Image.file(File(_image!.path), fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera, color: Colors.white),
                        label: const Text('Camera',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Background color
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library,
                            color: Colors.white),
                        label: const Text('Gallery',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Background color
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, // Make the button take the full width
              child: ElevatedButton(
                onPressed: _addJournalToFirebase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Predict Emotions and Sentiment',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

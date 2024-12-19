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
import '../services/ocr_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'chatbot_summarize.dart';

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
  final String apiKey = "AIzaSyDjZcFk2PqsoBrD7m_3FrFv_ElrstXwpVY";

  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  XFile? _image;

  bool _isListening = false;
  String _microphoneStatus = 'Tap to start recording';

  late final OCRService _ocrService;

  final int _currentStep = 0; // Track the current step
  final steps = ['Journal', 'Emotion', 'Music']; // Define the steps

  @override
  void initState() {
    super.initState();
    _ocrService =
        OCRService(apiKey: apiKey); // Initialize OCRService with apiKey
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _timeController.text = DateFormat('HH:mm').format(DateTime.now());
    _initSpeech();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      // Request microphone permission
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Microphone permission denied')),
        );
        return;
      }

      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          setState(() {
            _isListening = false;
            _microphoneStatus = 'Speech recognition error';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Speech recognition error: ${error.errorMsg}')),
          );
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
        },
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize speech: $e')),
      );
    }
  }

  void _startListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) return;
    }

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: Duration(minutes: 2), // Increased listening time
        pauseFor: Duration(seconds: 10), // Increased pause duration
        localeId: 'en_GB',
        partialResults: true, // Display partial results
      );
      setState(() {
        _isListening = true;
        _microphoneStatus = 'Listening...';
        _lastWords = ''; // Reset last words
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting speech recognition: $e')),
      );
    }
  }

  void _stopListening() async {
    try {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
        _microphoneStatus = 'Tap to start recording';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping speech recognition: $e')),
      );
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      // Only update if we have a non-empty result
      if (result.recognizedWords.isNotEmpty) {
        // Append with a space if the current text is not empty
        _lastWords = result.recognizedWords;
        _entryController.text +=
            (_entryController.text.isNotEmpty ? ' ' : '') + _lastWords;

        // If the result is final, stop listening
        if (result.finalResult) {
          _stopListening();
        }
      }
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

  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  Future<void> _processImageWithOCR(File imageFile) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Uploading image...'),
              ],
            ),
          );
        },
      );

      // Upload image to Firebase Storage
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('ocr_images')
          .child('$fileName.jpg');

      await storageRef.putFile(imageFile);
      final String imageUrl = await storageRef.getDownloadURL();

      Navigator.pop(context); // Close upload dialog

      // Show processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing image...'),
              ],
            ),
          );
        },
      );

      // Perform OCR using the image URL
      final ocrText = await _ocrService.performOCR(imageUrl);
      Navigator.pop(context); // Close processing dialog

      // Show preview dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('OCR Result'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image preview with network image
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ocrText,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Use Text'),
              ),
            ],
          );
        },
      );

      if (result == true) {
        setState(() {
          _entryController.text = ocrText;
        });
      }

      // Clean up - delete uploaded image
      await storageRef.delete();
    } catch (e) {
      Navigator.of(context).pop(); // Close any open dialogs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    }
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        await _processImageWithOCR(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
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
      content: _entryController.text.trim(),
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Create Journals',
              style: TextStyle(
                  fontSize: 23,
                  fontWeight:
                      FontWeight.bold), // Use white color for AppBar title
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.import_contacts,
                  ), // Use white color for AppBar icons
                  onPressed: () async {
                    // Use async to await the result
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatSummaryPage(),
                      ),
                    );

                    // Check if a result was returned
                    if (result != null) {
                      // Update the title and entry controllers
                      _titleController.text = result['title'];
                      _entryController.text = result['content'];
                    }
                  },
                )
              ],
            ),
          ],
        ),
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
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            _dateController.text =
                                DateFormat('yyyy-MM-dd').format(pickedDate);
                          }
                        },
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
                        onTap: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            _timeController.text = pickedTime.format(context);
                          }
                        },
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
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none_rounded,
                              color: _isListening ? Colors.red : Colors.grey,
                            ),
                            onPressed:
                                _isListening ? _stopListening : _startListening,
                            tooltip:
                                _microphoneStatus, // Add a tooltip for additional context
                          ),
                          // Update IconButtons
                          IconButton(
                            icon: const Icon(Icons.file_upload_outlined,
                                color: Colors.grey),
                            onPressed: () =>
                                _pickAndProcessImage(ImageSource.gallery),
                          ),
                          IconButton(
                            icon: const Icon(Icons.photo_camera_outlined,
                                color: Colors.grey),
                            onPressed: () =>
                                _pickAndProcessImage(ImageSource.camera),
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
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _image == null
                            ? Center(child: Text('No image selected.'))
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_image!.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                        if (_image != null)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: _removeImage,
                            ),
                          ),
                      ],
                    ),
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

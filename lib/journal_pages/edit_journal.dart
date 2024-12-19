import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../models/journal_model.dart';
import '../services/emotion_service.dart';
import '../services/ocr_service.dart';
import 'emotion_analysis.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class EditJournalPage extends StatefulWidget {
  final String journalId;

  EditJournalPage({required this.journalId});

  @override
  _EditJournalPageState createState() => _EditJournalPageState();
}

class _EditJournalPageState extends State<EditJournalPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final String apiKey = "AIzaSyDjZcFk2PqsoBrD7m_3FrFv_ElrstXwpVY";
  final EmotionService _emotionService = EmotionService();
  late final OCRService _ocrService;
  final DatabaseService _databaseService = DatabaseService();

  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  XFile? _image;
  String? _existingImageUrl;

  bool _isListening = false;
  String _microphoneStatus = 'Tap to start recording';

  @override
  void initState() {
    super.initState();
    _ocrService =
        OCRService(apiKey: apiKey); // Initialize OCRService with apiKey
    _loadJournal();
    _initSpeech();
  }

  Future<void> _loadJournal() async {
    Journal? journal = await _databaseService.getJournalById(widget.journalId);
    if (journal != null) {
      setState(() {
        _titleController.text = journal.title;
        _contentController.text = journal.content;
        _dateController.text =
            DateFormat('yyyy-MM-dd').format(journal.entryDate.toDate());
        _timeController.text =
            DateFormat('HH:mm').format(journal.entryDate.toDate());
        _existingImageUrl = journal.imageUrl;
      });
    }
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
        _contentController.text +=
            (_contentController.text.isNotEmpty ? ' ' : '') + _lastWords;

        // If the result is final, stop listening
        if (result.finalResult) {
          _stopListening();
        }
      }
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
          _contentController.text = ocrText;
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

  Widget _buildImagePreview() {
    if (_image != null) {
      return Image.file(File(_image!.path), fit: BoxFit.cover);
    } else if (_existingImageUrl != null) {
      try {
        return Image.memory(base64Decode(_existingImageUrl!),
            fit: BoxFit.cover);
      } catch (e) {
        return Center(child: Text('Invalid image data'));
      }
    }
    return Center(child: Text('No image'));
  }

  Future<void> _updateJournal() async {
    try {
      if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }

      DateTime date = DateFormat('yyyy-MM-dd').parse(_dateController.text);
      TimeOfDay time = TimeOfDay(
        hour: int.parse(_timeController.text.split(":")[0]),
        minute: int.parse(_timeController.text.split(":")[1]),
      );
      DateTime dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      String? imageBase64;
      if (_image != null) {
        final bytes = await File(_image!.path).readAsBytes();
        imageBase64 = base64Encode(bytes);
      } else {
        imageBase64 = _existingImageUrl;
      }

      // Analyze emotions and sentiment
      final analysisResult =
          await _emotionService.analyzeEmotions(_contentController.text);

      Journal updatedJournal = Journal(
        title: _titleController.text,
        content: _contentController.text,
        entryDate: Timestamp.fromDate(dateTime),
        imageUrl: imageBase64,
        userId: FirebaseAuth.instance.currentUser!.uid,
        emotions: analysisResult['emotions'],
        sentiment: analysisResult['sentiment'],
      );

      await _databaseService.updateJournal(widget.journalId, updatedJournal);

      if (mounted) {
        // Use pushReplacement instead of pop and push
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmotionAnalysis(
              emotions: analysisResult['emotions'],
              sentiment: analysisResult['sentiment'],
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating journal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Journal'),
        backgroundColor: Colors.grey[100],
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Journal Title',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            SizedBox(height: 8),
            _buildInputContainer(
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter Journal Title',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.edit_note, color: Colors.grey),
                ),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(height: 24),
            Text('Entry Date and Time',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            SizedBox(height: 8),
            _buildInputContainer(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (date != null) {
                          _dateController.text =
                              DateFormat('yyyy-MM-dd').format(date);
                        }
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon:
                            Icon(Icons.calendar_today, color: Colors.grey),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _timeController,
                      readOnly: true,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          _timeController.text = time.format(context);
                        }
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.access_time, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text('Journal Entry',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            SizedBox(height: 8),
            _buildInputContainer(
              child: Column(
                children: [
                  TextField(
                    controller: _contentController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Enter your journal entry here...',
                      border: InputBorder.none,
                    ),
                    style: TextStyle(fontSize: 16),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
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
                      IconButton(
                        icon: Icon(Icons.file_upload_outlined,
                            color: Colors.grey),
                        onPressed: () =>
                            _pickAndProcessImage(ImageSource.gallery),
                      ),
                      IconButton(
                        icon: Icon(Icons.photo_camera_outlined,
                            color: Colors.grey),
                        onPressed: () =>
                            _pickAndProcessImage(ImageSource.camera),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text('Media Attachment',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            SizedBox(height: 8),
            _buildInputContainer(
              child: Column(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildImagePreview(),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.camera);
                          if (image != null) {
                            setState(() => _image = image);
                          }
                        },
                        icon: Icon(Icons.camera_alt, color: Colors.white),
                        label: Text('Camera',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (image != null) {
                            setState(() => _image = image);
                          }
                        },
                        icon: Icon(Icons.photo_library, color: Colors.white),
                        label: Text('Gallery',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateJournal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: Text('Update Journal',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import '../services/groq_api_service.dart'; // Ensure you import the GroqApiService
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class JournalSummarizer extends StatefulWidget {
  @override
  _JournalSummarizerState createState() => _JournalSummarizerState();
}

class _JournalSummarizerState extends State<JournalSummarizer> {
  String? _summary;
  bool _isLoading = false;
  List<Map<String, dynamic>> _journalEntries = [];
  DateTime? _startDate;
  DateTime? _endDate;
  Timer? _timer;
  int _index = 0;
  String _displayedSummary = '';

  // Groq API service
  final _groqApiService = GroqApiService(
      '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');

  Future<void> _summarizeJournal() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _summary = null;
      _displayedSummary = '';
      _journalEntries = [];
    });

    try {
      final journalEntries = await _fetchJournalEntries();

      if (journalEntries.isEmpty) {
        setState(() {
          _summary = 'No journal entries found for the selected date range.';
        });
        return;
      }

      setState(() {
        _journalEntries = journalEntries;
      });

      final formattedJournalText = journalEntries.map((entry) {
        final date = entry['entryDate'] != null
            ? (entry['entryDate'] as DateTime).toLocal()
            : DateTime.now();

        final formattedDate =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        return '''Date: $formattedDate
Journal Entry:
${entry['content']}''';
      }).join('\n\n---\n\n');

      String summary =
          await _groqApiService.summarizeJournalEntry(formattedJournalText);

      // Define the regex pattern
      final pattern = RegExp(r'\*{1,2}(.*?)\*{1,2}');

      // Replace the matched patterns with the inner text
      summary =
          summary.replaceAllMapped(pattern, (match) => match.group(1) ?? '');

      setState(() {
        _summary = summary;
        _index = 0;
        _displayedSummary = '';
      });

      _startDisplayingSummary();
    } catch (e) {
      setState(() {
        _summary = 'Error summarizing journal: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startDisplayingSummary() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: 15), (timer) {
      if (_index < _summary!.length) {
        setState(() {
          _displayedSummary = _summary!.substring(0, _index) + '|';
          _index++;
        });
      } else {
        setState(() {
          _displayedSummary = _summary!;
        });
        _timer?.cancel();
      }
    });
  }

  Future<List<Map<String, dynamic>>> _fetchJournalEntries() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    Query query = FirebaseFirestore.instance
        .collection('journal')
        .where('userId', isEqualTo: user.uid)
        .where('entryDate', isGreaterThanOrEqualTo: _startDate)
        .where('entryDate', isLessThanOrEqualTo: _endDate)
        .orderBy('entryDate');

    final querySnapshot = await query.get();
    print('Fetched ${querySnapshot.docs.length} journal entries');
    return querySnapshot.docs
        .map((doc) => {
              'content': doc['content'] as String,
              'entryDate': (doc['entryDate'] as Timestamp).toDate(),
            })
        .toList();
  }

  void _showOriginalEntries() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Original Journal Entries',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: _journalEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _journalEntries[index];
                    return ListTile(
                      title: Text(
                        DateFormat('MMM d, yyyy').format(entry['entryDate']),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        entry['content'],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _showFullEntry(entry),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullEntry(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('MMM d, yyyy').format(entry['entryDate'])),
        content: SingleChildScrollView(
          child: Text(entry['content']),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.lightBlue,
            colorScheme: ColorScheme.light(
              primary: Colors.lightBlue,
              onPrimary: Colors.white, // Set the line color to white
            ),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal Insights',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date Range Selector
                  Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: _selectDateRange,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, color: Colors.black),
                          SizedBox(width: 10),
                          Text(
                            _startDate == null || _endDate == null
                                ? 'Select Date Range'
                                : '${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Summarize Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _summarizeJournal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator()
                        : Text(
                            'Generate Summary',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  SizedBox(height: 20),

                  // Summary Display
                  Expanded(
                    child: _summary == null
                        ? _buildEmptyState()
                        : _buildSummaryCard(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 100,
          ),
          SizedBox(height: 20),
          Text(
            'Your journal insights will appear here',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Select a date range and generate a summary',
            style: TextStyle(
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return GestureDetector(
      onTap: _journalEntries.isNotEmpty ? _showOriginalEntries : null,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Journal Insights',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      if (_journalEntries.isNotEmpty)
                        Icon(
                          Icons.remove_red_eye,
                          color: Colors.black,
                        ),
                      SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.copy, color: Colors.black),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _displayedSummary));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Summary copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        tooltip: 'Copy Summary',
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                _displayedSummary,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              if (_journalEntries.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Tap to view original entries',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

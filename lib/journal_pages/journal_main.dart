import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_journal.dart';
import 'utils.dart';
import '../models/emotion.dart';
import '../models/journal_model.dart' as journal;
import 'journal_details.dart';
import 'search_journal.dart';
import 'journal_summarize.dart';
import 'journal_notification.dart';

class JournalMainPage extends StatefulWidget {
  const JournalMainPage({super.key});

  @override
  _JournalMainPageState createState() => _JournalMainPageState();
}

class _JournalMainPageState extends State<JournalMainPage> {
  User? get user => FirebaseAuth.instance.currentUser;
  DateTime selectedDate = DateTime.now();
  String _sortOrder = 'Newest';
  final ValueNotifier<Map<String, Size>> _cardSizeNotifier =
      ValueNotifier<Map<String, Size>>({});
  final journal.DatabaseService _journalDatabaseService =
      journal.DatabaseService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    List<String> daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<DateTime> weekDates = List.generate(7, (index) {
      return now.subtract(Duration(days: now.weekday - 1 - index));
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Journals',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown[900], // Use white color for AppBar text
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications,
                      color: Colors
                          .brown[900]), // Use white color for AppBar icons
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JournalNotificationPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.summarize,
                      color: Colors
                          .brown[900]), // Use white color for AppBar icons
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JournalSummarizer(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.search,
                      color: Colors
                          .brown[900]), // Use white color for AppBar icons
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Selector
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white, // Set the background color to white
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    bool isSelected =
                        weekDates[index].day == selectedDate.day &&
                            weekDates[index].month == selectedDate.month &&
                            weekDates[index].year == selectedDate.year;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDate = weekDates[index];
                        });
                      },
                      child: Container(
                        width: 50,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue
                              : Colors
                                  .transparent, // Set selected background color to blue
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              daysOfWeek[index],
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.brown[
                                        900], // Change text color based on selection
                              ),
                            ),
                            Text(
                              DateFormat('d').format(weekDates[index]),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.brown[
                                        900], // Change text color based on selection
                              ),
                            ),
                            if (isSelected)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Timeline Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[900],
                    ),
                  ),
                  DropdownButton<String>(
                    value: _sortOrder,
                    items: <String>['Newest', 'Oldest'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                                value == 'Newest'
                                    ? Icons.sort
                                    : Icons.sort_by_alpha,
                                color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              value,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _sortOrder = newValue!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot<journal.Journal>>(
                  stream: _journalDatabaseService.getJournalsByDateAndUser(
                      selectedDate, user!.uid, _sortOrder),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No journal entries found'));
                    } else {
                      return ListView(
                        children: snapshot.data!.docs.map((doc) {
                          String entryId = doc.id;
                          String title = doc['title'];
                          String content = doc['content'];
                          DateTime entryDate =
                              (doc['entryDate'] as Timestamp).toDate();
                          String sentimentLabel = doc['sentiment']['label'] ??
                              'Unknown'; // Assuming sentiment is stored as a map with a 'label' key

                          // Retrieve emotions and sentiment directly from the journal document
                          List<dynamic> emotionsJson = doc['emotions'];

                          List<Emotion> emotions = emotionsJson
                              .map((e) =>
                                  Emotion.fromJson(e as Map<String, dynamic>))
                              .toList();
                          // Get the highest probability emotion
                          Emotion? highestEmotion =
                              emotions.isNotEmpty ? emotions.first : null;
                          String emoji = highestEmotion != null
                              ? emotionToEmoji[highestEmotion.emotion] ?? ''
                              : '';
                          String emotionName = highestEmotion != null
                              ? highestEmotion.emotion
                              : '';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      JournalDetailsPage(journalId: entryId),
                                ),
                              );
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        DateFormat('HH:mm').format(entryDate),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    ValueListenableBuilder<Map<String, Size>>(
                                      valueListenable: _cardSizeNotifier,
                                      builder: (context, sizeMap, child) {
                                        Size size =
                                            sizeMap[entryId] ?? Size.zero;
                                        return Container(
                                          width: 2,
                                          height: size.height + 15.5,
                                          color: Colors.blue,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        bottom:
                                            20.0), // Add padding between entries
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Container(
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.1),
                                                spreadRadius: 1,
                                                blurRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: MeasureSize(
                                            onChange: (size) {
                                              _cardSizeNotifier.value = {
                                                ..._cardSizeNotifier.value,
                                                entryId: size,
                                              };
                                            },
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      emoji,
                                                      style: TextStyle(
                                                          fontSize: 20),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        title,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      emotionName,
                                                      style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  content,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Sentiment: ${sentimentLabel}',
                                                  style: TextStyle(
                                                    color: getSentimentColor(
                                                        sentimentLabel),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateJournal()),
          );
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

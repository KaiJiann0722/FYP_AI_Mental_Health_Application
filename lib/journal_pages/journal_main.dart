import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_fyp/userAuth_pages/auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_journal.dart';
import 'utils.dart';

class JournalMainPage extends StatefulWidget {
  const JournalMainPage({super.key});

  @override
  _JournalMainPageState createState() => _JournalMainPageState();
}

class _JournalMainPageState extends State<JournalMainPage> {
  User? user;
  bool _isSearchBarVisible = false;
  final CollectionReference journalCollection =
      FirebaseFirestore.instance.collection('journal');
  DateTime selectedDate = DateTime.now();
  String _sortOrder = 'Newest';
  final ValueNotifier<Map<String, Size>> _cardSizeNotifier =
      ValueNotifier<Map<String, Size>>({});

  @override
  void initState() {
    super.initState();
    // Load the current user on initialization
    _loadUser();
  }

  // Method to load the current user
  Future<void> _loadUser() async {
    final currentUser = Auth().currentUser;
    setState(() {
      user = currentUser;
    });
  }

  // Get start of day
  DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    List<String> daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<DateTime> weekDates = List.generate(7, (index) {
      return now.subtract(Duration(days: now.weekday - 1 - index));
    });

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Calendar Icon and Search Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Journals',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[900],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.calendar_today,
                            color: Colors.brown[900]),
                        onPressed: () {
                          // Handle calendar icon press
                        },
                      ),
                      const SizedBox(width: 8),
                      _isSearchBarVisible
                          ? Container(
                              width: 200,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.grey[600]),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.close,
                                        color: Colors.grey[600]),
                                    onPressed: () {
                                      setState(() {
                                        _isSearchBarVisible = false;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            )
                          : IconButton(
                              icon:
                                  Icon(Icons.search, color: Colors.brown[900]),
                              onPressed: () {
                                setState(() {
                                  _isSearchBarVisible = true;
                                });
                              },
                            ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
              // Journal Entries
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: journalCollection
                      .where('userId', isEqualTo: user?.uid)
                      .where('entryDate',
                          isGreaterThanOrEqualTo:
                              Timestamp.fromDate(getStartOfDay(selectedDate)))
                      .where('entryDate',
                          isLessThan: Timestamp.fromDate(
                              getStartOfDay(selectedDate)
                                  .add(Duration(days: 1))))
                      .orderBy('entryDate', descending: _sortOrder == 'Newest')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No journal entries found.'));
                    }

                    return ListView(
                      children: snapshot.data!.docs.map((doc) {
                        String entryId = doc.id;
                        String title = doc['title'];
                        String content = doc['content'];
                        DateTime entryDate =
                            (doc['entryDate'] as Timestamp).toDate();

                        return Row(
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
                                    Size size = sizeMap[entryId] ?? Size.zero;
                                    return Container(
                                      width: 2,
                                      height: size.height + 18,
                                      color: Colors.blue,
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
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
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
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
                                                Icon(Icons.book,
                                                    color: Colors.green),
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
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              content,
                                              style: TextStyle(
                                                color: Colors.grey[600],
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
                        );
                      }).toList(),
                    );
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

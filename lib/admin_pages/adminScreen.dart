import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_fyp/admin_pages/emotionChart.dart';
import 'package:flutter_fyp/admin_pages/sentimentController.dart';
import 'package:flutter_fyp/admin_pages/sentimentChart.dart';
import 'package:flutter_fyp/admin_pages/userManagementScreen.dart';
import 'package:flutter_fyp/userAuth_pages/auth.dart';
import 'package:flutter_fyp/widget_tree.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final SentimentController _adminController = SentimentController();
  Map<String, Map<String, dynamic>> sentimentOverview = {};

  String firstName = '';
  String lastName = '';
  String email = '';
  String imageUrl = '';
  String gender = '';
  String dob = '';
  String isAdmin = '';
  bool isLoading = true;

  List<String> userNames = [];

  // Variable to store the number of registered users
  int registeredUserCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAdminData(); // Load user data when the screen initializes
    _loadUserNames(); // Fetch user IDs from journals
  }

  Future<void> _loadAdminData() async {
    Map<String, String>? data = await Auth().getUserData();
    if (data != null) {
      setState(() {
        firstName = data['firstName'] ?? '';
        lastName = data['lastName'] ?? '';
        email = data['email'] ?? '';
        imageUrl = data['imageUrl'] ?? '';
        gender = data['gender'] ?? '';
        dob = data['dob'] ?? '';
        isAdmin = data['isAdmin'] ?? '';
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
    if (isAdmin == 'true') {
      _fetchUserCount(); // Fetch user count if admin
    }
  }

  // Fetch user IDs from journals
  Future<void> _loadUserNames() async {
    try {
      // Fetch full names for all users
      List<String> fetchedUserNames =
          await _adminController.fetchUserDetailsForAllJournals();

      setState(() {
        userNames = fetchedUserNames;
        isLoading = false; // Set loading to false once data is fetched
      });
    } catch (e) {
      print('Error loading user details: $e');
    }
  }

  // Fetch the total number of registered users from Firestore
  Future<void> _fetchUserCount() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        registeredUserCount = snapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching user count: $e');
    }
  }

  // Sign out method
  // Future<void> signOut() async {
  //   await Auth().signOut();
  // }
  Future<void> signOut() async {
    await Auth().signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => WidgetTree()),
        (route) => false,
      );
    }
  }

  // Sign out button
  Widget _signOutButton() {
    return SizedBox(
      width: 300,
      child: ElevatedButton(
        onPressed: signOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(
              color: Colors.black,
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.logout,
              color: Colors.black,
            ),
            SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget registeredUserCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Registered Users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$registeredUserCount',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            // Wrap the ElevatedButton inside a SizedBox to take full width
            SizedBox(
              width: double
                  .infinity, // Make the button take up all available width
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserManagementScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Users',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget registeredSentimentAndEmotionCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Sentiment Recorded',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              ' ${userNames.length}',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            // Column to stack the buttons vertically
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double
                      .infinity, // The button takes up the full width of the card
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SentimentChart(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Sentiments',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Space between the buttons
                SizedBox(
                  width: double
                      .infinity, // The button takes up the full width of the card
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmotionChart(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Emotions',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget displayUsername() {
    return Expanded(
      // Wrap the ListView with Expanded to prevent layout issues
      child: ListView.builder(
        itemCount: userNames.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              userNames[index],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isAdmin != 'true') {
      return WidgetTree();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              registeredUserCard(),
              const SizedBox(height: 40),
              registeredSentimentAndEmotionCard(),
              // displayUsername(),
              const SizedBox(height: 40),
              _signOutButton(),
            ],
          ),
        ),
      ),
    );
  }
}

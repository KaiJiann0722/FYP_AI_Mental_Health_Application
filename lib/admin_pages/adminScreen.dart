import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_fyp/profile_pages/profile.dart';
import 'package:flutter_fyp/userAuth_pages/auth.dart';
import 'package:flutter_fyp/userAuth_pages/login.dart';
import 'package:flutter_fyp/widget_tree.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String firstName = '';
  String lastName = '';
  String email = '';
  String imageUrl = '';
  String gender = '';
  String dob = '';
  String isAdmin = '';
  bool isLoading = true; // To track loading state

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load the user data when the screen initializes
  }

  Future<void> _loadUserData() async {
    // Fetch the user data from Auth
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
        isLoading = false; // Set loading to false after data is fetched
      });
      print("Is the user an admin222? $isAdmin");
    } else {
      setState(() {
        isLoading = false; // Handle case where data is not available
      });
    }
  }

  Future<void> signOut() async {
    //await _loadUserData();
    //WidgetTree();
    await Auth().signOut();
    //_loadUserData();
    // WidgetTree();
  }

  Widget _signOutButton() {
    return SizedBox(
      width: 300, // Same width as your other widgets
      child: ElevatedButton(
        onPressed: signOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red, // Button background color
          padding: EdgeInsets.symmetric(
              vertical: 12, horizontal: 16), // Padding for the button
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(8), // Rounded corners for the button
            side: BorderSide(
              color: Colors.black, // Border color
              width: 1, // Border width
              style: BorderStyle.solid, // Solid border style
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Adjust the size based on content
          mainAxisAlignment: MainAxisAlignment.center, // Center icon and text
          children: [
            Icon(
              Icons.logout, // Logout icon
              color: Colors.black, // Icon color
            ),
            SizedBox(width: 8), // Spacing between icon and text
            Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Text color
              ),
            ),
          ],
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Admin!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Manage Users, View Analytics, and more.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Navigate to the user management page
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => UserManagementPage()),
                // );
              },
              child: const Text('Manage Users'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to the analytics page
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => AnalyticsPage()),
                // );
              },
              child: const Text('View Analytics'),
            ),
            _signOutButton(),
          ],
        ),
      ),
    );
  }
}

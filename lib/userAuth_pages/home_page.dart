import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_fyp/userAuth_pages/auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user;

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

  Widget _title() {
    return const Text('Mental Health App');
  }

  Widget _userUID() {
    return Text(user?.email ?? 'User email');
  }

  Widget _showUserIdButton() {
    return ElevatedButton(
      onPressed: () {
        // Print user ID to the console
        print('User ID: ${user?.uid}');
      },
      child: const Text('Show User ID'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _userUID(),
            _showUserIdButton(),
          ],
        ),
      ),
    );
  }
}

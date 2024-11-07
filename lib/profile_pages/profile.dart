import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_fyp/profile_pages/utils.dart';
import 'package:flutter_fyp/userAuth_pages/auth.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, String>? userData;
  Uint8List? image;
  String firstName = '';
  String lastName = '';
  String imageUrl = '';
  String email = '';

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load the user data when the screen initializes
  }

  Future<void> _loadUserData() async {
    Map<String, String>? data = await Auth().getUserData();
    setState(() {
      userData = data;
      if (userData != null) {
        firstName = userData!['firstName'] ?? '';
        lastName = userData!['lastName'] ?? '';
        email = userData!['email'] ?? '';
        imageUrl = userData!['imageUrl'] ?? '';
      }
    });
  }

  Future<void> signOut() async {
    await Auth().signOut();
    // After signing out, load the user state again
    _loadUserData();
  }

  Widget _signOutButton() {
    return ElevatedButton(onPressed: signOut, child: const Text('Sign Out'));
  }

  Widget _title() {
    return const Text(
      'Profile',
      style: TextStyle(fontSize: 30),
    );
  }

  void selectImage() async {
    Uint8List? img = await pickImage(
        ImageSource.gallery); // Using the utility function to pick image
    if (img != null) {
      setState(() {
        image = img;
      });

      // Convert the image data (Uint8List) to base64 string
      String base64Image = base64Encode(image!);

      // Upload the base64-encoded image string to Firebase (or any other service)
      await Auth().uploadImageToDatabase(
          base64Image); // Pass the base64 string directly
    }
  }

  // Custom circular edit button
  Widget imgEditButton(Color color) => GestureDetector(
        onTap: selectImage, // Trigger selectImage function when tapped
        child: buildCircle(
          color: Colors.white,
          all: 4, // Outer padding for the circle
          child: buildCircle(
            color: color,
            all: 10, // Inner padding for the smaller circle (for the edit icon)
            child: Icon(
              Icons.edit,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );

  // Circle builder function
  Widget buildCircle({
    required Widget child,
    required double all,
    required Color color,
  }) =>
      Container(
        padding: EdgeInsets.all(all),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle, // Ensures the container is a circle
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _title(),
      ),
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Container(
          padding:
              const EdgeInsets.only(right: 30, left: 30, top: 0, bottom: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: imageUrl.isEmpty
                        ? AssetImage('assets/profile.png')
                            as ImageProvider // Default profile picture
                        : Image.memory(base64Decode(imageUrl))
                            .image, // Display image from Firebase if available
                    radius: 60,
                    backgroundColor: Colors.black,
                  ),
                  if (image != null)
                    CircleAvatar(
                      backgroundImage: MemoryImage(image!),
                      radius: 60,
                      backgroundColor: Colors.white,
                    ),
                  Positioned(
                      bottom: -3, left: 75, child: imgEditButton(Colors.black))
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '$firstName $lastName', // Concatenate firstName and lastName
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.email, color: Colors.grey), // Email icon
                  const SizedBox(width: 10), // Space between the icon and text
                  Text(
                    email, // Display the user's email
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 10),
              const SizedBox(height: 20),
              const SizedBox(height: 30),
              _signOutButton()
            ],
          ),
        ),
      ),
    );
  }
}

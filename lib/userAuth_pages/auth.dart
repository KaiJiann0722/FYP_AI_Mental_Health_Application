import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<Map<String, String>?> getUserData() async {
    try {
      // Ensure the user is authenticated
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        // If no user is signed in, return null or handle the error as needed
        print('No user is currently signed in');
        return null;
      }

      // Get the current user ID (UID)
      String uid = user.uid;
      print('Fetching data for user with UID: $uid');

      // Fetch user data from Firestore
      DocumentSnapshot snapshot =
          await _firestore.collection('users').doc(uid).get();

      print('Snapshot Data: ${snapshot.data()}');

      if (snapshot.exists) {
        // Extract first name and last name from Firestore document
        var data = snapshot.data() as Map<String, dynamic>;
        String firstName = data['firstName'] ?? '';
        String lastName = data['lastName'] ?? '';
        String email = data['email'] ?? '';
        String imageUrl = data['imageUrl'] ?? '';

        return {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'imageUrl': imageUrl,
        };
      } else {
        print('User data not found for UID: $uid');
        return null;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  Future<void> uploadImageToDatabase(dynamic pickedFile) async {
    try {
      String uid = _firebaseAuth.currentUser!.uid;

      // Check if pickedFile is an XFile or a base64 string
      if (pickedFile is XFile) {
        // Convert XFile (image file) to a base64 string
        File file = File(pickedFile.path);
        List<int> imageBytes = await file.readAsBytes();
        String base64String = base64Encode(imageBytes);

        // Save the base64 string to Firebase Firestore
        await _firestore.collection('users').doc(uid).update({
          'imageUrl':
              base64String, // Store the base64 string in the imageUrl field
        });

        print(
            "Image uploaded successfully and stored as base64 in Firebase Database");
      } else if (pickedFile is String) {
        // Handle the case where pickedFile is already a base64 string
        await _firestore.collection('users').doc(uid).update({
          'imageUrl': pickedFile, // Just store the provided base64 string
        });

        print("Base64 image uploaded successfully in Firebase Database");
      } else {
        print("Invalid image format");
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<String?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      return null; // Return null if sign-in is successful
    } on FirebaseAuthException catch (e) {
      return getErrorMessage(e);
    }
  }

  Future<String?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // Create the user in Firebase Authentication
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the user ID
      String uid = userCredential.user!.uid;

      // Store additional user details in Firestore under a 'users' collection
      await _firestore.collection('users').doc(uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      });

      return null; // Return null if registration is successful
    } on FirebaseAuthException catch (e) {
      return getErrorMessage(
          e); // Return custom error message if there's an error
    } catch (e) {
      // Handle other errors, if any
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<String?> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return null; // Return null if sign-in is successful
    } on FirebaseAuthException catch (e) {
      return getErrorMessage(e);
    }
  }

  String getErrorMessage(FirebaseAuthException e) {
    print(e.code);
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'Email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters long.';
      default:
        return 'An error occurred. Please try again later.';
    }
  }
}

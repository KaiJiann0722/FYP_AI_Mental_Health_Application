import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_fyp/admin_pages/adminScreen.dart';
import 'package:flutter_fyp/chatbot_pages/chatbot_api.dart';
import 'package:flutter_fyp/userAuth_pages/auth.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String? _currentUserId;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _getCurrentUserId();
    _searchController.addListener(_filterUsers);
  }

  // Get the current user ID
  Future<void> _getCurrentUserId() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    } else {
      // Handle case where user is not authenticated
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User is not authenticated.")),
      );
    }
  }

  // Fetch users from Firestore
  Future<void> _fetchUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      setState(() {
        _users = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'firstName': data['firstName'] ?? 'Unknown',
            'lastName': data['lastName'] ?? 'Unknown',
            'email': data['email'] ?? 'No email',
          };
        }).toList();
        _filteredUsers = List.from(_users); // Initially, show all users
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter users based on search query
  void _filterUsers() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        return user['firstName'].toLowerCase().contains(query) ||
            user['lastName'].toLowerCase().contains(query) ||
            user['email'].toLowerCase().contains(query);
      }).toList();
    });
  }

  // Delete user
  Future<void> _deleteUser(String userId) async {
    // Print the userId for debugging purposes
    print("Deleting user with ID: $userId");

    // Confirmation dialog before deleting the user
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete this user? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Delete user from Firestore first
                  await _firestore.collection('users').doc(userId).delete();

                  // Call the deleteUser method from ApiService to delete from backend
                  await ChatBotApi.deleteUser(userId);

                  await _fetchUsers();

                  setState(() {
                    _filteredUsers.removeWhere((user) => user['id'] == userId);
                  });

                  // Check if widget is still mounted before showing SnackBar
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("User deleted successfully")),
                    );
                  }
                  Navigator.of(context).pop();
                } catch (e) {
                  print("Error deleting user: $e");
                  // Check if widget is still mounted before showing SnackBar
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to delete user: $e")),
                    );
                  }
                }
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Send password reset email to the provided email (this could be the admin's email)
  Future<String?> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Return null if successful
    } on FirebaseAuthException catch (e) {
      return getErrorMessage(e); // Return error message if there's an issue
    }
  }

  // Helper function to handle FirebaseAuthException errors
  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  // Your existing method to reset password
  Future<void> _resetPassword(String email) async {
    try {
      // Call the sendPasswordResetEmail method
      final resetResult = await sendPasswordResetEmail(email: email);

      // Check if there's an error
      if (resetResult == null) {
        // Success, no error returned
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password reset link sent to: $email")),
        );
      } else {
        // Error message is returned
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to reset password: $resetResult")),
        );
      }
    } catch (e) {
      print("Error resetting password: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: UserSearchDelegate(_filteredUsers),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _filteredUsers.isEmpty
              ? Center(
                  child: Text(
                  'No registered users found',
                  style: TextStyle(fontSize: 16),
                ))
              : ListView.builder(
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];

                    // Check if this user is the currently logged-in user
                    if (user['id'] == _currentUserId) {
                      return SizedBox.shrink(); // Skip the current user
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(
                          '${user['firstName']} ${user['lastName']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(user['email']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Reset Password Button
                            IconButton(
                              icon: Icon(Icons.lock_reset, color: Colors.blue),
                              onPressed: () {
                                _resetPassword(user['email']);
                              },
                            ),
                            // Delete User Button
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteUser(user['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class UserSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> users;

  UserSearchDelegate(this.users);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildResults(BuildContext context) {
    List<Map<String, dynamic>> results = users
        .where((user) =>
            user['firstName'].toLowerCase().contains(query.toLowerCase()) ||
            user['lastName'].toLowerCase().contains(query.toLowerCase()) ||
            user['email'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text('${user['firstName']} ${user['lastName']}'),
            subtitle: Text(user['email']),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Map<String, dynamic>> suggestions = users
        .where((user) =>
            user['firstName'].toLowerCase().contains(query.toLowerCase()) ||
            user['lastName'].toLowerCase().contains(query.toLowerCase()) ||
            user['email'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final user = suggestions[index];

        return ListTile(
          title: Text('${user['firstName']} ${user['lastName']}'),
          subtitle: Text(user['email']),
        );
      },
    );
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Close the search
      },
    );
  }
}

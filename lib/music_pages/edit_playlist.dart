import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:convert';

import '../models/playlist.dart';

class EditPlaylistPage extends StatefulWidget {
  final Playlist playlist;
  final String playlistId;

  const EditPlaylistPage(
      {Key? key, required this.playlist, required this.playlistId})
      : super(key: key);

  @override
  _EditPlaylistPageState createState() => _EditPlaylistPageState();
}

class _EditPlaylistPageState extends State<EditPlaylistPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _base64Image;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist.name);
    _descriptionController =
        TextEditingController(text: widget.playlist.description);
    _base64Image = widget.playlist.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Convert image to base64
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _savePlaylist() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('playlists')
          .doc(widget.playlistId)
          .update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _base64Image,
      });

      // Navigate back to previous screen
      Navigator.of(context).pop(true);
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving playlist: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Playlist'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _savePlaylist,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _base64Image != null
                      ? Image.memory(
                          base64Decode(_base64Image!),
                          fit: BoxFit.cover,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 50),
                            Text('Add Playlist Image'),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 20),

              // Playlist Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Playlist Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a playlist name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Playlist Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Playlist Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

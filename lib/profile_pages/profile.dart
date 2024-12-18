import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_fyp/admin_pages/adminScreen.dart';
import 'package:flutter_fyp/profile_pages/utils.dart';
import 'package:flutter_fyp/userAuth_pages/auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:intl/intl.dart';

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
  String gender = '';
  String dob = '';
  String isAdmin = '';
  TextEditingController dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load the user data when the screen initializes
    dateController.text = dob;
  }

  Future<void> _loadUserData() async {
    Map<String, String>? data = await Auth().getUserData();
    if (mounted) {
      setState(() {
        userData = data;
        if (userData != null) {
          firstName = userData!['firstName'] ?? '';
          lastName = userData!['lastName'] ?? '';
          email = userData!['email'] ?? '';
          imageUrl = userData!['imageUrl'] ?? '';
          gender = userData!['gender'] ?? '';
          dob = userData!['dob'] ?? '';
          isAdmin = data?['isAdmin'] ?? '';
        }
      });
    }
  }

  Future<void> signOut() async {
    await Auth().signOut();
    // After signing out, load the user state again
    _loadUserData();
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

  Widget _emailDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        // Use IntrinsicWidth to let the container auto size based on content
        IntrinsicWidth(
          child: Container(
            width: 300, // Set a fixed width for the container
            decoration: BoxDecoration(
              color: Colors.grey[200], // Background color
              borderRadius: BorderRadius.circular(8), // Rounded corners
              border: Border.all(color: Colors.grey), // Border color
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12), // Padding for text
            child: Row(
              children: [
                Icon(
                  Icons.email, // Email icon
                  color: Colors.grey, // Icon color
                  size: 20, // Icon size
                ),
                const SizedBox(width: 8), // Space between icon and text
                Expanded(
                  child: Text(
                    email, // Display the email value
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow
                        .ellipsis, // Truncate if the email is too long
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderDropdown() {
    // Select the appropriate icon based on the gender value
    IconData genderIcon = Icons.person; // Default icon
    switch (gender) {
      case 'Male':
        genderIcon = Icons.male; // Male icon
        break;
      case 'Female':
        genderIcon = Icons.female; // Female icon
        break;
      case 'Prefer Not to Say':
        genderIcon = Icons.help_outline; // "Prefer Not to Say" icon
        break;
      default:
        genderIcon = Icons.person; // Default icon
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8), // Space between label and dropdown
        Container(
          width: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), // Rounded corners
            border: Border.all(color: Colors.grey), // Border color
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              value: gender.isNotEmpty ? gender : null,
              hint: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    genderIcon, // Display the selected gender icon before the text
                    color: Colors.grey, // Icon color
                    size: 20, // Icon size
                  ),
                  const SizedBox(width: 8), // Space between icon and text
                  const Text(
                    'Select Gender',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              items: <String>['Male', 'Female', 'Prefer Not to Say']
                  .map((String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                              value == 'Male'
                                  ? Icons.male
                                  : value == 'Female'
                                      ? Icons.female
                                      : Icons
                                          .help_outline, // Gender-specific icons
                              color: Colors.grey,
                              size: 25,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              value,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (String? newValue) async {
                setState(() {
                  gender = newValue!;
                });
                // Optionally, update gender in Firebase or another service here
                await Auth().updateUserGender(gender);
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDOB(BuildContext context) async {
    DateTime initialDate =
        dob.isNotEmpty ? DateTime.parse(dob) : DateTime.now();
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null && selectedDate != DateTime.now()) {
      setState(() {
        dob = DateFormat('yyyy-MM-dd').format(selectedDate);
        dateController.text = dob; // Update DOB text field
      });

      // Call updateDob method to update DOB in Firestore
      await Auth().updateDob(dob);
    }
  }

  Widget _dobDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDOB(context), // Show date picker on tap
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8), // Rounded corners
              border: Border.all(color: Colors.grey), // Border color
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.edit_calendar_outlined, // Icon for DOB
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8), // Space between the icon and the text
                Expanded(
                  child: Text(
                    dob.isEmpty ? 'Select DOB' : dob, // Show selected DOB
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow
                        .ellipsis, // Truncate if the text is too long
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isAdmin == 'true') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminScreen(),
          ),
        );
      });
    }
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
              _emailDisplay(),
              const SizedBox(height: 10),
              _genderDropdown(),
              const SizedBox(height: 10),
              _dobDisplay(),
              const SizedBox(height: 20),
              const SizedBox(height: 60),
              _signOutButton()
            ],
          ),
        ),
      ),
    );
  }
}

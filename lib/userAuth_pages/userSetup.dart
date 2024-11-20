// ignore_for_file: file_names

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fyp/userAuth_pages/auth.dart';
import 'package:flutter_fyp/widget_tree.dart';
import 'package:intl/intl.dart';

class UserSetupPage extends StatefulWidget {
  const UserSetupPage({super.key});

  @override
  State<UserSetupPage> createState() => _UserSetupPageState();
}

class _UserSetupPageState extends State<UserSetupPage> {
  String? selectedGender;
  String? selectedDate;
  TextEditingController dateController = TextEditingController();
  User? user;
  Map<String, String>? userData;
  String gender = '';
  String dob = '';

  final List<String> genders = ['Male', 'Female', 'Other'];
  bool isGenderSelected = false; // Track if gender has been selected

  // Function to proceed to the next section after gender is selected
  void proceedToDateOfBirth() {
    setState(() {
      isGenderSelected = true; // Move to DOB selection
    });
  }

  // Function to complete the profile setup
  Future<void> completeProfileSetup() async {
    try {
      // Fetch user data (including UID) using the getUserData function
      Map<String, String>? userData = await Auth().getUserData();

      if (userData == null) {
        print('Error: User data is null');
        return;
      }

      // Get user ID (UID) from the returned data
      final currentUser = Auth().currentUser;
      setState(() {
        user = currentUser;
      });

      if (user?.uid == null) {
        print('No UID found');
        return;
      }

      // Prepare data to update
      Map<String, String> updatedData = {
        'gender': selectedGender ?? "", // The gender value you collected
        'dob': selectedDate ?? "", // The date of birth value you collected
      };

      // Now pass a non-null UID to the function
      await Auth().addGenderAndDob(
          user!.uid, updatedData); // Use '!' to assert non-null UID

      // Optionally, navigate to another screen after the update
      if (mounted) {
        Route route = MaterialPageRoute(builder: (context) => WidgetTree());
        Navigator.pushReplacement(context, route);
      }
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          selectedDate != null ? DateTime.parse(selectedDate!) : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked.toString().split(" ")[0] != selectedDate) {
      setState(() {
        // Convert DateTime to string in desired format (e.g., 'yyyy-MM-dd')
        selectedDate = DateFormat('yyyy-MM-dd')
            .format(picked); // Format the DateTime as a string
        dateController.text =
            selectedDate!; // Update the text field with formatted date string
      });
    }
  }

  Widget _title() {
    return const Text(
      'Setting up your profile',
      style: TextStyle(fontSize: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _title(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              selectedGender == null ? 'Step 1 of 2' : 'Step 2 of 2',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: isGenderSelected ? 1.0 : 0.5,
            ),
            const SizedBox(height: 20),

            // Select Gender Section
            if (!isGenderSelected) ...[
              const Text(
                'What is your gender?',
                style: TextStyle(fontSize: 33, fontWeight: FontWeight.bold),
              ),
              const Center(
                child: Text(
                  'Help us understand you better by selecting your gender',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedGender = 'Male';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedGender == 'Male'
                                  ? Colors.blue
                                  : Colors.grey[200],
                              foregroundColor: selectedGender == 'Male'
                                  ? Colors.white
                                  : Colors.black,
                              minimumSize: const Size(160, 160),
                              shape: const CircleBorder(),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.male, size: 60),
                                SizedBox(height: 8),
                                Text('Male', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedGender = 'Female';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedGender == 'Female'
                                  ? Colors.pink
                                  : Colors.grey[200],
                              foregroundColor: selectedGender == 'Female'
                                  ? Colors.white
                                  : Colors.black,
                              minimumSize: const Size(160, 160),
                              shape: const CircleBorder(),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.female, size: 60),
                                SizedBox(height: 8),
                                Text('Female', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            selectedGender = 'Prefer Not to Say';
                          });
                        },
                        icon: const Icon(Icons.help_outline, size: 40),
                        label: const Text('Prefer Not to Say'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedGender == 'Prefer Not to Say'
                              ? Colors.green
                              : Colors.grey[200],
                          foregroundColor: selectedGender == 'Prefer Not to Say'
                              ? Colors.white
                              : Colors.black,
                          minimumSize: const Size(200, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      Padding(
                        padding: const EdgeInsets.all(30),
                        child: SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: selectedGender != null
                                ? proceedToDateOfBirth
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                            child: const Text('Continue'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Select Date of Birth Section
            if (isGenderSelected) ...[
              const Center(
                child: Text(
                  'How old are you?',
                  style: TextStyle(fontSize: 33, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const Center(
                child: Text(
                  'Providing your date of birth helps us create a more personalized experience for you.',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 100),
              Center(
                  child: Padding(
                padding: EdgeInsets.all(30),
                child: TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    labelText: 'Date of birth',
                    filled: true,
                    prefixIcon: Icon(Icons.calendar_today),
                    enabledBorder:
                        OutlineInputBorder(borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue)),
                  ),
                  readOnly: true,
                  onTap: () {
                    _selectDate();
                  },
                ),
              )),
              const SizedBox(height: 160),
              Padding(
                padding: const EdgeInsets.all(30),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: selectedDate == null
                        ? null // Disable button if no date is selected
                        : completeProfileSetup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('Finish'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

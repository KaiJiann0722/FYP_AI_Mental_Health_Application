import 'package:flutter/material.dart';
import 'package:flutter_fyp/profile_pages/profile.dart';
import 'package:flutter_fyp/journal_pages/journal_main.dart';
import 'package:get/get.dart';
import 'package:flutter_fyp/emotion_page/emotion.dart'; // Import the new chart page

class NavMenu extends StatelessWidget {
  const NavMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavController());

    return Scaffold(
      bottomNavigationBar: Obx(
        () => NavigationBar(
          height: 80,
          elevation: 0,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: (index) =>
              controller.selectedIndex.value = index,
          destinations: [
            // First destination with an icon
            NavigationDestination(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.show_chart), label: 'Chart'),
            NavigationDestination(
                icon: Icon(Icons.music_note_rounded), label: 'Music'),
            NavigationDestination(
                icon: Icon(Icons.chat_outlined), label: 'Chatbot'),
            NavigationDestination(
                icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    JournalMainPage(),
    EmotionChartPage(),
    Container(color: Colors.purple),
    Container(color: Colors.black),
    ProfilePage()
  ];
}

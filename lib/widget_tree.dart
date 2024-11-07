import 'package:flutter/material.dart';
import 'package:flutter_fyp/userAuth_pages/login.dart';
import 'package:flutter_fyp/userAuth_pages/home_page.dart';
import 'package:flutter_fyp/userAuth_pages/auth.dart';
import 'package:flutter_fyp/layout_pages/nav_menu.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Auth().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return NavMenu();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

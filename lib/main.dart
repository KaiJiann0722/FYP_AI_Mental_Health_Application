import 'package:flutter/material.dart';
import 'package:flutter_fyp/widget_tree.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
    apiKey: 'AIzaSyBKbhpbjNenAuXilE4ysBUdIVT0VaKrGaI',
    appId: '1:9969613141:android:5fa18572b6731982efd7dc',
    messagingSenderId: '9969613141',
    projectId: 'fyp-db-4e0f7',
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WidgetTree(),
    );
  }
}
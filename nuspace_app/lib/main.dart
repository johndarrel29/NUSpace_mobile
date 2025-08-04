import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nuspace_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NU Space',
      // theme: ThemeData(
      //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      // ),
      home: Scaffold(
        appBar: AppBar(title: const Text('NU Space')),
        body: const Center(child: Text('Firebase Initialized')),
      ),
    );
  }
}

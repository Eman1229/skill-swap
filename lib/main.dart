import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap/firebase_options.dart';
import 'package:skill_swap/screens/splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://dvmqgwosltkmtltwfvpp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2bXFnd29zbHRrbXRsdHdmdnBwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzMTg3NjcsImV4cCI6MjA5Mzg5NDc2N30.OlvpVDEcYSzm8C-hu-JYTh-bjgLVoK1JajmrQMsDULY',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF0F172A)),
      home: SplashScreen(),
    );
  }
}
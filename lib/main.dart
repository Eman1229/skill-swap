import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap/firebase_options.dart';
import 'package:skill_swap/screens/splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skill_swap/services/presence_service.dart';
import 'package:skill_swap/services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🔵 Firebase init
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Push Notifications (FCM)
    await FcmService().init();

    // Enable Firestore offline persistence/caching
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // 🟣 Supabase init
    await Supabase.initialize(
      url: 'https://dvmqgwosltkmtltwfvpp.supabase.co',
      anonKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2bXFnd29zbHRrbXRsdHdmdnBwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzMTg3NjcsImV4cCI6MjA5Mzg5NDc2N30.OlvpVDEcYSzm8C-hu-JYTh-bjgLVoK1JajmrQMsDULY',
    );


    runApp(const MyApp());

  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text("Initialization Error: $e")),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: FcmService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFF0F172A),
      ),

      home:  const SplashScreen(),
    );
  }
}
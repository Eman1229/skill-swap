import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:skill_swap/Ui_helper/Ui_helper.dart';
import 'package:skill_swap/screens/offline/offlinescreen.dart';
import 'package:skill_swap/screens/onboarding1/onboarding1.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkInternetAndNavigate();
  }

  Future<bool> hasInternet() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void checkInternetAndNavigate() async {
    await Future.delayed(Duration(seconds: 3));

    if (!mounted) return;

    bool internetAvailable = await hasInternet();

    if (!mounted) return;

    if (internetAvailable) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnBoardingScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OfflineScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Safe image with error fallback
            Image.asset(
              'assets/Images/logo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.swap_horiz, size: 100, color: Colors.white);
              },
            ),
            SizedBox(height: 10),
            // Loading indicator
            SizedBox(height: 30),
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:skill_swap/screens/offline/offlinescreen.dart';
import 'package:skill_swap/screens/onboarding1/onboarding1.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

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
          .head(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      try {
        final response = await http
            .get(Uri.parse('https://www.google.com'))
            .timeout(const Duration(seconds: 4));
        return response.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }

  void checkInternetAndNavigate() async {
    // Start internet check immediately in the background
    final internetCheck = hasInternet();

    // Visual logo delay of 800ms to keep the user experience smooth and professional
    await Future.delayed(const Duration(milliseconds: 800));

    final internetAvailable = await internetCheck;

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
    context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                return Icon(Icons.swap_horiz, size: 100, color: Theme.of(context).colorScheme.onSurface);
              },
            ),
            SizedBox(height: 10),
            // Loading indicator
            SizedBox(height: 30),
            CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

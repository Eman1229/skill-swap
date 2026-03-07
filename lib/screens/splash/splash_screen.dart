import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

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
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void checkInternetAndNavigate() async {
    await Future.delayed(Duration(seconds: 5));
    bool internetAvailable = await hasInternet();

    if (internetAvailable) {
      // Internet available → go to onboarding
      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) => OnBoardingScreen()),
      );
    } else {
      // No internet → go to offline screen
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => OfflineScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UiHelper.CustomImage(imgurl: "logo.png"),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

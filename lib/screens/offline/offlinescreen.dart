import 'package:flutter/material.dart';
import 'package:skill_swap/ui_helper/ui_helper.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UiHelper.CustomImage(imgurl: "nowifi.png"),
            Text(
              "You are Offline",
              style: TextStyle(
                fontFamily: "Nunito",
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w400,
                fontSize: 32,
              ),
            ),
            Text(
              "No Internet connection found. Check",
              style: TextStyle(
                fontFamily: "Inter",
                fontSize: 14,
                color: Color(0XFF888888),
              ),
            ),
            SizedBox(height: 4),
            Text(
              "your connection or try again.",
              style: TextStyle(
                fontFamily: "Inter",
                fontSize: 14,
                color: Color(0XFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
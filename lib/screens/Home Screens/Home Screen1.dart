import 'package:flutter/material.dart' show AppBar, BuildContext, Center, Color, Column, ElevatedButton, FontWeight, Key, MainAxisAlignment, MaterialPageRoute, Navigator, Scaffold, SizedBox, StatelessWidget, Text, TextStyle, Widget;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/screens/sign%20in/sign%20in.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // Logout function
  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Skill Swap Home"),
        backgroundColor: const Color(0xFF00C2FF),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              "Welcome to Skill Swap 🎉",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "You have successfully logged in.",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                logout(context);
              },
              child: const Text("Logout"),
            )

          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Home%20Screens/Home%20Screen1.dart';
import 'package:skill_swap/screens/Sign%20in/sign%20in.dart';

class LearningSkill1 extends StatefulWidget {
  const LearningSkill1({Key? key}) : super(key: key);

  @override
  State<LearningSkill1> createState() => _LearningSkill1State();
}

class _LearningSkill1State extends State<LearningSkill1> {
  final TextEditingController _skillController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Navy Background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Title
            const Text(
              "What do you want to \nLearn?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF00C2FF), // Sky Blue
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 60),

            // Skill Input Field
            TextField(
              controller: _skillController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Skill Name",
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(
                  Icons.lightbulb_outline,
                  color: Colors.grey,
                  size: 28,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00C2FF)),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Next Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)
                  =>HomeScreen(),),
                  );
                  print("Teaching: ${_skillController.text}");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C2FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Next",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
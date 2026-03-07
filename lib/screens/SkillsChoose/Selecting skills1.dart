import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Learning%20Skills/Learning%20Skills.dart';

class TeachOthersScreen extends StatefulWidget {
  const TeachOthersScreen({Key? key}) : super(key: key);

  @override
  State<TeachOthersScreen> createState() => _TeachOthersScreenState();
}

class _TeachOthersScreenState extends State<TeachOthersScreen> {
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
              "What Can You Teach\nOthers?",
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
              decoration: InputDecoration(
                hintText: "Skill Name",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.grey,
                  size: 28,
                ),
                // This creates the white line underneath
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const UnderlineInputBorder(
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
                  print("Teaching: ${_skillController.text}");
                  Navigator.push(context, MaterialPageRoute
                    (builder: (context)=>
                  const LearningSkillsScreen(),),
                  );
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
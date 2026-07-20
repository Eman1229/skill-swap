import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Learning Skills/Learning Skills.dart';

class TeachOthersScreen extends StatefulWidget {
  const TeachOthersScreen({Key? key}) : super(key: key);

  @override
  State<TeachOthersScreen> createState() => _TeachOthersScreenState();
}

class _TeachOthersScreenState extends State<TeachOthersScreen> {
  final TextEditingController _skillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _skillController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 30,
          ),
          child: Column(
            children: [
              const SizedBox(height: 45),
              const Text(
                "What Can You Teach\nOthers?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF00C2FF),
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 43),

              Container(
                height: 40,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white24,
                      width: 1,
                    ),
                  ),
                ),
                child: TextField(
                  controller: _skillController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.school_outlined,
                      color: Colors.grey,
                      size: 16,
                    ),
                    hintText: "Skill Name",
                    hintStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 29),

              SizedBox(
                width: double.infinity,
                height: 47,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C2FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _skillController.text.trim().isEmpty
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LearningSkillsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Next",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Learning%20Skills/Learning%20Skills1.dart';
import 'package:skill_swap/screens/Sign%20in/sign%20in.dart';

class LearningSkillsScreen extends StatefulWidget {
  const LearningSkillsScreen({Key? key}) : super(key: key);

  @override
  State<LearningSkillsScreen> createState() => _LearningSkillsScreenState();
}

class _LearningSkillsScreenState extends State<LearningSkillsScreen> {
  String? selectedSkill;

  final List<Map<String, dynamic>> skills = [
    {
      "name": "AI",
      "icon": Icons.auto_awesome,
      "color": const Color(0xFFFF6A6B),
    },
    {
      "name": "Coding",
      "icon": Icons.code,
      "color": const Color(0xFF9D4EDD),
    },
    {
      "name": "Drawing",
      "icon": Icons.palette,
      "color": const Color(0xFFF5CB1A),
    },
    {
      "name": "Data Analysis",
      "icon": Icons.storage,
      "color": const Color(0xFF5FD5C7),
    },
    {
      "name": "Digital Marketing",
      "icon": Icons.code,
      "color": const Color(0xFFF5CB1A),
    },
    {
      "name": "Design",
      "icon": Icons.design_services,
      "color": const Color(0xFF6EE7E0),
    },
    {
      "name": "Music",
      "icon": Icons.music_note,
      "color": const Color(0xFFFF6A6B),
    },
    {
      "name": "Photos",
      "icon": Icons.camera_alt,
      "color": const Color(0xFF9D4EDD),
    },
    {
      "name": "others",
      "icon": Icons.more_horiz,
      "color": const Color(0xFF6EE7E0),
    },
  ];

  void toggleSkill(String skill) {
    setState(() {
      if (selectedSkill == skill) {
        selectedSkill = null;
      } else {
        selectedSkill = skill;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isFilled = selectedSkill != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "Select a skill you're\ninterested to learn.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF00C2FF),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Expanded(
                child: GridView.builder(
                  itemCount: skills.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final skill = skills[index];
                    final bool isSelected =
                        selectedSkill == skill["name"];

                    return GestureDetector(
                      onTap: () => toggleSkill(skill["name"]),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: skill["color"],
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                    color: const Color(0xFF9D4EDD),
                                    width: 3,
                                  )
                                      : null,
                                ),
                                child: Icon(
                                  skill["icon"],
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),

                              if (isSelected)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF9D4EDD),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            skill["name"],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    isFilled ? const Color(0xFF00C2FF) : Colors.grey,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: !isFilled
                      ? null
                      : () {
                    if (selectedSkill=="Others") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SignInScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LearningSkill1(),
                        ),
                      );
                    }
                  },

                  child: const Text(
                    "Next",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
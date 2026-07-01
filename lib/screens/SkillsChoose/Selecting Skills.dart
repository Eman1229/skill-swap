import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Learning Skills/Learning Skills.dart';
import 'Selecting skills1.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';
import 'skill_selection_layout.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({Key? key}) : super(key: key);

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final int maxSelection = 5;
  final Set<String> selectedSkills = {};

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
      "name": "Others",
      "icon": Icons.more_horiz,
      "color": const Color(0xFF6EE7E0),
    },
  ];

  void toggleSkill(String skill) {
    setState(() {
      if (selectedSkills.contains(skill)) {
        selectedSkills.remove(skill);
        return;
      }

      // If Others is selected, it becomes the only selection
      if (skill == "Others") {
        selectedSkills.clear();
        selectedSkills.add("Others");
        return;
      }

      // If any normal skill is selected, remove Others first
      selectedSkills.remove("Others");

      if (selectedSkills.length < maxSelection) {
        selectedSkills.add(skill);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  "Choose up to 5 skills\nyou can teach others.",
                  style: const TextStyle(
                    color: Color(0XFF00C2FF),
                    fontSize: 25,
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
                    selectedSkills.contains(skill["name"]);

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
                                    color: Color(0XFF9D4EDD),
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
                                      color: Color(0XFF9D4EDD),
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
                    backgroundColor: const Color(0xFF00C2FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: selectedSkills.isEmpty
                      ? null
                      : () {
                    if (selectedSkills.contains("Others")) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeachOthersScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LearningSkillsScreen(),
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
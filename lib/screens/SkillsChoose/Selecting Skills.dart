import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Learning%20Skills/Learning%20Skills.dart';

import 'Selecting skills1.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({Key? key}) : super(key: key);

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final int maxSelection = 5;
  final Set<String> selectedSkills = {};

  final List<Map<String, dynamic>> skills = [
    {"name": "AI", "icon": Icons.auto_awesome, "color": Color(0XFFFF6A6B)},
    {"name": "Coding", "icon": Icons.code, "color": Color(0XFF9D4EDD)},
    {"name": "Drawing", "icon": Icons.brush, "color": Color(0XFFF5CB1A)},
    {"name": "Data Analysis", "icon": Icons.storage, "color": Color(0XFF5FD5C7)},
    {"name": "Digital Marketing", "icon": Icons.campaign, "color": Color(0XFFF5CB1A)},
    {"name": "Design", "icon": Icons.design_services, "color": Color(0XFF5FD5C7)},
    {"name": "Music", "icon": Icons.music_note, "color": Color(0XFFFF6A6B)},
    {"name": "Photos", "icon": Icons.camera_alt, "color": Color(0XFF9D4EDD)},
    {"name": "Others", "icon": Icons.more_horiz, "color": Color(0XFF5FD5C7)},
  ];

  void toggleSkill(String skill) {
    setState(() {
      if (selectedSkills.contains(skill)) {
        selectedSkills.remove(skill);
      } else {
        if (selectedSkills.length < maxSelection) {
          selectedSkills.add(skill);
        }
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
              const SizedBox(height: 77,
              width: 335,),
              const Text(
                "Choose up to 5 skills\nyou can teach others.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0XFF00C2FF),
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),

              Expanded(
                child: GridView.builder(
                  itemCount: skills.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final skill = skills[index];
                    final bool isSelected =
                    selectedSkills.contains(skill["name"]);

                    return GestureDetector(
                      onTap: () => toggleSkill(skill["name"]),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width:80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: skill["color"].withOpacity(0.9),
                                  border: isSelected
                                      ? Border.all(color: Color(0XFF9D4EDD), width: 3)
                                      : null,

                                ),
                                child: Center(
                                  child: Icon(
                                    skill["icon"],
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),

                              if (isSelected)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Color(0XFF9D4EDD),
                                    child: const Icon(
                                      Icons.check,
                                      size: 26,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      const SizedBox(height: 8), // 2. Space between circle and text
                      Text(
                        skill["name"], // 3. The skill label
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
                height: 50,
                child: ElevatedButton(
                  onPressed: selectedSkills.isNotEmpty ? () {
                    //check if other option is selected
                    if(selectedSkills.contains('Others')) {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => const TeachOthersScreen()),
                      );
                    }else{
                      Navigator.push(context, MaterialPageRoute
                        (builder: (context)=>
                      const LearningSkillsScreen(),)
                      );
                    }
                    print(selectedSkills);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0XFF00C2FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Next",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

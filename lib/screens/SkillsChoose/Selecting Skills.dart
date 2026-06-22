import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Learning%20Skills/Learning%20Skills.dart';

import 'Selecting skills1.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';
import 'skill_selection_layout.dart';

class SkillsScreen extends StatefulWidget {
  SkillsScreen({Key? key}) : super(key: key);

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final int maxSelection = 5;
  final Set<String> selectedSkills = {};

<<<<<<< Updated upstream
=======
  final List<Map<String, dynamic>> skills = [
    {"name": "AI", "icon": Icons.auto_awesome},
    {"name": "Coding", "icon": Icons.code},
    {"name": "Drawing", "icon": Icons.brush},
    {"name": "Data Analysis", "icon": Icons.storage},
    {"name": "Digital\nMarketing", "icon": Icons.campaign},
    {"name": "Design", "icon": Icons.design_services},
    {"name": "Music", "icon": Icons.music_note},
    {"name": "Photos", "icon": Icons.camera_alt},
    {"name": "Others", "icon": Icons.more_horiz},
  ];

  // Define distinct colors matching the mockup
  final List<Color> skillColors = [
    Color(0xFFE05A5A), // red - AI
    Color(0xFF9B59B6), // purple - Coding
    Color(0xFFE6B800), // yellow - Drawing
    Color(0xFF00BFA5), // teal - Data Analysis
    Color(0xFFE6B800), // yellow - Digital Marketing
    Color(0xFF00BFA5), // teal - Design
    Color(0xFFE05A5A), // red - Music
    Color(0xFF9B59B6), // purple - Photos
    Color(0xFF00BFA5), // teal - Others
  ];

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
    return SkillSelectionScaffold(
      title: "choose_teach_skills".tr(),
      selectedSkills: selectedSkills,
      onSkillTap: toggleSkill,
      onNext: selectedSkills.isNotEmpty
          ? () {
              if (selectedSkills.contains('Others')) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TeachOthersScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LearningSkillsScreen()),
                );
              }
            }
          : null,
=======
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 35),
              Text(
                "choose_teach_skills".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 30),

              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: skills.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.79,
                  ),
                  itemBuilder: (context, index) {
                    final skill = skills[index];
                    final bool isSelected = selectedSkills.contains(skill["name"]);
                    final Color skillColor = skillColors[index];

                    return GestureDetector(
                      onTap: () => toggleSkill(skill["name"]),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: skillColor,
                                  border: isSelected
                                      ? Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  )
                                      : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    skill["icon"],
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.check,
                                      size: 16,
                                      color: skillColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            skill["name"],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: selectedSkills.isNotEmpty
                      ? () {
                    if (selectedSkills.contains('Others')) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeachOthersScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LearningSkillsScreen(),
                        ),
                      );
                    }
                    print(selectedSkills);
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedSkills.isNotEmpty
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade700,
                    disabledBackgroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "next".tr(),
                    style: const TextStyle(
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
>>>>>>> Stashed changes
    );
  }
}
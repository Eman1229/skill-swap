import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Learning%20Skills/Learning%20Skills1.dart';
import 'package:skill_swap/screens/Sign%20in/sign%20in.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';
import 'package:skill_swap/screens/SkillsChoose/skill_selection_layout.dart';
import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';

class LearningSkillsScreen extends StatefulWidget {
  const LearningSkillsScreen({Key? key}) : super(key: key);

  @override
  State<LearningSkillsScreen> createState() => _LearningSkillsScreenState();
}

class _LearningSkillsScreenState extends State<LearningSkillsScreen> {
  Set<String> selectedSkills = {};

  final List<Map<String, dynamic>> skills = [
    {
      "name": "AI",
      "icon": Icons.auto_awesome,
      "color": const Color(0xFFFF6A6B),
    },
    {"name": "Coding", "icon": Icons.code, "color": const Color(0xFF9D4EDD)},
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

      if (skill == 'Others') {
        selectedSkills.clear();
        selectedSkills.add('Others');
        return;
      }

      selectedSkills.remove('Others');
      selectedSkills.add(skill);
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    return SkillSelectionScaffold(
      title: "choose_learn_skills".tr(),
      selectedSkills: selectedSkills,
      onSkillTap: toggleSkill,
      onNext: selectedSkills.isNotEmpty
          ? () {
              if (selectedSkills.contains('Others')) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LearningSkill1()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignInScreen()),
                );
              }
            }
          : null,
    );
  }
}

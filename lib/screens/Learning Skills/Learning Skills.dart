import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Learning%20Skills/Learning%20Skills1.dart';
import 'package:skill_swap/screens/Sign%20in/sign%20in.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';
import 'package:skill_swap/screens/SkillsChoose/skill_selection_layout.dart';

class LearningSkillsScreen extends StatefulWidget {
  LearningSkillsScreen({Key? key}) : super(key: key);

  @override
  State<LearningSkillsScreen> createState() => _LearningSkillsScreenState();
}

class _LearningSkillsScreenState extends State<LearningSkillsScreen> {
  final int maxSelection = 5;
  final Set<String> selectedSkills = {};

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
import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Learning%20Skills/Learning%20Skills.dart';

import 'Selecting skills1.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';
import 'skill_selection_layout.dart';
import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';

class SkillsScreen extends StatefulWidget {
  SkillsScreen({Key? key}) : super(key: key);

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
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
    context.watch<LanguageProvider>();
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
    );
  }
}
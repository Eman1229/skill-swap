import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Learning%20Skills/Learning%20Skills.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';
import 'skill_selection_layout.dart';

class TeachOthersScreen extends StatefulWidget {
  TeachOthersScreen({Key? key}) : super(key: key);

  @override
  State<TeachOthersScreen> createState() => _TeachOthersScreenState();
}

class _TeachOthersScreenState extends State<TeachOthersScreen> {
  final TextEditingController _skillController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return OtherSkillScaffold(
      title: "what_can_teach_others".tr(),
      controller: _skillController,
      onNext: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LearningSkillsScreen()),
        );
      },
    );
  }
}

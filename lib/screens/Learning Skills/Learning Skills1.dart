import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Home%20Screens/Home%20Screen1.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';
import 'package:skill_swap/screens/Sign%20in/sign%20in.dart';
import 'package:skill_swap/screens/SkillsChoose/skill_selection_layout.dart';

class LearningSkill1 extends StatefulWidget {
  LearningSkill1({Key? key}) : super(key: key);

  @override
  State<LearningSkill1> createState() => _LearningSkill1State();
}

class _LearningSkill1State extends State<LearningSkill1> {
  final TextEditingController _skillController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return OtherSkillScaffold(
      title: "what_want_learn".tr(),
      controller: _skillController,
      onNext: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SignInScreen()),
        );
      },
    );
  }
}

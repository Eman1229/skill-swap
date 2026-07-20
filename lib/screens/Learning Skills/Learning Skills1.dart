import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
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
    context.watch<LanguageProvider>();
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

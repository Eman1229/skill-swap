import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Learning%20Skills/Learning%20Skills.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class TeachOthersScreen extends StatefulWidget {
  TeachOthersScreen({Key? key}) : super(key: key);

  @override
  State<TeachOthersScreen> createState() => _TeachOthersScreenState();
}

class _TeachOthersScreenState extends State<TeachOthersScreen> {
  final TextEditingController _skillController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Dark Navy Background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            // Title
            Text(
              "choose_teach_skills".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary, // Sky Blue
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 60),

            // Skill Input Field
            TextField(
              controller: _skillController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "title_label".tr(),
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(
                  Icons.lightbulb_outline,
                  color: Colors.grey,
                  size: 28,
                ),
                // This creates the white line underneath
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),

            SizedBox(height: 40),

            // Next Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  print("Teaching: ${_skillController.text}");
                  Navigator.push(context, MaterialPageRoute
                    (builder: (context)=>
                  LearningSkillsScreen(),),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  "next".tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
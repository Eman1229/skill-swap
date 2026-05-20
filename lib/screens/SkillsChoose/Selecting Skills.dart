import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Learning%20Skills/Learning%20Skills.dart';

import 'Selecting skills1.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class SkillsScreen extends StatefulWidget {
  SkillsScreen({Key? key}) : super(key: key);

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final int maxSelection = 5;
  final Set<String> selectedSkills = {};

  final List<Map<String, dynamic>> skills = [
    {"name": "AI", "icon": Icons.auto_awesome},
    {"name": "Coding", "icon": Icons.code},
    {"name": "Drawing", "icon": Icons.brush},
    {"name": "Data Analysis", "icon": Icons.storage},
    {"name": "Digital Marketing", "icon": Icons.campaign},
    {"name": "Design", "icon": Icons.design_services},
    {"name": "Music", "icon": Icons.music_note},
    {"name": "Photos", "icon": Icons.camera_alt},
    {"name": "Others", "icon": Icons.more_horiz},
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 77,
              width: 335,),
              Text(
                "choose_teach_skills".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 30),

              Expanded(
                child: GridView.builder(
                  itemCount: skills.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final skill = skills[index];
                    final bool isSelected = selectedSkills.contains(skill["name"]);
                    final skillColor = index.isEven
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary;

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
                                  color: skillColor.withOpacity(0.9),
                                  border: isSelected
                                      ? Border.all(color: Theme.of(context).colorScheme.secondary, width: 3)
                                      : null,

                                ),
                                child: Center(
                                  child: Icon(
                                    skill["icon"],
                                    color: Theme.of(context).colorScheme.onSurface,
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
                                    backgroundColor: Theme.of(context).colorScheme.secondary,
                                    child: Icon(
                                      Icons.check,
                                      size: 26,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      SizedBox(height: 8), // 2. Space between circle and text
                      Text(
                        skill["name"], // 3. The skill label
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
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
                          builder: (context) => TeachOthersScreen()),
                      );
                    }else{
                      Navigator.push(context, MaterialPageRoute
                        (builder: (context)=>
                      LearningSkillsScreen(),)
                      );
                    }
                    print(selectedSkills);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "next".tr(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
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

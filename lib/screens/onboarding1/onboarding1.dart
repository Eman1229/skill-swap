import 'package:flutter/material.dart';
import 'package:skill_swap/screens/SkillsChoose/Selecting Skills.dart';

import '../../Ui_helper/Ui_helper.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Welcome to SkillSwapX", style: TextStyle(fontFamily:"Nunito",fontSize: 26, fontWeight: FontWeight.w400,
                  color: Color(0xFF00C2FF),
                ), textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text("Trade Skills, Learn cool stuff, No money needed", style: TextStyle(fontFamily:"Inter",fontSize: 14,
                fontWeight: FontWeight.w500, color: Color(0XFFF8FAFC),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
             UiHelper.CustomImage(imgurl: "Onboard1.png"),
        SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, 
                    MaterialPageRoute(builder: (context)
                    => const SkillsScreen(),),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00C2FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text("Proceed", style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0XFFF8FAFC),
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

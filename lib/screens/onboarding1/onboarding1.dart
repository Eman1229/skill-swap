import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Sign%20in/sign%20in.dart';

import '../../ui_helper/ui_helper.dart';

class OnBoardingScreen extends StatelessWidget {
  OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('welcome_to_skillswap'.tr(), style: TextStyle(fontFamily:"Nunito",fontSize: 26, fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ), textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text('onboard_slogan'.tr(), style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    => SignInScreen(),),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text('proceed'.tr(), style: TextStyle(fontSize: 16,
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

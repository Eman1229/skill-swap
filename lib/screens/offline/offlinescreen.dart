import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap/ui_helper/ui_helper.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UiHelper.CustomImage(imgurl: "nowifi.png"),
            Text('you_are_offline'.tr(),
              style: TextStyle(
                fontFamily: "Nunito",
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w400,
                fontSize: 32,
              ),
            ),
            Text('no_internet_line1'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: Color(0XFF888888),
              ),
            ),
            SizedBox(height: 4),
            Text('no_internet_line2'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: Color(0XFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
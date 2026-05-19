import 'package:flutter/material.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class AboutScreen extends StatelessWidget {
  AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'about_skill_swap_title'.tr(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            _buildGlowingLogo(context),
            SizedBox(height: 16),
            Text(
              'Skill Swap',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.2),
            ),
            SizedBox(height: 6),
            Text(
              'Version 1.0.0 (Build 12)',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 32),
            _buildAboutCard(context),
            SizedBox(height: 32),
            _buildSectionTitle(context, 'legal_agreements'.tr()),
            _buildLegalTile(
              context: context,
              icon: Icons.article_outlined,
              title: 'terms_of_service'.tr(),
              content: _termsText,
            ),
            _buildLegalTile(
              context: context,
              icon: Icons.privacy_tip_outlined,
              title: 'privacy_policy'.tr(),
              content: _privacyText,
            ),
            _buildLegalTile(
              context: context,
              icon: Icons.code_rounded,
              title: 'open_source_licenses'.tr(),
              content: _licensesText,
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowingLogo(BuildContext context) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.8), width: 2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.swap_horizontal_circle_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 56,
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withAlpha(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'democratizing_education'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 10),
          Text(
            'Skill Swap is an innovative peer-to-peer knowledge barter platform designed to bring learners and mentors together. We believe that everyone is an expert in something and a student in another.\n\nOur mission is to bypass financial barriers in career growth, hobbies, and educational pursuits by establishing a direct value exchange—helping you teach what you love to learn what you need.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 4, bottom: 12),
        child: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildLegalTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withAlpha(8)),
      ),
      child: ListTile(
        onTap: () => _showLegalBottomSheet(context, title, content),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: Theme.of(context).colorScheme.outlineVariant, size: 16),
      ),
    );
  }

  void _showLegalBottomSheet(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6), height: 20),
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Text(
                    content,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _termsText = '''
Welcome to Skill Swap! These Terms of Service ("Terms") govern your use of the Skill Swap mobile application and related platform.

1. ACCEPTANCE OF TERMS
By downloading or using the App, you agree to comply with and be bound by these Terms. If you do not agree, please do not use the application.

2. DESCRIPTION OF SERVICE
Skill Swap is a direct-barter educational exchange application allowing users to offer skills to teach in exchange for learning other skills from peer users.

3. USER ACCOUNTS AND SECURITY
You must create a valid account to publish swap listings. You are solely responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.

4. USER CONDUCT & PROHIBITED CONTENT
Users must maintain respect during chat sessions. You may not publish content that is misleading, fraudulent, defamatory, adult, or otherwise inappropriate. We reserve the absolute right to terminate accounts that violate this clause.

5. NO GUARANTEES OR WARRANTIES
Skill Swap is a peer-to-peer connection service. We do not evaluate or certify the credentials of any users or listings. Swaps are arranged at your own risk.

6. LIMITATION OF LIABILITY
Skill Swap and its developers shall not be liable for any direct or indirect damages arising out of your connections or meetings scheduled through the application.

7. AMENDMENTS
We reserve the right to modify these Terms at any time. Your continued use of the platform constitutes your agreement to such modifications.
''';

  static String _privacyText = '''
Your privacy is extremely important to us. This Privacy Policy describes how Skill Swap collects, protects, and handles your information.

1. INFORMATION WE COLLECT
- Account Data: Name, email address, password, profile photo, and biography.
- Skills Listing Data: Details of the skills you offer and want.
- Chat Data: Chat messages and connection requests to coordinate swaps.
- App Usage Data: Analytics regarding popular categories.

2. HOW WE USE YOUR INFORMATION
- To facilitate connections and exchange messaging between swapping partners.
- To personalize your home screen matching feeds.
- To secure and authenticate your account through Firebase Auth.

3. DATA RETENTION
We store your profile data on Google Firebase and Supabase for as long as your account remains active. You can trigger mock account deletion or contact support to request permanent deletion at any time.

4. THIRD-PARTY SERVICES
We utilize third-party SDKs including Google Firebase (Authentication, Storage, Firestore) and Supabase to host listings and perform platform analytics. These services operate under their respective privacy policies.

5. SECURITY
We apply industry-standard cloud protection policies to protect your data. However, no database transmission is 100% secure. Please choose strong, unique credentials.
''';

  static String _licensesText = '''
Skill Swap is made possible by the incredible open-source community! Below are primary frameworks and libraries used:

■ Flutter SDK
Copyright 2014 The Flutter Authors. All rights reserved.
Licensed under the BSD 3-Clause License.

■ Firebase Core & Auth
Copyright 2020 Google LLC. All rights reserved.
Licensed under the Apache License, Version 2.0.

■ Cloud Firestore
Copyright 2020 Google LLC. All rights reserved.
Licensed under the Apache License, Version 2.0.

■ Supabase Flutter
Copyright (c) 2021 Supabase. All rights reserved.
Licensed under the MIT License.

■ Connectivity Plus
Copyright 2020 The Chromium Authors. All rights reserved.
Licensed under the BSD-style License.

■ Cupertino Icons
Copyright 2020 The Flutter Authors. All rights reserved.
Licensed under the MIT License.
''';
}

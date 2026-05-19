import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/screens/Sign%20in/sign%20in.dart';
import 'package:skill_swap/screens/Home%20Screens/swapping%20Available.dart';
import 'package:skill_swap/screens/Profile/edit_profile_screen.dart';
import 'package:skill_swap/screens/reset/Reset.dart';
import 'package:skill_swap/screens/Setting/app_settings.dart';
import 'package:skill_swap/screens/Setting/notifications_settings_screen.dart';
import 'package:skill_swap/screens/Setting/privacy_security_screen.dart';
import 'package:skill_swap/screens/Setting/language_settings_screen.dart';
import 'package:skill_swap/screens/Setting/help_center_screen.dart';
import 'package:skill_swap/screens/Setting/about_screen.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final AppSettings _settings = AppSettings();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('settings'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection('account'.tr()),
          _buildSettingTile(
            icon: Icons.person_outline_rounded,
            title: 'profile_info'.tr(),
            onTap: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;
              final snap = await FirebaseFirestore.instance
                  .collection('swapListings')
                  .where('userId', isEqualTo: uid)
                  .limit(1)
                  .get();
              if (context.mounted) {
                if (snap.docs.isNotEmpty) {
                  final mySwap = SwapListing.fromDoc(snap.docs.first);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(swap: mySwap)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No skill listing found.'.tr())),
                  );
                }
              }
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _settings.notificationsEnabled,
            builder: (context, enabled, _) {
              return _buildSettingTile(
                icon: Icons.notifications_none_rounded,
                title: 'notifications'.tr(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsSettingsScreen()),
                  );
                },
                trailing: Switch(
                  value: enabled,
                  onChanged: (v) => _settings.setNotificationsEnabled(v),
                  activeTrackColor: const Color(0xFF00C2FF),
                  activeColor: Colors.white,
                ),
              );
            },
          ),
          _buildSettingTile(
            icon: Icons.lock_outline_rounded,
            title: 'change_password'.tr(),
            onTap: () {
              final email = FirebaseAuth.instance.currentUser?.email;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmailVerificationScreen(email: email),
                ),
              );
            },
          ),
          _buildSettingTile(
            icon: Icons.security_rounded,
            title: 'privacy_security'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSection('app_preferences'.tr()),
          ValueListenableBuilder<String>(
            valueListenable: _settings.currentLanguage,
            builder: (context, currentLang, _) {
              return _buildSettingTile(
                icon: Icons.language_rounded,
                title: 'language'.tr(),
                subtitle: currentLang,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
                  );
                },
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _settings.isDarkMode,
            builder: (context, isDark, _) {
              return _buildSettingTile(
                icon: Icons.dark_mode_outlined,
                title: 'dark_mode'.tr(),
                onTap: () {
                  _settings.isDarkMode.value = !isDark;
                },
                trailing: Switch(
                  value: isDark,
                  onChanged: (v) => _settings.isDarkMode.value = v,
                  activeTrackColor: const Color(0xFF00C2FF),
                  activeColor: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSection('support'.tr()),
          _buildSettingTile(
            icon: Icons.help_outline_rounded,
            title: 'help_center'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
              );
            },
          ),
          _buildSettingTile(
            icon: Icons.info_outline_rounded,
            title: 'about_skill_swap'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          const SizedBox(height: 40),
          _LogoutButton(),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF00C2FF),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF00C2FF), size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12))
            : null,
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.white24),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const SignInScreen()),
              (route) => false,
            );
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFF3B3B), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'log_out'.tr(),
          style: const TextStyle(color: Color(0xFFFF3B3B), fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}

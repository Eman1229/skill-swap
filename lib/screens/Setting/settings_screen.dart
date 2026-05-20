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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'settings'.tr(),
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          _buildSection(context, 'account'.tr()),
          _buildSettingTile(
            context: context,
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
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(swap: mySwap),
                    ),
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
                context: context,
                icon: Icons.notifications_none_rounded,
                title: 'notifications'.tr(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationsSettingsScreen(),
                    ),
                  );
                },
                trailing: Switch(
                  value: enabled,
                  onChanged: (v) => _settings.setNotificationsEnabled(v),
                ),
              );
            },
          ),
          _buildSettingTile(
            context: context,
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
            context: context,
            icon: Icons.security_rounded,
            title: 'privacy_security'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PrivacySecurityScreen(),
                ),
              );
            },
          ),
          SizedBox(height: 24),
          _buildSection(context, 'app_preferences'.tr()),
          ValueListenableBuilder<String>(
            valueListenable: _settings.currentLanguage,
            builder: (context, currentLang, _) {
              return _buildSettingTile(
                context: context,
                icon: Icons.language_rounded,
                title: 'language'.tr(),
                subtitle: currentLang,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LanguageSettingsScreen(),
                    ),
                  );
                },
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _settings.isDarkMode,
            builder: (context, isDark, _) {
              final isLight = !isDark;
              return _buildSettingTile(
                context: context,
                icon: isLight
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                title: 'Light Mode'.tr(),
                onTap: () {
                  _settings.setDarkMode(!isLight);
                },
                trailing: Switch(
                  value: isLight,
                  onChanged: (enabled) => _settings.setDarkMode(!enabled),
                ),
              );
            },
          ),
          SizedBox(height: 24),
          _buildSection(context, 'support'.tr()),
          _buildSettingTile(
            context: context,
            icon: Icons.help_outline_rounded,
            title: 'help_center'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HelpCenterScreen()),
              );
            },
          ),
          _buildSettingTile(
            context: context,
            icon: Icons.info_outline_rounded,
            title: 'about_skill_swap'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AboutScreen()),
              );
            },
          ),
          SizedBox(height: 40),
          _LogoutButton(),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colorScheme.secondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconBackground = colorScheme.surfaceContainerHighest;
    final subtitleColor = colorScheme.onSurfaceVariant;

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colorScheme.secondary, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: subtitleColor, fontSize: 12),
              )
            : null,
        trailing:
            trailing ??
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final danger = Theme.of(context).colorScheme.error;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => SignInScreen()),
              (route) => false,
            );
          }
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: danger, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'log_out'.tr(),
          style: TextStyle(
            color: danger,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

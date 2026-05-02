import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/screens/Sign%20in/sign%20in.dart';
import 'package:skill_swap/screens/Home%20Screens/swapping%20Available.dart';
import 'package:skill_swap/screens/Profile/profile%20screen.dart';
import 'package:skill_swap/screens/Profile/edit_profile_screen.dart';
import 'package:skill_swap/screens/reset/Reset.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection('Account'),
          _buildSettingTile(
            icon: Icons.person_outline_rounded,
            title: 'Profile Information',
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
                    const SnackBar(content: Text('No skill listing found.')),
                  );
                }
              }
            },
          ),
          _buildSettingTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications settings coming soon')),
              );
            },
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeTrackColor: const Color(0xFF00C2FF),
            ),
          ),
          _buildSettingTile(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
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
            title: 'Privacy & Security',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy settings coming soon')),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSection('App Preferences'),
          _buildSettingTile(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: 'English',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language settings coming soon')),
              );
            },
          ),
          _buildSettingTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            onTap: () {},
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeTrackColor: const Color(0xFF00C2FF),
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('Support'),
          _buildSettingTile(
            icon: Icons.help_outline_rounded,
            title: 'Help Center',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help Center coming soon')),
              );
            },
          ),
          _buildSettingTile(
            icon: Icons.info_outline_rounded,
            title: 'About Skill Swap',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Skill Swap v1.0.0')),
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
        child: const Text(
          'Log Out',
          style: TextStyle(color: Color(0xFFFF3B3B), fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}

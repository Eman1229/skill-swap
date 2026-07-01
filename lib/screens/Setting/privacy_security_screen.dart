import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:skill_swap/screens/Setting/app_settings.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';
import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final AppSettings _settings = AppSettings();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) return;

    final data = doc.data()!;

    var visibility = data['profileVisibility'] ?? 'public';
    if (visibility == 'Public') visibility = 'public';
    if (visibility == 'Swappers Only') visibility = 'swappers_only';
    if (visibility == 'Private') visibility = 'private';
    _settings.profileVisibility.value = visibility;
    _settings.showOnlineStatus.value = data['showOnlineStatus'] ?? true;
    _settings.directMessagesEnabled.value = data['directMessagesEnabled'] ?? true;

    setState(() {});
  }

  Future<void> updateUserSetting(String field, dynamic value) async {
    try {
      await _firestore.collection('users').doc(uid).set({field: value}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user setting: $e');
    }
    if (field == 'profileVisibility') {
      final listings = await _firestore.collection('swapListings').where('userId', isEqualTo: uid).get();
      final batch = _firestore.batch();
      for (final doc in listings.docs) {
        batch.update(doc.reference, {'profileVisibility': value});
      }
      await batch.commit();
    }
  }

  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
    await user.delete();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'privacy_security_title'.tr(),
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          const SizedBox(height: 10),
          _buildSectionTitle('profile_visibility'.tr()),
          ValueListenableBuilder<String>(
            valueListenable: _settings.profileVisibility,
            builder: (context, visibility, _) {
              return Column(
                children: [
                  _buildVisibilityTile(
                    title: 'visibility_public'.tr(),
                    description: 'visibility_public_desc'.tr(),
                    isSelected: visibility == 'public',
                    onTap: () async {
                      setState(() => _settings.profileVisibility.value = 'public');
                      await updateUserSetting('profileVisibility', 'public');
                    },
                  ),
                  _buildVisibilityTile(
                    title: 'visibility_swappers'.tr(),
                    description: 'visibility_swappers_desc'.tr(),
                    isSelected: visibility == 'swappers_only',
                    onTap: () async {
                      setState(() => _settings.profileVisibility.value = 'swappers_only');
                      await updateUserSetting('profileVisibility', 'swappers_only');
                    },
                  ),
                  _buildVisibilityTile(
                    title: 'visibility_private'.tr(),
                    description: 'visibility_private_desc'.tr(),
                    isSelected: visibility == 'private',
                    onTap: () async {
                      setState(() => _settings.profileVisibility.value = 'private');
                      await updateUserSetting('profileVisibility', 'private');
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('preferences'.tr()),
          ValueListenableBuilder<bool>(
            valueListenable: _settings.showOnlineStatus,
            builder: (context, enabled, _) {
              return _buildSwitchTile(
                icon: Icons.circle_notifications_rounded,
                title: 'show_online_status'.tr(),
                description: 'show_online_status_desc'.tr(),
                value: enabled,
                onChanged: (v) async {
                  setState(() => _settings.showOnlineStatus.value = v);
                  await updateUserSetting('showOnlineStatus', v);
                },
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _settings.directMessagesEnabled,
            builder: (context, enabled, _) {
              return _buildSwitchTile(
                icon: Icons.chat_outlined,
                title: 'direct_msg_from_anyone'.tr(),
                description: 'direct_msg_from_anyone_desc'.tr(),
                value: enabled,
                onChanged: (v) async {
                  setState(() => _settings.directMessagesEnabled.value = v);
                  await updateUserSetting('directMessagesEnabled', v);
                },
              );
            },
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('danger_zone'.tr()),
          _buildDangerZoneCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildVisibilityTile({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : (isDark
                ? Colors.transparent
                : Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.3)),
            width: 1.5,
          ),
          boxShadow: isDark
              ? null
              : [
            BoxShadow(
              color:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.65),
                        fontSize: 12,
                        height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
        boxShadow: isDark
            ? null
            : [
          BoxShadow(
            color:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.65),
                fontSize: 12,
                height: 1.3),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF3B3B).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: const Color(0xFFFF3B3B).withValues(alpha: 0.8), size: 22),
              const SizedBox(width: 10),
              Text(
                'high_risk_actions'.tr(),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('clear_cache'.tr(),
                        style: TextStyle(
                            color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('clear_cache_desc'.tr(),
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                            fontSize: 11)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _showClearCacheDialog,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text('clear'.tr(),
                    style: TextStyle(
                        color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12)),
              ),
            ],
          ),
          Divider(
              color:
              Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
              height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('delete_account'.tr(),
                        style: TextStyle(
                            color: const Color(0xFFFF3B3B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('delete_account_desc'.tr(),
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                            fontSize: 11)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _showDeleteAccountDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B3B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text('delete'.tr(),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('clear_cache'.tr(),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold)),
          content: Text(
            'clear_cache_confirm'.tr(),
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr(),
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.65))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await DefaultCacheManager().emptyCache();
                _showSuccessSnackBar('cache_cleared'.tr());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('clear_now'.tr(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1F30),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Color(0xFFFF3B3B)),
              const SizedBox(width: 10),
              Text('delete_account'.tr(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'delete_account_confirm'.tr(),
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr(),
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.65))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await deleteAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B3B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('delete_permanently'.tr(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface))),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Setting/app_settings.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class PrivacySecurityScreen extends StatefulWidget {
  PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final AppSettings _settings = AppSettings();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'privacy_security_title'.tr(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          SizedBox(height: 10),
          _buildSectionTitle('profile_visibility'.tr()),
          ValueListenableBuilder<String>(
            valueListenable: _settings.profileVisibility,
            builder: (context, visibility, _) {
              return Column(
                children: [
                  _buildVisibilityTile(
                    title: 'visibility_public'.tr(),
                    description: 'visibility_public_desc'.tr(),
                    isSelected: visibility == 'Public',
                    onTap: () => setState(() => _settings.profileVisibility.value = 'Public'),
                  ),
                  _buildVisibilityTile(
                    title: 'visibility_swappers'.tr(),
                    description: 'visibility_swappers_desc'.tr(),
                    isSelected: visibility == 'Swappers Only',
                    onTap: () => setState(() => _settings.profileVisibility.value = 'Swappers Only'),
                  ),
                  _buildVisibilityTile(
                    title: 'visibility_private'.tr(),
                    description: 'visibility_private_desc'.tr(),
                    isSelected: visibility == 'Private',
                    onTap: () => setState(() => _settings.profileVisibility.value = 'Private'),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 24),
          _buildSectionTitle('preferences'.tr()),
          ValueListenableBuilder<bool>(
            valueListenable: _settings.showOnlineStatus,
            builder: (context, enabled, _) {
              return _buildSwitchTile(
                icon: Icons.circle_notifications_rounded,
                title: 'show_online_status'.tr(),
                description: 'show_online_status_desc'.tr(),
                value: enabled,
                onChanged: (v) => setState(() => _settings.showOnlineStatus.value = v),
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
                onChanged: (v) => setState(() => _settings.directMessagesEnabled.value = v),
              );
            },
          ),
          SizedBox(height: 32),
          _buildSectionTitle('danger_zone'.tr()),
          _buildDangerZoneCard(),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
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
    );
  }

  Widget _buildVisibilityTile({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withAlpha(13),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
              size: 20,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 12, height: 1.3),
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
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withAlpha(13)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 12, height: 1.3),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: Theme.of(context).colorScheme.primary,
          activeColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color(0xFF1E1F30), // subtle reddish tint
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFFF3B3B).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3B3B).withOpacity(0.8), size: 22),
              SizedBox(width: 10),
              Text(
                'high_risk_actions'.tr(),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('clear_cache'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('clear_cache_desc'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), fontSize: 11)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _showClearCacheDialog,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text('clear'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
              ),
            ],
          ),
          Divider(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6), height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('delete_account'.tr(), style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 13, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('delete_account_desc'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), fontSize: 11)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _showDeleteAccountDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF3B3B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text('delete'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.bold)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('clear_cache'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
          content: Text(
            'clear_cache_confirm'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                _showSuccessSnackBar('cache_cleared'.tr());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('clear_now'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
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
          backgroundColor: Color(0xFF1E1F30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Color(0xFFFF3B3B)),
              SizedBox(width: 10),
              Text('delete_account'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'delete_account_confirm'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showSuccessSnackBar('Mock Deletion: Account deleted. Signing out...');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF3B3B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('delete_permanently'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
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
            Icon(Icons.check_circle_outline_rounded, color: Theme.of(context).colorScheme.onSurface),
            SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

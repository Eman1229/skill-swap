import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Setting/app_settings.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
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
          'notifications'.tr(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          SizedBox(height: 10),
          _buildInfoCard(),
          SizedBox(height: 24),
          _buildSectionTitle('master_controls'.tr()),
          ValueListenableBuilder<bool>(
            valueListenable: _settings.notificationsEnabled,
            builder: (context, enabled, _) {
              return _buildSwitchTile(
                icon: Icons.notifications_active_rounded,
                title: 'allow_push'.tr(),
                description: 'allow_push_desc'.tr(),
                value: enabled,
                onChanged: (v) {
                  setState(() {
                    _settings.setNotificationsEnabled(v);
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              );
            },
          ),
          SizedBox(height: 24),
          _buildSectionTitle('notification_types'.tr()),
          ValueListenableBuilder<bool>(
            valueListenable: _settings.notificationsEnabled,
            builder: (context, masterEnabled, _) {
              return Column(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _settings.swapRequestsEnabled,
                    builder: (context, enabled, _) {
                      return _buildSwitchTile(
                        icon: Icons.swap_horizontal_circle_outlined,
                        title: 'swap_proposals'.tr(),
                        description: 'swap_proposals_desc'.tr(),
                        value: enabled,
                        onChanged: masterEnabled
                            ? (v) => setState(() => _settings.swapRequestsEnabled.value = v)
                            : null,
                        activeColor: Theme.of(context).colorScheme.primary,
                      );
                    },
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _settings.chatMessagesEnabled,
                    builder: (context, enabled, _) {
                      return _buildSwitchTile(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'direct_messages'.tr(),
                        description: 'direct_messages_desc'.tr(),
                        value: enabled,
                        onChanged: masterEnabled
                            ? (v) => setState(() => _settings.chatMessagesEnabled.value = v)
                            : null,
                        activeColor: Theme.of(context).colorScheme.primary,
                      );
                    },
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _settings.marketingEmailsEnabled,
                    builder: (context, enabled, _) {
                      return _buildSwitchTile(
                        icon: Icons.alternate_email_rounded,
                        title: 'weekly_tips'.tr(),
                        description: 'weekly_tips_desc'.tr(),
                        value: enabled,
                        onChanged: masterEnabled
                            ? (v) => setState(() => _settings.marketingEmailsEnabled.value = v)
                            : null,
                        activeColor: Theme.of(context).colorScheme.primary,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.15),
            Color(0xFF6B8AFF).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'customize_alerts'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
            ),
          ),
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required Color activeColor,
  }) {
    final bool isEnabled = onChanged != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isEnabled
            ? (isDark ? const Color(0xFF1E293B) : Colors.white)
            : (isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isEnabled ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isEnabled ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: TextStyle(
              color: isEnabled ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65) : Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: activeColor,
          activeColor: Theme.of(context).colorScheme.onSurface,
          inactiveThumbColor: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
          inactiveTrackColor: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6),
        ),
      ),
    );
  }
}

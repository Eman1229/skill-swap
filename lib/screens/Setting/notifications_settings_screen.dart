import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Setting/app_settings.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  final AppSettings _settings = AppSettings();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'notifications'.tr(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          const SizedBox(height: 10),
          _buildInfoCard(),
          const SizedBox(height: 24),
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
                activeColor: const Color(0xFF00C2FF),
              );
            },
          ),
          const SizedBox(height: 24),
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
                        activeColor: const Color(0xFF00C2FF),
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
                        activeColor: const Color(0xFF00C2FF),
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
                        activeColor: const Color(0xFF00C2FF),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00C2FF).withOpacity(0.15),
            const Color(0xFF6B8AFF).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C2FF).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF00C2FF), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'customize_alerts'.tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF00C2FF),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(isEnabled ? 1.0 : 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isEnabled ? const Color(0xFF00C2FF) : Colors.white38,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isEnabled ? Colors.white : Colors.white38,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: TextStyle(
              color: isEnabled ? Colors.white38 : Colors.white12,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: activeColor,
          activeColor: Colors.white,
          inactiveThumbColor: Colors.white30,
          inactiveTrackColor: Colors.white10,
        ),
      ),
    );
  }
}

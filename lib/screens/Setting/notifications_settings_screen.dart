import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/services/notification_service.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _loading = true;

  Map<String, bool> _settings = {
    'directMessages': true,
    'swapRequests': true,
    'swapUpdates': true,
    'progressUpdates': true,
    'reviews': true,
    'general': true,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final fetched = await _notificationService.getSettings(uid);
      if (mounted) {
        setState(() {
          _settings = fetched;
          _loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleSetting(String key, bool val) async {
    setState(() {
      _settings[key] = val;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _notificationService.updateSettings(uid, _settings);
    }
  }

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
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                const SizedBox(height: 10),
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('notification_types'.tr()),
                _buildSwitchTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Direct Messages',
                  description: 'Receive notifications for incoming chat messages.',
                  value: _settings['directMessages'] ?? true,
                  onChanged: (v) => _toggleSetting('directMessages', v),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                _buildSwitchTile(
                  icon: Icons.swap_horizontal_circle_outlined,
                  title: 'Swap Requests',
                  description: 'Get notified when someone sends you a new skill swap request.',
                  value: _settings['swapRequests'] ?? true,
                  onChanged: (v) => _toggleSetting('swapRequests', v),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                _buildSwitchTile(
                  icon: Icons.sync_problem_rounded,
                  title: 'Swap Updates',
                  description: 'Notifications when your swap requests are accepted or rejected.',
                  value: _settings['swapUpdates'] ?? true,
                  onChanged: (v) => _toggleSetting('swapUpdates', v),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                _buildSwitchTile(
                  icon: Icons.playlist_add_check_circle_outlined,
                  title: 'Progress Updates',
                  description: 'Alerts when your sessions are marked completed or progress changes.',
                  value: _settings['progressUpdates'] ?? true,
                  onChanged: (v) => _toggleSetting('progressUpdates', v),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                _buildSwitchTile(
                  icon: Icons.star_outline_rounded,
                  title: 'Reviews & Ratings',
                  description: 'Receive notifications for new feedback and skill reviews.',
                  value: _settings['reviews'] ?? true,
                  onChanged: (v) => _toggleSetting('reviews', v),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                _buildSwitchTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'General Notifications',
                  description: 'Receive announcements, tips, and important activity alerts.',
                  value: _settings['general'] ?? true,
                  onChanged: (v) => _toggleSetting('general', v),
                  activeColor: Theme.of(context).colorScheme.primary,
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
            Theme.of(context).colorScheme.primary.withOpacity(0.15),
            const Color(0xFF6B8AFF).withOpacity(0.05),
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Customize which push notifications and in-app alerts you want to receive on your device.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
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
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
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

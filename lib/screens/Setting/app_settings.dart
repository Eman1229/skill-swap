import 'package:flutter/material.dart';

class AppSettings {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  // Theme Settings
  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);
  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  void setDarkMode(bool value) {
    isDarkMode.value = value;
  }

  // Notification Settings
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> swapRequestsEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> chatMessagesEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> marketingEmailsEnabled = ValueNotifier<bool>(false);

  // Language Settings
  final ValueNotifier<String> currentLanguage = ValueNotifier<String>(
    'English',
  );

  // Privacy & Security Settings
  final ValueNotifier<String> profileVisibility = ValueNotifier<String>(
    'Public',
  );
  final ValueNotifier<bool> showOnlineStatus = ValueNotifier<bool>(true);
  final ValueNotifier<bool> directMessagesEnabled = ValueNotifier<bool>(true);

  // Helper method to toggle master push notifications
  void setNotificationsEnabled(bool value) {
    notificationsEnabled.value = value;
    if (!value) {
      // If master notification is off, disable child switches visually/logically
      swapRequestsEnabled.value = false;
      chatMessagesEnabled.value = false;
      marketingEmailsEnabled.value = false;
    } else {
      // Re-enable typical defaults when master is toggled back on
      swapRequestsEnabled.value = true;
      chatMessagesEnabled.value = true;
    }
  }
}

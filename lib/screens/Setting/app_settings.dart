import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  static const String _keyDarkMode = 'is_dark_mode';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<DocumentSnapshot>? _settingsSubscription;
  bool _initialized = false;

  // Theme Settings
  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);
  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  /// Load theme preference from SharedPreferences
  Future<void> loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_keyDarkMode)) {
        final savedIsDark = prefs.getBool(_keyDarkMode) ?? true;
        isDarkMode.value = savedIsDark;
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  /// Update dark mode preference, persist locally and to Firestore
  Future<void> setDarkMode(bool value) async {
    isDarkMode.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDarkMode, value);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
    await _saveToFirestore();
  }

  // Notification Settings
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> swapRequestsEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> chatMessagesEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> weeklyTipsEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> marketingEmailsEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> soundEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> vibrationEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> emailNotifications = ValueNotifier<bool>(false);

  // Loading state for settings screen
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  // Language Settings
  final ValueNotifier<String> currentLanguage = ValueNotifier<String>(
    'English',
  );

  // Privacy & Security Settings
  final ValueNotifier<String> profileVisibility = ValueNotifier<String>(
    'public',
  );
  final ValueNotifier<bool> showOnlineStatus = ValueNotifier<bool>(true);
  final ValueNotifier<bool> directMessagesEnabled = ValueNotifier<bool>(true);

  /// Firestore document reference for the current user's notification settings
  DocumentReference? get _settingsDocRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('settings').doc('notifications');
  }

  /// Initialize settings by loading from Firestore and starting realtime listener
  Future<void> initNotificationSettings() async {
    if (_initialized) return;
    isLoading.value = true;

    try {
      final docRef = _settingsDocRef;
      if (docRef == null) {
        isLoading.value = false;
        return;
      }

      // Load initial settings
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        _applyFromFirestore(snapshot.data() as Map<String, dynamic>);
      } else {
        // Create default settings in Firestore
        await _saveToFirestore();
      }

      // Start realtime listener
      _settingsSubscription = docRef.snapshots().listen(
        (snapshot) {
          if (snapshot.exists) {
            _applyFromFirestore(snapshot.data() as Map<String, dynamic>);
          }
        },
        onError: (e) => debugPrint('Settings stream error: $e'),
      );

      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing notification settings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Apply Firestore data to local ValueNotifiers without triggering saves
  void _applyFromFirestore(Map<String, dynamic> data) {
    if (data.containsKey('isDarkMode')) {
      final firestoreDark = data['isDarkMode'] as bool?;
      if (firestoreDark != null) {
        isDarkMode.value = firestoreDark;
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool(_keyDarkMode, firestoreDark);
        }).catchError((e) => debugPrint('Error updating pref from Firestore: $e'));
      }
    }
    notificationsEnabled.value = data['pushEnabled'] ?? data['notificationsEnabled'] ?? true;
    swapRequestsEnabled.value = data['swapRequestsEnabled'] ?? true;
    chatMessagesEnabled.value = data['chatMessagesEnabled'] ?? data['directMessagesEnabled'] ?? data['messagesEnabled'] ?? true;
    weeklyTipsEnabled.value = data['weeklyTipsEnabled'] ?? true;
    marketingEmailsEnabled.value = data['marketingEmailsEnabled'] ?? false;
    soundEnabled.value = data['soundEnabled'] ?? true;
    vibrationEnabled.value = data['vibrationEnabled'] ?? true;
    emailNotifications.value = data['emailNotifications'] ?? false;
  }

  /// Build the Firestore payload from current ValueNotifiers
  Map<String, dynamic> _toFirestoreMap() {
    return {
      'isDarkMode': isDarkMode.value,
      'pushEnabled': notificationsEnabled.value,
      'swapRequestsEnabled': swapRequestsEnabled.value,
      'chatMessagesEnabled': chatMessagesEnabled.value,
      'directMessagesEnabled': chatMessagesEnabled.value,
      'messagesEnabled': chatMessagesEnabled.value,
      'weeklyTipsEnabled': weeklyTipsEnabled.value,
      'marketingEmailsEnabled': marketingEmailsEnabled.value,
      'soundEnabled': soundEnabled.value,
      'vibrationEnabled': vibrationEnabled.value,
      'emailNotifications': emailNotifications.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Save current settings to Firestore
  Future<bool> _saveToFirestore() async {
    try {
      final docRef = _settingsDocRef;
      if (docRef == null) return false;
      await docRef.set(_toFirestoreMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
      return false;
    }
  }

  /// Helper method to toggle master push notifications
  void setNotificationsEnabled(bool value) {
    notificationsEnabled.value = value;
    if (!value) {
      // If master notification is off, disable child switches visually/logically
      swapRequestsEnabled.value = false;
      chatMessagesEnabled.value = false;
      weeklyTipsEnabled.value = false;
      marketingEmailsEnabled.value = false;
      soundEnabled.value = false;
      vibrationEnabled.value = false;
      emailNotifications.value = false;
    } else {
      // Re-enable typical defaults when master is toggled back on
      swapRequestsEnabled.value = true;
      chatMessagesEnabled.value = true;
      weeklyTipsEnabled.value = true;
      soundEnabled.value = true;
      vibrationEnabled.value = true;
    }
    _saveToFirestore();
  }

  /// Update a single notification toggle and persist to Firestore
  Future<bool> updateSetting(ValueNotifier<bool> notifier, bool value) async {
    notifier.value = value;
    return _saveToFirestore();
  }

  /// Expose a stream for realtime updates
  Stream<Map<String, dynamic>>? get notificationSettingsStream {
    final docRef = _settingsDocRef;
    if (docRef == null) return null;
    return docRef.snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      }
      return <String, dynamic>{};
    });
  }

  /// Dispose Firestore subscription
  void disposeNotificationSettings() {
    _settingsSubscription?.cancel();
    _settingsSubscription = null;
    _initialized = false;
  }
}

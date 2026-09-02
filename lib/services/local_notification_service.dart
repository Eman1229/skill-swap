import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notifications that are created and delivered on this device only.
///
/// This service deliberately has no FCM token or server-side sending logic.
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _initialized = false;

  /// Retained for chat screens that suppress alerts while that chat is open.
  static String? currentActiveConversationId;

  static Future<void> init() async {
    if (_initialized || kIsWeb) return;

    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      // The timezone package falls back safely when the device zone is absent.
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleTap,
    );

    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await _createChannels(android);
    _initialized = true;
  }

  static Future<void> _createChannels(
      AndroidFlutterLocalNotificationsPlugin? android) async {
    if (android == null) return;
    const channels = [
      AndroidNotificationChannel(
        'default_channel',
        'Default',
        description: 'General notifications',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'scheduled_channel',
        'Scheduled',
        description: 'Scheduled reminders',
        importance: Importance.high,
      ),
    ];
    for (final channel in channels) {
      await android.createNotificationChannel(channel);
    }
  }

  static Future<void> showNow({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    await plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default',
          channelDescription: 'General notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }

  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await init();
    await plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_channel',
          'Scheduled',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  static Future<void> cancel(int id) => plugin.cancel(id: id);
  static Future<void> cancelAll() => plugin.cancelAll();

  static void _handleTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      if (data['screen'] == 'swapping_available' && data['sessionId'] != null) {
        navigatorKey.currentState?.pushNamed(
          '/swappingAvailable',
          arguments: data['sessionId'],
        );
      }
    } catch (_) {
      // A plain string payload has no route information to handle.
    }
  }
}

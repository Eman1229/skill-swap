import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:skill_swap/services/notification_router.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notifications drawn on this device (heads-up banners and scheduled
/// reminders). Remote delivery lives in PushNotificationService.
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _initialized = false;

  /// Retained for chat screens that suppress alerts while that chat is open.
  static String? currentActiveConversationId;

  /// While backgrounded, the OS already shows the FCM push, so the Firestore
  /// listener must not draw a second copy.
  static bool isAppInForeground = true;

  /// Android channels, keyed by the notification `type` stored in Firestore.
  /// Ids match the channelId the push sender puts in each FCM message.
  static const _channels = <String, AndroidNotificationChannel>{
    'chat_message': AndroidNotificationChannel(
      'chat_message', 'Chat Messages',
      description: 'New messages in your chats', importance: Importance.max),
    'swap_request': AndroidNotificationChannel(
      'swap_request', 'Swap Requests',
      description: 'Skill swap proposals and their updates', importance: Importance.high),
    'session': AndroidNotificationChannel(
      'sessions', 'Mentoring Sessions',
      description: 'Session invites and updates', importance: Importance.high),
    'asset_upload': AndroidNotificationChannel(
      'asset_upload', 'Learning Assets',
      description: 'New course material from your mentor', importance: Importance.high),
    'assignment': AndroidNotificationChannel(
      'assignment', 'Assignments',
      description: 'Assignments and submissions', importance: Importance.high),
    'system': AndroidNotificationChannel(
      'system', 'General',
      description: 'Badges, progress and other updates', importance: Importance.high),
  };

  static AndroidNotificationChannel channelForType(String? type) {
    switch (type) {
      case 'chat_message':
      case 'chat':
        return _channels['chat_message']!;
      case 'swap_request':
      case 'swap':
      case 'completion_request':
        return _channels['swap_request']!;
      case 'session':
        return _channels['session']!;
      case 'asset_upload':
        return _channels['asset_upload']!;
      case 'assignment':
        return _channels['assignment']!;
      default:
        return _channels['system']!;
    }
  }

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
      // Permission is requested by PushNotificationService after sign-in.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) =>
          NotificationRouter.openFromPayload(response.payload),
    );

    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await _createChannels(android);
    _initialized = true;

    // A tap on a local notification can also be what launched the app.
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      NotificationRouter.openFromPayload(launch!.notificationResponse?.payload);
    }
  }

  static Future<void> _createChannels(
      AndroidFlutterLocalNotificationsPlugin? android) async {
    if (android == null) return;
    const extra = [
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
    for (final channel in [..._channels.values, ...extra]) {
      await android.createNotificationChannel(channel);
    }
  }

  static Future<void> requestPermission() async {
    if (kIsWeb) return;
    await init();
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> showNow({
    required String title,
    required String body,
    String? type,
    String? payload,
    int? id,
    String? groupKey,
  }) async {
    if (kIsWeb) return;
    await init();
    final channel = channelForType(type);
    await plugin.show(
      id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: Priority.high,
          groupKey: groupKey,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Shows a Firestore `notifications` document as a system notification.
  static Future<void> showFromNotificationDoc(
      String docId, Map<String, dynamic> doc) async {
    final type = doc['type']?.toString();
    final nested = doc['data'] is Map ? Map<String, dynamic>.from(doc['data']) : <String, dynamic>{};
    final payload = <String, dynamic>{
      ...nested,
      'notificationId': docId,
      'type': type,
      'senderId': doc['senderId'],
      'senderName': doc['senderName'],
      'actionRoute': doc['actionRoute'],
      'actionId': doc['actionId'] ?? doc['relatedId'],
      if (doc['courseId'] != null) 'courseId': doc['courseId'],
      if (doc['assetId'] != null) 'assetId': doc['assetId'],
    }..removeWhere((_, v) => v == null);

    await showNow(
      id: docId.hashCode & 0x7fffffff,
      title: (doc['title'] ?? 'Skill SwapX').toString(),
      body: (doc['body'] ?? doc['message'] ?? 'You have a new notification').toString(),
      type: type,
      groupKey: nested['conversationId']?.toString(),
      payload: jsonEncode(payload, toEncodable: (v) => v.toString()),
    );
  }

  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (kIsWeb) return;
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
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  static Future<void> cancel(int id) => plugin.cancel(id: id);
  static Future<void> cancelAll() => plugin.cancelAll();
}

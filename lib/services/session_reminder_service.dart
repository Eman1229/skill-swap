import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:skill_swap/models/session_model.dart';
import 'package:skill_swap/services/fcm_service.dart';
import 'package:skill_swap/utils/user_display_name.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class SessionReminderService {
  static final SessionReminderService _instance =
      SessionReminderService._internal();
  factory SessionReminderService() => _instance;
  SessionReminderService._internal();

  bool _tzInitialized = false;

  static const String channelId = 'session_reminders';
  static const String channelName = 'Session Reminders';

  FlutterLocalNotificationsPlugin get _localNotifications =>
      FcmService().localNotifications;

  int _id10(String sessionId) => '${sessionId}_10'.hashCode;
  int _id5(String sessionId) => '${sessionId}_5'.hashCode;

  Future<void> init() async {
    await _ensureTimezone();
    await _createChannel();
    await resyncAllAcceptedSessions();
  }

  Future<void> _ensureTimezone() async {
    if (_tzInitialized) return;
    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    _tzInitialized = true;
  }

  Future<void> _createChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Reminders before skill swap sessions start',
      importance: Importance.max,
    );
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(channel);
    await android?.requestExactAlarmsPermission();
  }

  Future<void> scheduleSessionReminder({
    required String sessionId,
    required String swapId,
    required DateTime sessionStartTime,
    required String otherUserName,
  }) async {
    await _ensureTimezone();
    await cancelSessionReminder(sessionId);

    final now = DateTime.now();
    final t10 = sessionStartTime.subtract(const Duration(minutes: 10));
    final t5 = sessionStartTime.subtract(const Duration(minutes: 5));

    if (t10.isAfter(now)) {
      await _scheduleOne(
        id: _id10(sessionId),
        fireAt: t10,
        title: 'Upcoming Skill Swap Session',
        body: 'Your class starts in 10 minutes with $otherUserName.',
        sessionId: sessionId,
        swapId: swapId,
      );
    }

    if (t5.isAfter(now)) {
      await _scheduleOne(
        id: _id5(sessionId),
        fireAt: t5,
        title: 'Session Starting Soon',
        body: 'Your class starts in 5 minutes with $otherUserName.',
        sessionId: sessionId,
        swapId: swapId,
      );
    }

    await FirebaseFirestore.instance
        .collection('swaps')
        .doc(swapId)
        .collection('sessions')
        .doc(sessionId)
        .set({
          'remindersEnabled': true,
          'sessionStartTime': Timestamp.fromDate(sessionStartTime),
          'lastReminderScheduledAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _scheduleOne({
    required int id,
    required DateTime fireAt,
    required String title,
    required String body,
    required String sessionId,
    required String swapId,
  }) async {
    final payload = jsonEncode({
      'type': 'session_reminder',
      'screen': 'swapping_available',
      'sessionId': sessionId,
      'swapId': swapId,
    });

    await _localNotifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<void> cancelSessionReminder(String sessionId) async {
    await _localNotifications.cancel(id: _id10(sessionId));
    await _localNotifications.cancel(id: _id5(sessionId));
  }

  Future<void> disableSessionReminders({
    required String sessionId,
    required String swapId,
  }) async {
    await cancelSessionReminder(sessionId);
    await FirebaseFirestore.instance
        .collection('swaps')
        .doc(swapId)
        .collection('sessions')
        .doc(sessionId)
        .set({'remindersEnabled': false}, SetOptions(merge: true));
  }

  void handleNotificationTap(Map<String, dynamic> data) {
    final screen = data['screen'] as String?;
    final sessionId = data['sessionId'] as String?;

    if (screen != 'swapping_available' || sessionId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmService.navigatorKey.currentState?.pushNamed(
        '/swappingAvailable',
        arguments: sessionId,
      );
    });
  }

  Future<void> resyncAllAcceptedSessions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collectionGroup('sessions')
          .where('participantIds', arrayContains: uid)
          .where('status', isEqualTo: 'accepted')
          .get();

      for (final doc in snap.docs) {
        final session = SessionModel.fromDoc(doc);
        if (session.date.isBefore(DateTime.now())) {
          await cancelSessionReminder(session.id);
          continue;
        }

        final otherName = await resolveOtherUserName(session, uid);
        await scheduleSessionReminder(
          sessionId: session.id,
          swapId: session.swapId,
          sessionStartTime: session.date,
          otherUserName: otherName,
        );
      }
    } catch (e) {
      debugPrint('SessionReminderService resync error: $e');
    }
  }

  // No longer async — names come directly from the session document
  Future<String> resolveOtherUserName(SessionModel session, String uid) async {
    if (uid == session.mentorId) {
      final name = session.learnerName.trim();
      if (UserDisplayName.isUsable(name)) {
        return name;
      }
      final resolved = await UserDisplayName.resolve(
        FirebaseFirestore.instance,
        session.learnerId,
      );
      return UserDisplayName.isUsable(resolved) ? resolved : 'Your student';
    } else {
      final name = session.mentorName.trim();
      if (UserDisplayName.isUsable(name)) {
        return name;
      }
      final resolved = await UserDisplayName.resolve(
        FirebaseFirestore.instance,
        session.mentorId,
      );
      return UserDisplayName.isUsable(resolved) ? resolved : 'Your instructor';
    }
  }

  Future<void> scheduleFromSessionDoc({
    required DocumentSnapshot sessionDoc,
    required String swapId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final session = SessionModel.fromDoc(sessionDoc);
    if (session.status != 'accepted') return;
    if (session.date.isBefore(DateTime.now())) return;

    final otherName = await resolveOtherUserName(session, uid);
    await scheduleSessionReminder(
      sessionId: session.id,
      swapId: swapId,
      sessionStartTime: session.date,
      otherUserName: otherName,
    );
  }
}

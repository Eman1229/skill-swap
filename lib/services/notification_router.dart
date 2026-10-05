import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Chat/conversation_screen.dart';
import 'package:skill_swap/screens/Home Screens/swapping Available.dart';
import 'package:skill_swap/screens/Notifications/notifications_screen.dart';
import 'package:skill_swap/screens/Swap/confirm_swap_completion_screen.dart';
import 'package:skill_swap/screens/Swap/course_assets_screen.dart';
import 'package:skill_swap/services/local_notification_service.dart';
import 'package:skill_swap/services/session_reminder_service.dart';

/// Opens the right screen when a system notification (local or FCM) is tapped.
/// Mirrors the in-app handling in NotificationsScreen._handleNotificationTap.
class NotificationRouter {
  NotificationRouter._();

  // A tap that launches the app arrives while SplashScreen is still deciding
  // where to go; its pushReplacement would discard any screen pushed earlier.
  static bool _ready = false;
  static Map<String, dynamic>? _pending;

  /// Called by SplashScreen once it has navigated away. Pending taps are only
  /// opened when a signed-in user reached the home screen.
  static void markReady({bool openPending = true}) {
    _ready = true;
    final pending = _pending;
    _pending = null;
    if (openPending && pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => open(pending));
    }
  }

  static void openFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) open(Map<String, dynamic>.from(decoded));
    } catch (_) {
      // A plain string payload has no route information to handle.
    }
  }

  static void open(Map<String, dynamic> raw) {
    if (!_ready) {
      _pending = raw;
      return;
    }
    final data = _flatten(raw);
    if (data['type'] == 'session_reminder' || data['screen'] == 'swapping_available') {
      SessionReminderService().handleNotificationTap(data);
      return;
    }
    // The navigator may not exist yet when the app was launched by the tap.
    _whenNavigatorReady((nav) => nav.push(MaterialPageRoute(builder: (_) => _screenFor(data))));
  }

  static Widget _screenFor(Map<String, dynamic> data) {
    final type = _str(data['type']);
    final actionId = _str(data['actionId']).isNotEmpty
        ? _str(data['actionId'])
        : _str(data['relatedId']);

    if (type == 'asset_upload') {
      final courseId = _str(data['courseId']).isNotEmpty ? _str(data['courseId']) : _str(data['swapId']);
      if (courseId.isNotEmpty) {
        return CourseAssetsScreen(
          courseId: courseId,
          highlightedAssetId: _str(data['assetId']).isNotEmpty ? _str(data['assetId']) : actionId,
        );
      }
    }

    if (data['actionRoute'] == '/confirm_completion' || type == 'completion_request') {
      return ConfirmSwapCompletionScreen(swapId: actionId.isNotEmpty ? actionId : _str(data['swapId']));
    }

    final convoId = _str(data['conversationId']).isNotEmpty ? _str(data['conversationId']) : actionId;
    final otherUid = _str(data['otherUserId']).isNotEmpty ? _str(data['otherUserId']) : _str(data['senderId']);
    final otherName = _str(data['senderName']).isNotEmpty
        ? _str(data['senderName'])
        : (_str(data['otherName']).isNotEmpty ? _str(data['otherName']) : 'Chat');

    if ((type == 'chat_message' || type == 'session' || type == 'swap_request') &&
        convoId.isNotEmpty &&
        otherUid.isNotEmpty) {
      return ConversationScreen(
        swap: SwapListing(
          id: convoId,
          userId: otherUid,
          name: otherName,
          initials: otherName[0],
          avatarColor: const Color(0xFF6B8AFF),
          offering: '',
          wanting: '',
          rating: 0.0,
          reviews: 0,
          category: 'All',
        ),
      );
    }

    return const NotificationsScreen();
  }

  /// FCM data arrives flat; Firestore notification docs keep extras under `data`.
  static Map<String, dynamic> _flatten(Map<String, dynamic> raw) {
    final nested = raw['data'];
    final result = <String, dynamic>{};
    if (nested is Map) result.addAll(Map<String, dynamic>.from(nested));
    raw.forEach((key, value) {
      if (key != 'data' && value != null && _str(value).isNotEmpty) result[key] = value;
    });
    return result;
  }

  static String _str(Object? value) => value?.toString().trim() ?? '';

  static void _whenNavigatorReady(void Function(NavigatorState nav) action, [int attempt = 0]) {
    final nav = LocalNotificationService.navigatorKey.currentState;
    if (nav != null) {
      action(nav);
    } else if (attempt < 20) {
      Future.delayed(const Duration(milliseconds: 250), () => _whenNavigatorReady(action, attempt + 1));
    }
  }
}

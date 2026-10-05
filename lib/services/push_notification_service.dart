import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_swap/services/local_notification_service.dart';
import 'package:skill_swap/services/notification_router.dart';
import 'package:skill_swap/services/session_reminder_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

/// Runs in a separate isolate when a push arrives while the app is in the
/// background or killed. Every message we send carries a `notification`
/// block, which Android/iOS display on their own, so nothing to do here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Free push pipeline (no Firebase Blaze plan needed):
///
///  1. Each device saves its FCM token to users/{uid}/deviceTokens/{token}.
///  2. Whoever creates a doc in `notifications` calls [dispatch] with its id.
///  3. The Supabase Edge Function `send-push` (supabase/functions/send-push)
///     checks the caller, reads the doc and the receiver's tokens, and sends
///     the push through the FCM HTTP v1 API.
///
/// While the app is open, NotificationProvider shows the banner from the
/// Firestore listener instead, so foreground FCM messages are ignored.
class PushNotificationService {
  PushNotificationService._();

  static const String edgeFunctionName = 'send-push';

  static bool _initialized = false;
  static String? _registeredUid;
  static String? _currentToken;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> init() async {
    if (_initialized || !_supported) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    // On iOS, show nothing from FCM in the foreground; the Firestore listener
    // already does that and would otherwise duplicate the banner.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    FirebaseMessaging.onMessageOpenedApp
        .listen((message) => NotificationRouter.open(message.data));
    unawaited(messaging.getInitialMessage().then((message) {
      if (message != null) NotificationRouter.open(message.data);
    }));

    messaging.onTokenRefresh.listen((token) => _saveToken(token));

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && user.uid != _registeredUid) {
        unawaited(_registerDevice(user));
      } else if (user == null) {
        _registeredUid = null;
      }
    });
  }

  static Future<void> _registerDevice(User user) async {
    _registeredUid = user.uid;
    try {
      await LocalNotificationService.requestPermission();
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('PushNotificationService: permission denied');
        return;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          await FirebaseMessaging.instance.getAPNSToken() == null) {
        // No APNs key uploaded in Firebase (needs a paid Apple account);
        // iOS then only gets in-app/local notifications.
        debugPrint('PushNotificationService: no APNs token, skipping FCM on iOS');
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      debugPrint('PushNotificationService: token registration failed: $e');
    }
    unawaited(SessionReminderService().init());
  }

  static Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || token.isEmpty) return;
    _currentToken = token;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final batch = FirebaseFirestore.instance.batch();
    batch.set(userRef.collection('deviceTokens').doc(token), {
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(userRef, {
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
    debugPrint('PushNotificationService: FCM token saved for $uid');
  }

  /// Call BEFORE FirebaseAuth.signOut() so this device stops receiving the
  /// previous user's pushes (Firestore rules need the user still signed in).
  static Future<void> unregister() async {
    if (!_supported) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      final token = _currentToken ?? await FirebaseMessaging.instance.getToken();
      if (uid != null && token != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        await userRef.collection('deviceTokens').doc(token).delete();
        final userDoc = await userRef.get();
        if (userDoc.data()?['fcmToken'] == token) {
          await userRef.update({'fcmToken': FieldValue.delete()});
        }
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('PushNotificationService: unregister failed: $e');
    }
    _currentToken = null;
    _registeredUid = null;
  }

  /// Sends the push for an already-written `notifications/{id}` document.
  /// Never throws: the in-app notification exists either way.
  static Future<void> dispatch(String notificationId) async {
    if (notificationId.isEmpty) return;
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;
      final response = await Supabase.instance.client.functions.invoke(
        edgeFunctionName,
        headers: {'x-firebase-token': idToken},
        body: {'notificationId': notificationId},
      );
      debugPrint('PushNotificationService: dispatch $notificationId -> ${response.data}');
    } catch (e) {
      debugPrint('PushNotificationService: dispatch $notificationId failed: $e');
    }
  }

  /// Fire-and-forget variant for call sites that should not wait on the network.
  static void dispatchAll(Iterable<String> notificationIds) {
    for (final id in notificationIds) {
      unawaited(dispatch(id));
    }
  }
}

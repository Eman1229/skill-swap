import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/screens/Chat/conversation_screen.dart';
import 'package:skill_swap/screens/Home Screens/swapping Available.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background/terminated state messages here if needed.
  print("Background FCM message received: ${message.messageId}");
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // 1. Request iOS / Android permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted push notification permission.");
    }

    // Explicit notification permission request for Android 13+
    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      print("Error requesting Android 13+ notification permissions: $e");
    }

    // 2. Initialize local notifications for foreground popups
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iOSInit,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final Map<String, dynamic> data = jsonDecode(response.payload!);
          _handleNotificationClick(data);
        }
      },
    );

    // Create high-importance notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for incoming SkillSwapX chat messages.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Register Top-level Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handle notification tap when app is completely terminated and opened
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage.data);
    }

    // 5. Handle notification tap when app is in background but alive
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.data);
    });

    // 6. Handle foreground messages (app is actively open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      String? title = notification?.title;
      String? body = notification?.body;

      // Handle data-only messages when foreground
      if (title == null && body == null && message.data.isNotEmpty) {
        title = message.data['title'] as String?;
        body = message.data['body'] as String?;
      }

      if (title != null && body != null) {
        // Show a local notification alert using strictly named parameters
        _localNotifications.show(
          id: message.hashCode,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // Listen to Firebase Auth state changes to dynamically save device tokens
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        saveDeviceToken();
      }
    });

    _initialized = true;
    
    // Register FCM Token for currently logged-in user if any
    await saveDeviceToken();
  }

  // Updates current user's FCM token in Firestore
  Future<void> saveDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print("FCM Device Token updated: $token");
      }
    } catch (e) {
      print("Error registering FCM token: $e");
    }
  }

  // De-registers token (call on sign out)
  Future<void> removeDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
      });
      print("FCM Token cleared.");
    } catch (e) {
      print("Error removing FCM token: $e");
    }
  }

  // Handles navigation on tapping the notification
  void _handleNotificationClick(Map<String, dynamic> data) {
    final String conversationId = data['conversationId'] ?? '';
    final String otherUserId = data['otherUserId'] ?? '';
    final String otherName = data['otherName'] ?? 'Chat';
    final String imageUrl = data['imageUrl'] ?? '';
    final String offering = data['offering'] ?? '';
    final String wanting = data['wanting'] ?? '';

    if (conversationId.isEmpty || otherUserId.isEmpty) return;

    final swap = SwapListing(
      id: conversationId,
      userId: otherUserId,
      name: otherName,
      initials: otherName.trim().split(' ').length >= 2
          ? '${otherName.trim().split(' ')[0][0]}${otherName.trim().split(' ')[1][0]}'.toUpperCase()
          : (otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U'),
      avatarColor: const Color(0xFF6B8AFF),
      offering: offering,
      wanting: wanting,
      rating: 0.0,
      reviews: 0,
      category: 'All',
      imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
    );

    // Wait a brief frame to make sure navigation context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ConversationScreen(swap: swap),
        ),
      );
    });
  }
}

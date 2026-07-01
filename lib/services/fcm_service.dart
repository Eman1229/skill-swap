import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/screens/Chat/conversation_screen.dart';
import 'package:skill_swap/screens/Home Screens/swapping Available.dart';
import 'package:skill_swap/screens/Notifications/notifications_screen.dart';
import 'package:skill_swap/models/notification_settings.dart';
import 'package:skill_swap/screens/Swap/confirm_swap_completion_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background FCM received: ${message.messageId}");
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  String? currentActiveConvoId;
  final DateTime _listenerStartTime = DateTime.now();
  final Set<String> _shownNotificationIds = {};

  Future<void> init() async {
    if (_initialized) return;

    // 1. Initial Logic for permissions
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // 2. Initialize local notifications
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iOSInit);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse res) {
        if (res.payload != null) {
          _handleNotificationClick(jsonDecode(res.payload!));
        }
      },
    );

    // Channels
    _createChannels();

    // 3. Listeners
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Foreground
    FirebaseMessaging.onMessage.listen((msg) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Suppress if user is currently looking at this active conversation
      final String? convoId = msg.data['conversationId'] ?? msg.data['data']?['conversationId'];
      if (convoId != null && convoId == currentActiveConvoId) {
        debugPrint("FCM Service: Suppressed foreground notification for active chat $convoId");
        return;
      }

      // Deduplicate if already shown
      if (msg.messageId != null && _shownNotificationIds.contains(msg.messageId)) {
        return;
      }
      if (msg.messageId != null) {
        _shownNotificationIds.add(msg.messageId!);
      }

      // Fetch settings
      final settingsDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('notifications')
          .get();
      
      final settings = NotificationSettingsModel.fromDoc(settingsDoc);

      if (!settings.pushEnabled) return;

      final type = msg.data['type'] as String?;
      if (type == 'chat_message' && !settings.directMessagesEnabled) return;
      if (type == 'swap_request' && !settings.swapProposalEnabled) return;

      _showLocalNotification(msg, settings);
    });

    // Interaction listeners
    FirebaseMessaging.onMessageOpenedApp.listen((msg) => _handleNotificationClick(msg.data));
    
    _fcm.getInitialMessage().then((msg) {
      if (msg != null) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handleNotificationClick(msg.data);
        });
      }
    });

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) saveDeviceToken();
    });

    _initialized = true;
    saveDeviceToken();
    _startNotificationsListener();
  }

  void _startNotificationsListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          
          // Deduplicate if already processed
          if (_shownNotificationIds.contains(change.doc.id)) {
            continue;
          }

          // Filter out historic notifications during startup to prevent initial-burst spam
          final createdAtField = data['createdAt'];
          DateTime? createdAt;
          if (createdAtField is Timestamp) {
            createdAt = createdAtField.toDate();
          } else if (createdAtField is String) {
            createdAt = DateTime.tryParse(createdAtField);
          }
          createdAt ??= DateTime.now();

          // Only alert if created after initialization (with a small 2s grace window)
          if (createdAt.isAfter(_listenerStartTime.subtract(const Duration(seconds: 2)))) {
            _shownNotificationIds.add(change.doc.id);
            _showLocalNotificationFromMap(change.doc.id, data);
          }
        }
      }
    });
  }

  void _showLocalNotificationFromMap(String docId, Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Suppress if actively viewing chat room
    final String? convoId = data['conversationId'] ?? data['data']?['conversationId'];
    if (convoId != null && convoId == currentActiveConvoId) {
      debugPrint("FCM Service: Suppressed Firestore-triggered notification for active chat $convoId");
      return;
    }

    final settingsDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .get();
    
    final settings = NotificationSettingsModel.fromDoc(settingsDoc);
    if (!settings.pushEnabled) return;

    final type = data['type'] as String?;
    if (type == 'chat_message' && !settings.directMessagesEnabled) return;
    if (type == 'swap_request' && !settings.swapProposalEnabled) return;

    String title = data['title'] ?? 'Skill Swap';
    String body = data['body'] ?? '';
    
    if (data['type'] == 'chat_message' && (data['senderName'] != null || data['otherName'] != null)) {
      title = data['senderName'] ?? data['otherName'];
    }

    String channelId = _getChannelId(type);

    _localNotifications.show(
      id: docId.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId.replaceAll('_', ' ').toUpperCase(),
          importance: settings.soundEnabled ? Importance.max : Importance.low,
          priority: Priority.high,
          playSound: settings.soundEnabled,
          enableVibration: settings.vibrationEnabled,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  void _createChannels() async {
    final List<AndroidNotificationChannel> channels = [
      const AndroidNotificationChannel('chat_messages', 'Chat Messages', importance: Importance.max),
      const AndroidNotificationChannel('swap_requests', 'Swap Proposals', importance: Importance.high),
      const AndroidNotificationChannel('sessions', 'Mentoring Sessions', importance: Importance.high),
      const AndroidNotificationChannel('system', 'System Announcements', importance: Importance.defaultImportance),
    ];

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      for (final channel in channels) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }
  }

  void _showLocalNotification(RemoteMessage msg, NotificationSettingsModel settings) {
    RemoteNotification? notification = msg.notification;
    String title = notification?.title ?? msg.data['title'] ?? 'Skill Swap';
    String body = notification?.body ?? msg.data['body'] ?? '';
    String channelId = _getChannelId(msg.data['type']);

    _localNotifications.show(
      id: msg.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId.replaceAll('_', ' ').toUpperCase(),
          importance: settings.soundEnabled ? Importance.max : Importance.low,
          priority: Priority.high,
          playSound: settings.soundEnabled,
          enableVibration: settings.vibrationEnabled,
        ),
      ),
      payload: jsonEncode(msg.data),
    );
  }

  String _getChannelId(String? type) {
    switch (type) {
      case 'chat_message': return 'chat_messages';
      case 'swap_request': return 'swap_requests';
      case 'session': return 'sessions';
      case 'system': return 'system';
      default: return 'chat_messages';
    }
  }

  Future<void> saveDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String? token = await _fcm.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final actionRoute = data['actionRoute'] as String?;
    final swapId = data['actionId'] ?? data['swapId'] ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (actionRoute == '/confirm_completion' || type == 'completion_request') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ConfirmSwapCompletionScreen(swapId: swapId),
          ),
        );
      } else if (type == 'chat_message' || type == 'session' || type == 'swap_request') {
        _openChat(data);
      } else {
        navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      }
    });
  }

  void _openChat(Map<String, dynamic> data) {
    Map<String, dynamic> nestedData = {};
    if (data['data'] is Map) {
      nestedData = Map<String, dynamic>.from(data['data']);
    } else if (data['data'] is String) {
      try {
        nestedData = jsonDecode(data['data']);
      } catch (_) {}
    }

    final String conversationId = data['conversationId'] ?? data['referenceId'] ?? data['actionId'] ?? nestedData['conversationId'] ?? '';
    final String otherUserId = data['otherUserId'] ?? data['senderId'] ?? nestedData['senderId'] ?? '';
    final String otherName = data['otherName'] ?? data['senderName'] ?? nestedData['senderName'] ?? 'Chat';

    if (conversationId.isEmpty) {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      return;
    }

    final swap = SwapListing(
      id: conversationId,
      userId: otherUserId,
      name: otherName,
      initials: otherName.isNotEmpty ? otherName[0] : 'U',
      avatarColor: const Color(0xFF6B8AFF),
      offering: data['offering'] ?? nestedData['offering'] ?? '',
      wanting: data['wanting'] ?? nestedData['wanting'] ?? '',
      rating: 0.0, reviews: 0, category: 'All',
    );

    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => ConversationScreen(swap: swap)));
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/services/local_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot>? _unreadSubscription;
  StreamSubscription<User?>? _authSubscription;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  NotificationProvider() {
    _authSubscription = _auth.authStateChanges().listen(_onAuthChanged);
    _onAuthChanged(_auth.currentUser);
  }

  void _onAuthChanged(User? user) {
    _unreadSubscription?.cancel();
    _unreadSubscription = null;

    if (user == null) {
      _unreadCount = 0;
      notifyListeners();
      return;
    }

    bool isFirstFetch = true;

    _unreadSubscription = _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen(
      (snapshot) {
        // The first snapshot is the existing backlog, not new events.
        if (!isFirstFetch) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              _maybeShowBanner(user.uid, change.doc.id, change.doc.data() ?? {});
            }
          }
        }
        isFirstFetch = false;

        _unreadCount = snapshot.docs.length;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('NotificationProvider stream error: $e');
      },
    );
  }

  final Set<String> _shownIds = {};

  Future<void> _maybeShowBanner(
      String uid, String docId, Map<String, dynamic> data) async {
    // In the background the FCM push (sent by PushNotificationService.dispatch)
    // is already on screen.
    if (!LocalNotificationService.isAppInForeground) return;
    if (!_shownIds.add(docId)) return;
    // With offline persistence the first snapshot can come from cache, and
    // docs that arrived while the app was closed then show up as "added".
    // Those were already delivered by FCM.
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp &&
        DateTime.now().difference(createdAt.toDate()) > const Duration(minutes: 2)) {
      return;
    }

    final type = data['type']?.toString();
    final nested = data['data'] is Map ? data['data'] as Map : const {};
    final convoId = (nested['conversationId'] ?? data['actionId'])?.toString();
    final isChat = type == 'chat_message' || type == 'chat';
    if (isChat && convoId != null &&
        convoId == LocalNotificationService.currentActiveConversationId) {
      return;
    }

    try {
      final settings = (await _firestore
              .collection('users').doc(uid)
              .collection('settings').doc('notifications')
              .get())
          .data() ?? const {};
      if (settings['pushEnabled'] == false) return;
      if (isChat && (settings['chatMessagesEnabled'] == false ||
          settings['directMessagesEnabled'] == false ||
          settings['chatNotificationsMuted'] == true)) {
        return;
      }
      if (type == 'swap_request' && settings['swapRequestsEnabled'] == false) return;
      if (isChat && convoId != null && convoId.isNotEmpty) {
        final convo = await _firestore.collection('conversations').doc(convoId).get();
        final muted = convo.data()?['muted'];
        if (muted is Map && muted[uid] == true) return;
      }
    } catch (e) {
      debugPrint('NotificationProvider: settings check failed, showing anyway: $e');
    }

    await LocalNotificationService.showFromNotificationDoc(docId, data);
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'read': true, // backward compat
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications for the current user as read
  Future<void> markAllAsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final batch = _firestore.batch();

      // Query with new field name
      final newFieldDocs = await _firestore
          .collection('notifications')
          .where('receiverId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in newFieldDocs.docs) {
        batch.update(doc.reference, {'isRead': true, 'read': true});
      }

      // Query with old field name for backward compat
      final oldFieldDocs = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .get();

      for (final doc in oldFieldDocs.docs) {
        batch.update(doc.reference, {'isRead': true, 'read': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete a single notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Clear all notifications for the current user
  Future<void> clearAll() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final batch = _firestore.batch();

      // Delete using new field name
      final newFieldDocs = await _firestore
          .collection('notifications')
          .where('receiverId', isEqualTo: uid)
          .get();

      for (final doc in newFieldDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete using old field name for backward compat
      final oldFieldDocs = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .get();

      for (final doc in oldFieldDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}

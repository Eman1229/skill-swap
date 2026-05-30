import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap/models/notification_settings.dart';
import 'package:skill_swap/models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── SETTINGS ────────────────────────────────────────────────────────

  Stream<NotificationSettingsModel> settingsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(NotificationSettingsModel());

    return _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .snapshots()
        .map((doc) => NotificationSettingsModel.fromDoc(doc));
  }

  Future<void> updateSettings(NotificationSettingsModel settings) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .set(settings.toMap(), SetOptions(merge: true));
  }

  // ── NOTIFICATIONS ───────────────────────────────────────────────────

  Stream<List<NotificationModel>> notificationsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint("Notification Repo: UID is null, returning empty stream");
      return Stream.value([]);
    }

    debugPrint("Notification Repo: Attaching listener for user $uid");

    return _db
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .handleError((error) {
          debugPrint("Notification Repo: Stream error caught: $error");
        })
        .map((snap) {
          debugPrint("Notification Repo: Received snapshot with ${snap.docs.length} docs");
          final list = <NotificationModel>[];
          for (var doc in snap.docs) {
            try {
              list.add(NotificationModel.fromDoc(doc));
            } catch (e) {
              debugPrint("Notification Repo: Error parsing doc ${doc.id}: $e");
              // Continue processing rather than rethrowing and crashing the entire stream
            }
          }
          return list;
        });
  }

  Stream<int> unreadCountStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _db
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({
          'isRead': true,
          'read': true, // backward compat
        });
  }

  Future<void> markAllAsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final batch = _db.batch();
      
      // Query with new field name
      final newFieldDocs = await _db
          .collection('notifications')
          .where('receiverId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in newFieldDocs.docs) {
        batch.update(doc.reference, {'isRead': true, 'read': true});
      }

      // Query with old field name for backward compat
      final oldFieldDocs = await _db
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in oldFieldDocs.docs) {
        batch.update(doc.reference, {'isRead': true, 'read': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Notification Repo: Error marking all as read: $e");
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }

  Future<void> clearAll() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final batch = _db.batch();
      
      // Query using new receiverId field
      final newFieldDocs = await _db
          .collection('notifications')
          .where('receiverId', isEqualTo: uid)
          .get();

      for (var doc in newFieldDocs.docs) {
        batch.delete(doc.reference);
      }

      // Query using old recipientId field for backward compat
      final oldFieldDocs = await _db
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .get();

      for (var doc in oldFieldDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Notification Repo: Error clearing all: $e");
    }
  }
}

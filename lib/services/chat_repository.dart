import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/models/message.dart';
import 'package:skill_swap/models/conversation.dart';
import 'package:flutter/foundation.dart';

class ChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of the current user's conversations, sorted by latest message timestamp.
  Stream<List<Conversation>> conversationsStream() {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return const Stream.empty();
    
    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
          final convos = snap.docs
            .map((doc) => Conversation.fromMap(doc.id, doc.data()))
            .toList();
          
          // Sort in-memory to avoid composite index requirements for simple queries
          convos.sort((a, b) {
            final aTime = a.lastMessageAt;
            final bTime = b.lastMessageAt;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          
          return convos;
        });
  }

  /// Stream of messages for a given conversation, ordered chronologically.
  Stream<List<ChatMessage>> messagesStream(String conversationId, {int limit = 20}) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
            .toList()
            .reversed
            .toList()); // newest first -> reverse to chronological
  }

  /// Sends a message and updates conversation meta.
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required String type, // 'text', 'image', etc.
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    
    final batch = _db.batch();
    final convoRef = _db.collection('conversations').doc(conversationId);
    
    // Add message
    final msgRef = convoRef.collection('messages').doc();
    final msg = ChatMessage(
      id: msgRef.id,
      senderId: uid,
      text: text,
      timestamp: Timestamp.now(),
      status: MessageStatus.sent,
      type: type,
    );
    batch.set(msgRef, msg.toMap());
    
    // Update conversation meta
    batch.update(convoRef, {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount.$uid': 0, // Reset self unread
    });
    
    // Increment unread for other participants
    final convoSnap = await convoRef.get();
    final participants = List<String>.from(convoSnap.data()?['participants'] ?? []);
    for (final p in participants) {
      if (p != uid) {
        batch.update(convoRef, {'unreadCount.$p': FieldValue.increment(1)});
      }
    }
    
    await batch.commit();

    // ── NOTIFICATION ──────────────────────────────────────────────────
    final otherUid = participants.firstWhere((p) => p != uid, orElse: () => '');
    if (otherUid.isNotEmpty) {
      String senderName = _auth.currentUser?.displayName ?? 'Someone';
      String senderProfilePic = _auth.currentUser?.photoURL ?? '';
      
      try {
        final senderDoc = await _db.collection('users').doc(uid).get();
        if (senderDoc.exists) {
          final sData = senderDoc.data();
          if (sData?['name'] != null && sData!['name'].toString().isNotEmpty) {
            senderName = sData['name'];
          }
          if (sData?['imageUrl'] != null && sData!['imageUrl'].toString().isNotEmpty) {
            senderProfilePic = sData['imageUrl'];
          }
        }
      } catch (e) {
        debugPrint("Error fetching sender details for notification: $e");
      }

      await _db.collection('notifications').add({
        'senderId': uid,
        'senderName': senderName,
        'senderProfilePic': senderProfilePic,
        'receiverId': otherUid,
        'type': 'chat_message',
        'title': senderName,
        'body': text,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'actionRoute': '/chat',
        'actionId': conversationId,
        'imageUrl': senderProfilePic,
        'data': {
          'conversationId': conversationId,
          'otherUserId': uid,
          'otherName': senderName,
          'senderProfilePic': senderProfilePic,
          'type': 'chat_message',
        },
      });
    }
  }

  /// Marks messages as delivered for the current user in a conversation.
  Future<void> markMessagesAsDelivered(String conversationId) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final query = await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: uid)
        .where('status', isEqualTo: 'sent')
        .limit(50)
        .get();

    if (query.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'status': 'delivered'});
    }
    await batch.commit();
  }

  /// Marks all messages as read for the current user in a conversation.
  Future<void> markAllAsRead(String conversationId) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final batch = _db.batch();
    
    // 1. Reset unread count for current user
    batch.update(_db.collection('conversations').doc(conversationId), {
      'unreadCount.$uid': 0,
    });

    // 2. Mark incoming messages as read
    final query = await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: uid)
        .where('status', isNotEqualTo: 'read')
        .limit(50)
        .get();

    for (final doc in query.docs) {
      batch.update(doc.reference, {'status': 'read'});
    }

    await batch.commit();
  }

  /// Marks all conversations as read for the current user.
  Future<void> markAllConversationsAsRead() async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final convosQuery = await _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .get();

    final batch = _db.batch();
    bool hasUpdates = false;

    for (final doc in convosQuery.docs) {
      final rawUnread = doc.data()['unreadCount'];
      if (rawUnread is Map) {
        final currentUnread = rawUnread[uid] ?? 0;
        if (currentUnread > 0) {
          batch.update(doc.reference, {
            'unreadCount.$uid': 0,
          });
          hasUpdates = true;
        }
      } else if (rawUnread is int && rawUnread > 0) {
        batch.update(doc.reference, {
          'unreadCount': 0,
        });
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      await batch.commit();
    }

    // Also update any pending notification documents in the notifications collection for this user!
    final notificationsQuery = await _db
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .where('type', isEqualTo: 'chat_message')
        .where('isRead', isEqualTo: false)
        .get();

    if (notificationsQuery.docs.isNotEmpty) {
      final notifBatch = _db.batch();
      for (final doc in notificationsQuery.docs) {
        notifBatch.update(doc.reference, {'isRead': true});
      }
      await notifBatch.commit();
    }
  }

  /// Clears all chat conversations and messages for the current user.
  Future<void> clearAllConversations() async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final convosQuery = await _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .get();

    for (final doc in convosQuery.docs) {
      final convoId = doc.id;
      final messagesQuery = await _db
          .collection('conversations')
          .doc(convoId)
          .collection('messages')
          .get();

      final batch = _db.batch();
      for (final msgDoc in messagesQuery.docs) {
        batch.delete(msgDoc.reference);
      }
      batch.delete(doc.reference);
      await batch.commit();
    }

    // Clear notifications of type 'chat_message'
    final notificationsQuery = await _db
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .where('type', isEqualTo: 'chat_message')
        .get();

    if (notificationsQuery.docs.isNotEmpty) {
      final notifBatch = _db.batch();
      for (final doc in notificationsQuery.docs) {
        notifBatch.delete(doc.reference);
      }
      await notifBatch.commit();
    }

    final sentNotificationsQuery = await _db
        .collection('notifications')
        .where('senderId', isEqualTo: uid)
        .where('type', isEqualTo: 'chat_message')
        .get();

    if (sentNotificationsQuery.docs.isNotEmpty) {
      final sentNotifBatch = _db.batch();
      for (final doc in sentNotificationsQuery.docs) {
        sentNotifBatch.delete(doc.reference);
      }
      await sentNotifBatch.commit();
    }
  }
}


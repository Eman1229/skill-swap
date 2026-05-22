import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/models/message.dart';
import 'package:skill_swap/models/conversation.dart';

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
}

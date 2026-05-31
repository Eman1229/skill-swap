import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MessageSyncService {
  static final MessageSyncService _instance = MessageSyncService._internal();
  factory MessageSyncService() => _instance;
  MessageSyncService._internal();

  /// Marks all unread, undelivered messages sent to the [currentUid] as DELIVERED.
  /// Typically called on app launch, or when the inbox renders.
  Future<void> markIncomingMessagesAsDelivered(String currentUid) async {
    try {
      final conversationsSnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: currentUid)
          .get();

      for (var convDoc in conversationsSnapshot.docs) {
        final messagesSnapshot = await convDoc.reference
            .collection('messages')
            .where('receiverId', isEqualTo: currentUid)
            .where('isDelivered', isNotEqualTo: true)
            .get();

        if (messagesSnapshot.docs.isNotEmpty) {
          final batch = FirebaseFirestore.instance.batch();
          for (var msgDoc in messagesSnapshot.docs) {
            batch.update(msgDoc.reference, {
              'isDelivered': true,
              'deliveredAt': FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();
          debugPrint("Synced ${messagesSnapshot.docs.length} messages to DELIVERED in conversation: ${convDoc.id}");
        }
      }
    } catch (e) {
      debugPrint("Error syncing delivery status: $e");
    }
  }

  /// Marks all messages inside a specific [conversationId] sent by the partner (i.e. not [currentUid]) as SEEN.
  /// Called when the active user enters the chat room.
  Future<void> markConversationMessagesAsSeen(String conversationId, String currentUid) async {
    try {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUid)
          .where('isSeen', isNotEqualTo: true)
          .get();

      if (messagesSnapshot.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var msgDoc in messagesSnapshot.docs) {
          batch.update(msgDoc.reference, {
            'isSeen': true,
            'seenAt': FieldValue.serverTimestamp(),
            'isDelivered': true, // Naturally seen implies delivered
            'deliveredAt': msgDoc.get('deliveredAt') ?? FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
        debugPrint("Synced ${messagesSnapshot.docs.length} messages to SEEN in conversation: $conversationId");
      }
    } catch (e) {
      debugPrint("Error marking conversation as seen: $e");
    }
  }
}

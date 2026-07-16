import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/models/swap_request.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_swap/services/skill_exchange_service.dart';

class SwapRequestRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SkillExchangeService _exchangeService = SkillExchangeService();

  /// Checks if a pending or accepted request already exists between two users
  Future<SwapRequest?> checkExistingRequest(String otherUserId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final query = await _db
        .collection('swap_requests')
        .where('participants', arrayContains: uid)
        .get();

    for (var doc in query.docs) {
      final request = SwapRequest.fromDoc(doc);
      if ((request.senderId == uid && request.receiverId == otherUserId) ||
          (request.senderId == otherUserId && request.receiverId == uid)) {
        if (request.status == SwapRequestStatus.pending ||
            request.status == SwapRequestStatus.accepted) {
          return request;
        }
      }
    }
    return null;
  }

  /// Sends a new swap request
  Future<void> sendRequest({
    required String receiverId,
    required String receiverName,
    required String offeredSkill,
    required String requestedSkill,
    required String conversationId,
  }) async {
    final uid = _auth.currentUser?.uid;
    final senderName = _auth.currentUser?.displayName ?? 'User';
    if (uid == null) return;

    if (uid == receiverId) {
      throw Exception('You cannot send a swap request to yourself.');
    }
    if (offeredSkill.trim().isEmpty || requestedSkill.trim().isEmpty) {
      throw Exception('A swap requires one skill to teach and one skill to learn.');
    }

    // 1. Double check for duplicates
    final existing = await checkExistingRequest(receiverId);
    if (existing != null) {
      throw Exception('A ${existing.status.name} request already exists.');
    }

    final batch = _db.batch();

    // 2. Create the request document
    final requestRef = _db.collection('swap_requests').doc();
    final requestData = {
      'senderId': uid,
      'receiverId': receiverId,
      'senderName': senderName,
      'receiverName': receiverName,
      'offeredSkill': offeredSkill,
      'requestedSkill': requestedSkill,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'conversationId': conversationId,
      'participants': [uid, receiverId],
    };
    batch.set(requestRef, requestData);
    debugPrint('Creating swap request ${requestRef.id} for $receiverId');

    // 3. Add a message to the conversation
    if (conversationId.isNotEmpty) {
      final msgRef = _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();
      
      batch.set(msgRef, {
        'senderId': uid,
        'text': 'I sent you a skill swap request!',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'swap_request',
        'requestId': requestRef.id,
        'status': 'sent',
      });

      // Update conversation last message
      batch.update(_db.collection('conversations').doc(conversationId), {
        'lastMessage': 'Skill Swap Request',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    // 4. Send Push Notification
    await _sendPushNotification(
      receiverId: receiverId,
      title:'new_swap_request_title'.tr(),
      body: '$senderName sent you a skill swap request.',
      data: {
        'type': 'swap_request',
        'requestId': requestRef.id,
        'conversationId': conversationId,
        'senderId': uid,
        'senderName': senderName,
      },
    );
  }

  /// Updates the status of a swap request
  Future<void> updateRequestStatus(String requestId, SwapRequestStatus status) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final requestRef = _db.collection('swap_requests').doc(requestId);
    final doc = await requestRef.get();
    if (!doc.exists) return;
    
    final request = SwapRequest.fromDoc(doc);
    if (request.status != SwapRequestStatus.pending) {
      throw Exception('This request is already ${request.status.name}.');
    }
    if (status == SwapRequestStatus.accepted &&
        (request.offeredSkill.trim().isEmpty || request.requestedSkill.trim().isEmpty)) {
      throw Exception('A skill swap must include one offered and one requested skill.');
    }

    final batch = _db.batch();

    batch.update(requestRef, {
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final String offeredSkill = request.offeredSkill;
    final String targetUserId = uid == request.senderId ? request.receiverId : request.senderId;
    final String myName = _auth.currentUser?.displayName ?? 'Someone';
    await batch.commit();

    if (status == SwapRequestStatus.accepted) {
      await _exchangeService.createMissingSwapPairFromRequest(
        requestId: requestId,
        request: {
          'senderId': request.senderId,
          'receiverId': request.receiverId,
          'senderName': request.senderName,
          'receiverName': request.receiverName,
          'offeredSkill': request.offeredSkill,
          'requestedSkill': request.requestedSkill,
          'conversationId': request.conversationId,
        },
      );
    } else if (status == SwapRequestStatus.rejected ||
        status == SwapRequestStatus.cancelled) {
      await _exchangeService.syncParticipants([request.senderId, request.receiverId]);
    }

    // Notify the other user of status change
    final statusText = status.name.toLowerCase();
    
    await _sendPushNotification(
      receiverId: targetUserId,
      title: status == SwapRequestStatus.accepted ? 'Swap Accepted! 🎉' : 'Swap Request Update',
      body: '$myName $statusText your request for "$offeredSkill".',
      data: {
        'type': 'swap_request',
        'requestId': requestId,
        'status': status.name,
        'conversationId': request.conversationId,
      },
    );
  }

  /// Sends push notification to a specific user
  Future<void> _sendPushNotification({
    required String receiverId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

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
        debugPrint("Error fetching sender details for swap notification: $e");
      }

      final String type = data?['type'] == 'swap_request' ? 'swap_request' : 'system';
      final String actionId = data?['requestId'] ?? '';
      final String actionRoute = '/swap';

      await _db.collection('notifications').add({
        'senderId': uid,
        'senderName': senderName,
        'senderProfilePic': senderProfilePic,
        'receiverId': receiverId,
        'type': type,
        'title': title,
        'body': body,
        'data': data != null ? {
          ...data,
          'senderName': senderName,
          'senderProfilePic': senderProfilePic,
        } : {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'actionRoute': actionRoute,
        'actionId': actionId,
        'imageUrl': senderProfilePic,
      });
      
      debugPrint('Swap request notification document created for $receiverId');
    } catch (e) {
      debugPrint('Error creating swap request notification document: $e');
    }
  }
}

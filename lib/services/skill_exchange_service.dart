import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_swap/models/swap_model.dart';

class SkillExchangeService {
  SkillExchangeService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const int defaultTotalSessions = 8;

  String exchangeIdForRequest(String requestId) => requestId;

  String senderTeachingSwapId(String requestId, String senderId) =>
      '${requestId}_${senderId}_teaches';

  String receiverTeachingSwapId(String requestId, String receiverId) =>
      '${requestId}_${receiverId}_teaches';

  Stream<List<SwapModel>> watchLearningSwaps(String uid) {
    return _db
        .collection('swaps')
        .where('learnerId', isEqualTo: uid)
        .snapshots()
        .map((snap) => _validUniqueSwaps(snap.docs));
  }

  Stream<List<SwapModel>> watchTeachingSwaps(String uid) {
    return _db
        .collection('swaps')
        .where('mentorId', isEqualTo: uid)
        .snapshots()
        .map((snap) => _validUniqueSwaps(snap.docs));
  }

  Future<List<String>> createMissingSwapPairFromRequest({
    required String requestId,
    required Map<String, dynamic> request,
  }) async {
    final senderId = _text(request['senderId']);
    final receiverId = _text(request['receiverId']);
    final offeredSkill = _text(request['offeredSkill']);
    final requestedSkill = _text(request['requestedSkill']);

    if (senderId.isEmpty ||
        receiverId.isEmpty ||
        offeredSkill.isEmpty ||
        requestedSkill.isEmpty ||
        senderId == receiverId) {
      throw Exception('A skill swap requires two users and two skills.');
    }

    String senderName = _text(request['senderName']).isNotEmpty ? _text(request['senderName']) : 'User';
    String receiverName = _text(request['receiverName']).isNotEmpty ? _text(request['receiverName']) : 'User';

    try {
      final senderDoc = await _db.collection('users').doc(senderId).get();
      if (senderDoc.exists) {
        final sName = senderDoc.data()?['name']?.toString().trim();
        if (sName != null && sName.isNotEmpty) {
          senderName = sName;
        }
      }
    } catch (e) {
      debugPrint('Error fetching sender name in swap pair creation: $e');
    }

    try {
      final receiverDoc = await _db.collection('users').doc(receiverId).get();
      if (receiverDoc.exists) {
        final rName = receiverDoc.data()?['name']?.toString().trim();
        if (rName != null && rName.isNotEmpty) {
          receiverName = rName;
        }
      }
    } catch (e) {
      debugPrint('Error fetching receiver name in swap pair creation: $e');
    }

    final existing = await _db
        .collection('swaps')
        .where('requestId', isEqualTo: requestId)
        .get();

    final existingKeys = existing.docs
        .map((doc) => _swapKey(doc.data()))
        .where((key) => key.isNotEmpty)
        .toSet();

    final senderSwapRef =
        _db.collection('swaps').doc(senderTeachingSwapId(requestId, senderId));
    final receiverSwapRef =
        _db.collection('swaps').doc(receiverTeachingSwapId(requestId, receiverId));

    final batch = _db.batch();
    final participants = [senderId, receiverId];
    final createdIds = <String>[];

    if (!existingKeys.contains(_swapKey({
      'mentorId': senderId,
      'learnerId': receiverId,
      'skillName': offeredSkill,
    }))) {
      batch.set(senderSwapRef, {
        'mentorId': senderId,
        'learnerId': receiverId,
        'mentorName': senderName,
        'learnerName': receiverName,
        'skillName': offeredSkill,
        'status': 'ongoing',
        'progress': 0.0,
        'conversationId': _text(request['conversationId']),
        'completedSessions': 0,
        'totalSessions': defaultTotalSessions,
        'participants': participants,
        'createdAt': FieldValue.serverTimestamp(),
        'requestId': requestId,
        'exchangeId': exchangeIdForRequest(requestId),
        'exchangeRole': 'sender_teaches',
      }, SetOptions(merge: true));
      createdIds.add(senderSwapRef.id);
    }

    if (!existingKeys.contains(_swapKey({
      'mentorId': receiverId,
      'learnerId': senderId,
      'skillName': requestedSkill,
    }))) {
      batch.set(receiverSwapRef, {
        'mentorId': receiverId,
        'learnerId': senderId,
        'mentorName': receiverName,
        'learnerName': senderName,
        'skillName': requestedSkill,
        'status': 'ongoing',
        'progress': 0.0,
        'conversationId': _text(request['conversationId']),
        'completedSessions': 0,
        'totalSessions': defaultTotalSessions,
        'participants': participants,
        'createdAt': FieldValue.serverTimestamp(),
        'requestId': requestId,
        'exchangeId': exchangeIdForRequest(requestId),
        'exchangeRole': 'receiver_teaches',
      }, SetOptions(merge: true));
      createdIds.add(receiverSwapRef.id);
    }

    if (createdIds.isNotEmpty) await batch.commit();
    await syncParticipants(participants);
    return createdIds;
  }

  Future<void> completeSessionAndSync({
    required String swapId,
    required String sessionId,
  }) async {
    final swapRef = _db.collection('swaps').doc(swapId);
    final sessionRef = swapRef.collection('sessions').doc(sessionId);

    final swapSnap = await swapRef.get();
    if (!swapSnap.exists) return;

    final swapData = swapSnap.data() ?? {};
    final exchangeId = _exchangeId(swapId, swapData);
    var pairSnap = await _db
        .collection('swaps')
        .where('exchangeId', isEqualTo: exchangeId)
        .get();
    if (pairSnap.docs.isEmpty) {
      final requestId = _text(swapData['requestId']);
      if (requestId.isNotEmpty) {
        pairSnap = await _db
            .collection('swaps')
            .where('requestId', isEqualTo: requestId)
            .get();
      }
    }

    await _db.runTransaction((transaction) async {
      final freshSwap = await transaction.get(swapRef);
      final freshSession = await transaction.get(sessionRef);
      if (!freshSwap.exists || !freshSession.exists) return;

      final currentSwap = freshSwap.data() ?? {};
      final currentSession = freshSession.data() as Map<String, dynamic>? ?? {};
      if (_text(currentSession['status']).toLowerCase() == 'completed') return;

      final completed =
          (_num(currentSwap['completedSessions'])).toInt() + 1;
      final total = (_num(currentSwap['totalSessions'])).toInt() > 0
          ? (_num(currentSwap['totalSessions'])).toInt()
          : defaultTotalSessions;
      final progress = (completed / total).clamp(0.0, 1.0).toDouble();
      final isExchangeComplete = progress >= 1.0;

      transaction.update(swapRef, {
        'completedSessions': completed,
        'progress': progress,
        'status': isExchangeComplete ? 'completed' : 'ongoing',
        'lastSessionAt': FieldValue.serverTimestamp(),
        'exchangeId': exchangeId,
      });
      transaction.update(sessionRef, {'status': 'completed'});

      if (isExchangeComplete) {
        for (final doc in pairSnap.docs) {
          transaction.update(doc.reference, {
            'status': 'completed',
            'progress': 1.0,
            'lastSessionAt': FieldValue.serverTimestamp(),
            'exchangeId': exchangeId,
          });
        }
        final requestId = _text(currentSwap['requestId']);
        if (requestId.isNotEmpty) {
          transaction.update(_db.collection('swap_requests').doc(requestId), {
            'status': 'completed',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });

    final participants = _participantsFromSwaps(pairSnap.docs)
      ..add(_text(swapData['mentorId']))
      ..add(_text(swapData['learnerId']));
    if (participants.isNotEmpty) await syncParticipants(participants);
  }

  Future<void> rebalanceUser(String uid) async {
    final requestSnap = await _db
        .collection('swap_requests')
        .where('participants', arrayContains: uid)
        .get();

    for (final doc in requestSnap.docs) {
      final data = doc.data();
      final status = _text(data['status']).toLowerCase();
      if (status == 'accepted' || status == 'completed') {
        try {
          await createMissingSwapPairFromRequest(requestId: doc.id, request: data);
        } catch (e) {
          debugPrint('Could not rebalance request ${doc.id}: $e');
        }
      }
    }

    // Auto-heal: scan swaps and recreate missing ones if request exists
    final swapsSnap = await _db
        .collection('swaps')
        .where('participants', arrayContains: uid)
        .get();

    for (final doc in swapsSnap.docs) {
      final swapData = doc.data();
      final requestId = _text(swapData['requestId']);
      if (requestId.isNotEmpty) {
        final reqDoc = await _db.collection('swap_requests').doc(requestId).get();
        if (reqDoc.exists) {
          final reqData = reqDoc.data();
          if (reqData != null) {
            try {
              await createMissingSwapPairFromRequest(requestId: requestId, request: reqData);
            } catch (e) {
              debugPrint('Could not heal missing swap from swap request $requestId: $e');
            }
          }
        }
      }
    }

    await syncParticipants([uid]);
  }

  Future<void> syncParticipants(List<String> participantIds) async {
    for (final uid in participantIds.toSet().where((id) => id.isNotEmpty)) {
      await syncUserProfile(uid);
    }
  }

  Future<void> syncUserProfile(String uid) async {
    final swapsSnap = await _db
        .collection('swaps')
        .where('participants', arrayContains: uid)
        .get();

    final swaps = swapsSnap.docs
        .where((doc) => _isValidSwap(doc.data()))
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();

    final completedPairs = <String, List<Map<String, dynamic>>>{};
    for (final swap in swaps) {
      final status = _text(swap['status']).toLowerCase();
      final progress = _num(swap['progress']);
      if (status != 'completed' && progress < 1.0) continue;
      completedPairs
          .putIfAbsent(_exchangeId(_text(swap['id']), swap), () => [])
          .add(swap);
    }

    final learning = <String>{};
    final teaching = <String>{};
    final completedExchangeIds = <String>{};

    for (final entry in completedPairs.entries) {
      final pair = entry.value;
      final learned = pair
          .where((swap) => _text(swap['learnerId']) == uid)
          .map((swap) => _text(swap['skillName']))
          .where((skill) => skill.isNotEmpty)
          .toSet();
      final taught = pair
          .where((swap) => _text(swap['mentorId']) == uid)
          .map((swap) => _text(swap['skillName']))
          .where((skill) => skill.isNotEmpty)
          .toSet();

      if (learned.isNotEmpty && taught.isNotEmpty) {
        learning.add(learned.first);
        teaching.add(taught.first);
        completedExchangeIds.add(entry.key);
      }
    }

    final balancedCount = learning.length < teaching.length
        ? learning.length
        : teaching.length;
    final learningList = learning.toList()..sort();
    final teachingList = teaching.toList()..sort();

    await _db.collection('users').doc(uid).set({
      'learningSkills': learningList.take(balancedCount).toList(),
      'teachingSkills': teachingList.take(balancedCount).toList(),
      'skillsLearnedCount': balancedCount,
      'skillsTeachingCount': balancedCount,
      'completedSwaps': completedExchangeIds.length,
      'skillExchangeCount': balancedCount,
      'skillStatsSyncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<SwapModel> _validUniqueSwaps(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final seen = <String>{};
    final result = <SwapModel>[];

    for (final doc in docs) {
      final data = doc.data();
      if (!_isValidSwap(data)) continue;
      final key = _swapKey(data);
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      result.add(SwapModel.fromDoc(doc));
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  bool _isValidSwap(Map<String, dynamic> data) {
    final status = _text(data['status']).toLowerCase();
    return _text(data['mentorId']).isNotEmpty &&
        _text(data['learnerId']).isNotEmpty &&
        _text(data['skillName']).isNotEmpty &&
        status != 'cancelled' &&
        status != 'rejected';
  }

  static String _swapKey(Map<String, dynamic> data) {
    final mentorId = _text(data['mentorId']);
    final learnerId = _text(data['learnerId']);
    final skill = _text(data['skillName']).toLowerCase();
    if (mentorId.isEmpty || learnerId.isEmpty || skill.isEmpty) return '';
    return '$mentorId|$learnerId|$skill';
  }

  static String _exchangeId(String fallbackId, Map<String, dynamic> data) {
    final explicit = _text(data['exchangeId']);
    if (explicit.isNotEmpty) return explicit;
    final requestId = _text(data['requestId']);
    if (requestId.isNotEmpty) return requestId;
    return fallbackId;
  }

  static List<String> _participantsFromSwaps(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final ids = <String>{};
    for (final doc in docs) {
      final data = doc.data();
      ids.add(_text(data['mentorId']));
      ids.add(_text(data['learnerId']));
    }
    return ids.where((id) => id.isNotEmpty).toList();
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}

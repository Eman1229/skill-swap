import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/services/notification_service.dart';
import 'package:skill_swap/services/session_reminder_service.dart';
import 'package:skill_swap/services/user_skills_service.dart';

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

    // cloud_firestore 6.x only supports document reads inside transactions.
    // Read the schedule's order first, then transactionally re-read each of
    // those documents before deciding whether this session may complete.
    final scheduledSessions = await swapRef.collection('sessions').orderBy('date').get();
    final scheduledSessionRefs = scheduledSessions.docs.map((doc) => doc.reference).toList();

    await _db.runTransaction((transaction) async {
      final freshSwap = await transaction.get(swapRef);
      if (!freshSwap.exists) return;

      final freshSessions = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final sessionDocRef in scheduledSessionRefs) {
        freshSessions.add(await transaction.get(sessionDocRef));
      }

      final total = freshSessions.length;
      if (total == 0) return;
      final targetIndex = freshSessions.indexWhere((doc) => doc.id == sessionId);
      if (targetIndex < 0) return;
      final currentSession = freshSessions[targetIndex].data();
      if (currentSession == null || _text(currentSession['status']).toLowerCase() == 'completed') {
        return;
      }

      // The transaction is the authority for the sequence. This prevents a
      // stale UI (or a second device) from completing a locked future session.
      final hasIncompletePredecessor = freshSessions
          .take(targetIndex)
          .any((doc) => _text((doc.data() ?? const {})['status']).toLowerCase() != 'completed');
      if (hasIncompletePredecessor || currentSession['isLocked'] == true) {
        throw StateError('Complete the previous scheduled session first.');
      }

      var completed = 0;
      for (final doc in freshSessions) {
        final status = _text((doc.data() ?? const {})['status']).toLowerCase();
        if (doc.id == sessionId || status == 'completed') {
          completed++;
        }
      }
      final progress = (completed / total).clamp(0.0, 1.0).toDouble();
      final isExchangeComplete = progress >= 1.0;

      transaction.update(swapRef, {
        'completedSessions': completed,
        'totalSessions': total,
        'progress': progress,
        'status': isExchangeComplete ? 'completed' : 'ongoing',
        'lastSessionAt': FieldValue.serverTimestamp(),
        'exchangeId': exchangeId,
      });
      transaction.update(sessionRef, {'status': 'completed'});

      // Unlock exactly the next incomplete session and keep every later one
      // locked. The status (pending/accepted) is intentionally preserved so
      // invitation acceptance continues to work as before.
      for (var index = targetIndex + 1; index < freshSessions.length; index++) {
        final doc = freshSessions[index];
        if (_text((doc.data() ?? const {})['status']).toLowerCase() != 'completed') {
          transaction.update(doc.reference, {'isLocked': false});
          break;
        }
      }

      if (isExchangeComplete) {
        transaction.update(swapRef, {
          'certificateUnlocked': true,
          'certificateUnlockedAt': FieldValue.serverTimestamp(),
          'completedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    await SessionReminderService().disableSessionReminders(
      sessionId: sessionId,
      swapId: swapId,
    );

    // Write real-time activity logs for both mentor and learner to update analytics instantly
    final mentorId = _text(swapData['mentorId']);
    final learnerId = _text(swapData['learnerId']);
    final skillName = _text(swapData['skillName']);

    if (mentorId.isNotEmpty && learnerId.isNotEmpty && skillName.isNotEmpty) {
      final now = DateTime.now();
      
      // Log session completion for mentor (teaching)
      final mentorSessionLogId = 'session_completed_${swapId}_${sessionId}_$mentorId';
      await _db.collection('users').doc(mentorId).collection('activities').doc(mentorSessionLogId).set({
        'type': 'session_completed',
        'role': 'mentor',
        'timestamp': Timestamp.fromDate(now),
        'xp': 60,
        'skillName': skillName,
        'swapId': swapId,
        'details': 'Taught a session in $skillName',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Log session completion for learner (learning)
      final learnerSessionLogId = 'session_completed_${swapId}_${sessionId}_$learnerId';
      await _db.collection('users').doc(learnerId).collection('activities').doc(learnerSessionLogId).set({
        'type': 'session_completed',
        'role': 'learner',
        'timestamp': Timestamp.fromDate(now),
        'xp': 60,
        'skillName': skillName,
        'swapId': swapId,
        'details': 'Learned in a session of $skillName',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final freshSwapSnap = await swapRef.get();
      if (freshSwapSnap.exists) {
        final freshData = freshSwapSnap.data() ?? {};
        final freshStatus = _text(freshData['status']).toLowerCase();
        final freshProgress = _num(freshData['progress']);
        if (freshStatus == 'completed' || freshProgress >= 1.0) {
          // Log swap completion for mentor
          final mentorSwapLogId = 'swap_completed_${swapId}_$mentorId';
          await _db.collection('users').doc(mentorId).collection('activities').doc(mentorSwapLogId).set({
            'type': 'swap_completed',
            'role': 'mentor',
            'timestamp': Timestamp.fromDate(now),
            'xp': 250,
            'skillName': skillName,
            'swapId': swapId,
            'details': 'Completed teaching $skillName',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Log swap completion for learner
          final learnerSwapLogId = 'swap_completed_${swapId}_$learnerId';
          await _db.collection('users').doc(learnerId).collection('activities').doc(learnerSwapLogId).set({
            'type': 'swap_completed',
            'role': 'learner',
            'timestamp': Timestamp.fromDate(now),
            'xp': 250,
            'skillName': skillName,
            'swapId': swapId,
            'details': 'Completed learning $skillName',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    }

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
    final results = await Future.wait([
      _db.collection('swaps').where('participants', arrayContains: uid).get(),
      _db.collection('swapListings').where('userId', isEqualTo: uid).get(),
    ]);

    final swapsSnap = results[0];
    final listingsSnap = results[1];

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

    final completedExchangeIds = <String>{};
    for (final entry in completedPairs.entries) {
      final pair = entry.value;
      final hasActivity = pair.any((swap) {
        final learned = _text(swap['learnerId']) == uid && _text(swap['skillName']).isNotEmpty;
        final taught = _text(swap['mentorId']) == uid && _text(swap['skillName']).isNotEmpty;
        return learned || taught;
      });
      if (hasActivity) {
        completedExchangeIds.add(entry.key);
      }
    }

    // Marketplace listings are the single source of truth for profile skill lists.
    final learningList =
        UserSkillsService.learningSkillsFromListingDocs(listingsSnap.docs);
    final teachingList =
        UserSkillsService.teachingSkillsFromListingDocs(listingsSnap.docs);
    final balancedCount = learningList.length < teachingList.length
        ? learningList.length
        : teachingList.length;

    await _db.collection('users').doc(uid).set({
      'learningSkills': learningList,
      'teachingSkills': teachingList,
      'skillsLearnedCount': learningList.length,
      'skillsTeachingCount': teachingList.length,
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

  Future<void> requestSwapCompletion({
    required String swapId,
    required String teacherId,
    required String learnerId,
    required String skillName,
    required String teacherName,
  }) async {
    final swapRef = _db.collection('swaps').doc(swapId);
    await swapRef.update({
      'status': 'Waiting for Learner Confirmation',
      'completionRequestedBy': teacherId,
      'completionRequestedAt': FieldValue.serverTimestamp(),
    });

    // Send notification
    await NotificationService().sendNotification(
      receiverId: learnerId,
      type: 'swap',
      title:'swap_completion_requested_title'.tr(),
      body: '$teacherName has requested to mark "$skillName" as complete. Please review and confirm.',
      actionRoute: '/confirm_completion',
      actionId: swapId,
      data: {
        'type': 'completion_request',
        'swapId': swapId,
      },
    );
  }

  Future<void> confirmSwapCompletion({
    required String swapId,
    required String learnerId,
    required String teacherId,
    required String skillName,
    required String learnerName,
  }) async {
    final swapRef = _db.collection('swaps').doc(swapId);
    final swapSnap = await swapRef.get();

    if (!swapSnap.exists) {
      throw Exception("Swap not found.");
    }

    final data = swapSnap.data() as Map<String, dynamic>;
    final exchangeId = _exchangeId(swapId, data);
    final pairQuery = await _db
        .collection('swaps')
        .where('exchangeId', isEqualTo: exchangeId)
        .get();

    await _db.runTransaction((transaction) async {
      final freshSwapSnap = await transaction.get(swapRef);
      if (!freshSwapSnap.exists) {
        throw Exception("Swap not found.");
      }
      
      final freshData = freshSwapSnap.data() as Map<String, dynamic>;
      final status = freshData['status']?.toString().toLowerCase() ?? '';

      if (status == 'completed') {
        // Already completed, no need to do anything
        return;
      }

      // Update the main swap
      transaction.update(swapRef, {
        'status': 'completed',
        'progress': 1.0,
        'completedAt': FieldValue.serverTimestamp(),
      });

      for (var doc in pairQuery.docs) {
        if (doc.id != swapId) {
          transaction.update(doc.reference, {
            'status': 'completed',
            'progress': 1.0,
            'completedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Update the swap request status if applicable
      final requestId = freshData['requestId']?.toString() ?? '';
      if (requestId.isNotEmpty) {
        transaction.update(_db.collection('swap_requests').doc(requestId), {
          'status': 'completed',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Activity Logs
      final now = DateTime.now();
      final mentorLogId = 'swap_completed_${swapId}_$teacherId';
      final learnerLogId = 'swap_completed_${swapId}_$learnerId';

      final mentorActivityRef = _db
          .collection('users')
          .doc(teacherId)
          .collection('activities')
          .doc(mentorLogId);
      final learnerActivityRef = _db
          .collection('users')
          .doc(learnerId)
          .collection('activities')
          .doc(learnerLogId);

      transaction.set(mentorActivityRef, {
        'type': 'swap_completed',
        'role': 'mentor',
        'timestamp': Timestamp.fromDate(now),
        'xp': 250,
        'skillName': skillName,
        'swapId': swapId,
        'details': 'Completed teaching $skillName',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(learnerActivityRef, {
        'type': 'swap_completed',
        'role': 'learner',
        'timestamp': Timestamp.fromDate(now),
        'xp': 250,
        'skillName': skillName,
        'swapId': swapId,
        'details': 'Completed learning $skillName',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    // Sync profiles (outside transaction because it performs its own operations)
    await syncUserProfile(learnerId);
    await syncUserProfile(teacherId);

    // Get mentor/teacher name from swap details
    String teacherName = 'Your teacher';
    try {
      final swapSnap = await _db.collection('swaps').doc(swapId).get();
      if (swapSnap.exists) {
        final d = swapSnap.data();
        if (d != null) {
          teacherName = d['mentorName'] ?? 'Your teacher';
        }
      }
    } catch (_) {}

    // Send notification to teacher
    await NotificationService().sendNotification(
      receiverId: teacherId,
      type: 'swap',
      title:'swap_completed_title'.tr(),
      body: '$learnerName has confirmed completion of the swap "$skillName".',
      actionRoute: '/skill_detail',
      actionId: swapId,
      data: {
        'type': 'swap_completed',
        'swapId': swapId,
      },
    );

    // Send notification to learner
    await NotificationService().sendNotification(
      receiverId: learnerId,
      type: 'swap',
      title:'swap_completed_title'.tr(),
      body: 'Your swap "$skillName" with $teacherName has been successfully completed.',
      actionRoute: '/skill_detail',
      actionId: swapId,
      data: {
        'type': 'swap_completed',
        'swapId': swapId,
      },
    );
  }

  Future<void> syncSwapSessionCounts(String swapId) async {
    final swapRef = _db.collection('swaps').doc(swapId);
    final sessionsQuery = await swapRef.collection('sessions').get();

    final total = sessionsQuery.docs.length;
    final completed = sessionsQuery.docs
        .where((doc) => _text(doc.data()['status']).toLowerCase() == 'completed')
        .length;
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

    await swapRef.update({
      'totalSessions': total,
      'completedSessions': completed,
      'progress': progress,
    });
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_swap/models/analytics_data.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/models/session_model.dart';
import 'package:skill_swap/models/ai/ai_analytics_snapshot.dart';
import 'package:skill_swap/repositories/ai/ai_recommendation_repository.dart';
import 'package:skill_swap/services/user_skills_service.dart';

class AnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  Stream<AnalyticsData> watchAnalytics(String uid) {
    late StreamController<AnalyticsData> controller;
    final subscriptions = <StreamSubscription>[];

    controller = StreamController<AnalyticsData>.broadcast(
      onListen: () {
        DocumentSnapshot? userSnap;
        List<SwapModel>? swaps;
        QuerySnapshot? requestsSnap;
        QuerySnapshot? listingsSnap;
        QuerySnapshot? activitiesSnap;
        QuerySnapshot? reviewsSnap;

        void checkAndEmit() async {
          if (userSnap == null ||
              swaps == null ||
              requestsSnap == null ||
              listingsSnap == null ||
              activitiesSnap == null ||
              reviewsSnap == null ||
              controller.isClosed) {
            return;
          }

          try {
            final swapIds = swaps!.map((s) => s.id).toList();
            final sessions = await _fetchAllSessions(uid, swapIds);

            // Backfill in background to keep history persistent and non-volatile
            _backfillActivities(
              uid,
              swaps!,
              sessions,
              requestsSnap!.docs,
              listingsSnap!.docs,
              activitiesSnap!.docs,
            );

            final data = _calculateAnalytics(
              uid: uid,
              userSnap: userSnap!,
              swaps: swaps!,
              requestsSnap: requestsSnap!,
              listingsSnap: listingsSnap!,
              activitiesSnap: activitiesSnap!,
              reviewsSnap: reviewsSnap!,
              sessions: sessions,
            );

            if (!controller.isClosed) {
              controller.add(data);
            }

            // Sync overall stats to the users document to ensure global consistency
            _db.collection('users').doc(uid).set({
              'xp': data.totalXp,
              'level': data.currentLevel,
              'levelProgress': data.levelProgressPercentage,
              'completedSwaps': data.completedSwaps,
              'skillsLearnedCount': data.skillsLearnedCount,
              'skillsTeachingCount': data.skillsTeachingCount,
              'teachingSkills': data.skillsTeaching,
              'learningSkills': data.skillsLearned,
              // Sync computed ratings back so other services can read them quickly
              'learningRating': data.learningRating,
              'teachingRating': data.teachingRating,
              'completedLearningSessions': data.completedLearningSessions,
              'completedTeachingSessions': data.completedTeachingSessions,
            }, SetOptions(merge: true)).catchError((e) {
              debugPrint("Error syncing user stats to Firestore: $e");
            });

            // Save AIAnalyticsSnapshot so Career Compass / Roadmap always has fresh data
            _saveAiSnapshot(uid, data, sessions).catchError((e) {
              debugPrint("Error saving AI analytics snapshot: $e");
            });

            // Sync Rating + Reviews to all swapListings for this user so
            // listing cards always show accurate data. When no reviews have
            // been submitted yet, use completedSwaps as the Reviews count
            // so the "N swaps_count" chip shows a non-zero value.
            _syncListingsStats(uid, listingsSnap!.docs, data).catchError((e) {
              debugPrint("Error syncing listing stats: $e");
            });
          } catch (e, stack) {
            debugPrint("Error in watchAnalytics checkAndEmit: $e\n$stack");
          }
        }

        subscriptions.add(
          _db.collection('users').doc(uid).snapshots().listen((snap) {
            userSnap = snap;
            checkAndEmit();
          }, onError: controller.addError),
        );

        subscriptions.add(
          _db
              .collection('swaps')
              .where('participants', arrayContains: uid)
              .snapshots()
              .listen((snap) {
            swaps = snap.docs.map((doc) => SwapModel.fromDoc(doc)).toList();
            checkAndEmit();
          }, onError: controller.addError),
        );

        subscriptions.add(
          _db
              .collection('swap_requests')
              .where('participants', arrayContains: uid)
              .snapshots()
              .listen((snap) {
            requestsSnap = snap;
            checkAndEmit();
          }, onError: controller.addError),
        );

        subscriptions.add(
          _db
              .collection('swapListings')
              .where('userId', isEqualTo: uid)
              .snapshots()
              .listen((snap) {
            listingsSnap = snap;
            checkAndEmit();
          }, onError: controller.addError),
        );

        subscriptions.add(
          _db
              .collection('users')
              .doc(uid)
              .collection('activities')
              .orderBy('timestamp', descending: true)
              .snapshots()
              .listen((snap) {
            activitiesSnap = snap;
            checkAndEmit();
          }, onError: controller.addError),
        );

        // Stream the reviews collection filtered by revieweeId so ratings
        // update in real-time immediately after a review is submitted.
        subscriptions.add(
          _db
              .collection('reviews')
              .where('revieweeId', isEqualTo: uid)
              .snapshots()
              .listen((snap) {
            reviewsSnap = snap;
            checkAndEmit();
          }, onError: controller.addError),
        );
      },
      onCancel: () async {
        for (final sub in subscriptions) {
          await sub.cancel();
        }
      },
    );

    return controller.stream;
  }

  Future<List<SessionModel>> _fetchAllSessions(String uid, List<String> swapIds) async {
    final List<SessionModel> list = [];
    if (swapIds.isEmpty) return list;

    await Future.wait(
      swapIds.map((swapId) async {
        try {
          final snap = await _db
              .collection('swaps')
              .doc(swapId)
              .collection('sessions')
              .get();
          for (final doc in snap.docs) {
            list.add(SessionModel.fromDoc(doc));
          }
        } catch (e) {
          debugPrint("Error fetching sessions for swap $swapId: $e");
        }
      }),
    );
    return list;
  }

  AnalyticsData _calculateAnalytics({
    required String uid,
    required DocumentSnapshot userSnap,
    required List<SwapModel> swaps,
    required QuerySnapshot requestsSnap,
    required QuerySnapshot listingsSnap,
    required QuerySnapshot activitiesSnap,
    required QuerySnapshot reviewsSnap,
    required List<SessionModel> sessions,
  }) {
    final now = DateTime.now();
    final userData = userSnap.data() as Map<String, dynamic>? ?? {};
    final listingMaps = listingsSnap.docs.map((doc) => doc.data() as Map<String, dynamic>? ?? {}).toList();

    // Profile metadata
    String name = userData['name']?.toString().trim() ?? '';
    if (name.isEmpty && listingMaps.isNotEmpty) name = listingMaps.first['name']?.toString().trim() ?? '';
    if (name.isEmpty) name = 'User';

    String? imageUrl = userData['imageUrl']?.toString().trim();
    if ((imageUrl == null || imageUrl.isEmpty) && listingMaps.isNotEmpty) {
      imageUrl = listingMaps.first['imageUrl']?.toString().trim();
    }
    if (imageUrl == null || imageUrl.isEmpty) imageUrl = null;

    final initials = _getInitials(name);
    final username = _getUsername(userData);

    // 1. Success Rate
    int acceptedRequests = 0;
    int closedRequests = 0;
    final List<Map<String, dynamic>> requestsList = [];
    for (final doc in requestsSnap.docs) {
      final rData = doc.data() as Map<String, dynamic>? ?? {};
      requestsList.add({'id': doc.id, ...rData});
      final status = rData['status']?.toString().toLowerCase() ?? '';
      if (status == 'accepted' || status == 'completed') {
        acceptedRequests++;
      }
      if (status == 'accepted' ||
          status == 'completed' ||
          status == 'rejected' ||
          status == 'cancelled') {
        closedRequests++;
      }
    }
    final successRate = closedRequests == 0 ? 0.0 : (acceptedRequests / closedRequests) * 100.0;

    // 2. Attendance Rate
    final attended = sessions.where((s) => s.status.toLowerCase() == 'completed').length;
    final missed = sessions
        .where((s) =>
    s.status.toLowerCase() == 'rejected' ||
        s.status.toLowerCase() == 'cancelled' ||
        (s.status.toLowerCase() == 'accepted' && s.date.add(const Duration(hours: 2)).isBefore(now)))
        .length;
    final attendanceRate = (attended + missed) == 0 ? 100.0 : (attended / (attended + missed)) * 100.0;

    // 3. Completed swaps and sessions count
    final completedSwapsList = swaps.where((s) => s.status.toLowerCase() == 'completed' || s.progress >= 1.0).toList();
    final completedSwapsCount = completedSwapsList.length;
    final totalSessions = swaps.fold<int>(0, (acc, swap) => acc + swap.completedSessions);

    // 4. Profile skills from marketplace listings (single source of truth)
    final skillsTeaching =
    UserSkillsService.teachingSkillsFromListingDocs(listingsSnap.docs);
    final skillsLearned =
    UserSkillsService.learningSkillsFromListingDocs(listingsSnap.docs);

    // Completed swap skills used only for XP balancing (NOT for UI display)
    final completedLearnedSet = <String>{};
    final completedTeachingSet = <String>{};
    for (final s in completedSwapsList) {
      if (s.learnerId == uid) completedLearnedSet.add(s.skillName);
      if (s.mentorId == uid) completedTeachingSet.add(s.skillName);
    }
    final balancedLearned = completedLearnedSet.toList();
    final balancedTeaching = completedTeachingSet.toList();

    final activeTeachingSwapsCount =
        swaps.where((s) => s.mentorId == uid).length;
    final activeLearningSwapsCount =
        swaps.where((s) => s.learnerId == uid).length;

    // 5. XP and Level
    final totalXp = (completedSwapsCount * 250 +
        totalSessions * 60 +
        acceptedRequests * 40 +
        balancedTeaching.length * 90 +
        balancedLearned.length * 110).toInt();

    final currentLevel = (totalXp ~/ 1000) + 1;
    final xpRequiredForNextLevel = 1000 - (totalXp % 1000);
    final levelProgressPercentage = (totalXp % 1000) / 1000.0;

    // 6. Hours – computed from the swap's own completedSessions counter,
    // filtered by the user's role on the swap document. This is more reliable
    // than querying session subcollection documents (which may lack learnerId).
    final completedLearningSessionsCount = swaps
        .where((s) => s.learnerId == uid)
        .fold<int>(0, (acc, s) => acc + s.completedSessions);
    final completedTeachingSessionsCount = swaps
        .where((s) => s.mentorId == uid)
        .fold<int>(0, (acc, s) => acc + s.completedSessions);
    final learningHours = completedLearningSessionsCount * 1.5;
    final teachingHours = completedTeachingSessionsCount * 1.5;

    // Also compute from actual session docs (for weekly chart / streak data)
    final completedLearningSessions = sessions
        .where((s) => (s.learnerId == uid || (s.learnerId.isEmpty && s.participantIds.contains(uid))) && s.status.toLowerCase() == 'completed')
        .length;
    final completedTeachingSessions = sessions
        .where((s) => (s.mentorId == uid || (s.mentorId.isEmpty && s.participantIds.contains(uid))) && s.status.toLowerCase() == 'completed')
        .length;
    // Use the higher of the two (swap counter is authoritative, session docs used if more detailed)
    final finalCompletedLearningSessions = completedLearningSessionsCount > completedLearningSessions
        ? completedLearningSessionsCount
        : completedLearningSessions;
    final finalCompletedTeachingSessions = completedTeachingSessionsCount > completedTeachingSessions
        ? completedTeachingSessionsCount
        : completedTeachingSessions;

    // 7. Ratings – calculated from the reviews collection (real-time source of truth)
    // Split by revieweeRole to get per-context ratings.
    double learningRatingSum = 0.0;
    int learningRatingCount = 0;
    double teachingRatingSum = 0.0;
    int teachingRatingCount = 0;

    for (final doc in reviewsSnap.docs) {
      final rData = doc.data() as Map<String, dynamic>? ?? {};
      final ratingVal = _numValue(rData['rating']);
      if (ratingVal <= 0) continue;
      final role = rData['revieweeRole']?.toString().toLowerCase() ?? '';
      if (role == 'learner') {
        learningRatingSum += ratingVal;
        learningRatingCount++;
      } else if (role == 'mentor') {
        teachingRatingSum += ratingVal;
        teachingRatingCount++;
      } else {
        // Legacy reviews without role – count toward both aggregates
        teachingRatingSum += ratingVal;
        teachingRatingCount++;
      }
    }

    final learningRating = learningRatingCount == 0
        ? 0.0
        : learningRatingSum / learningRatingCount;
    final teachingRating = teachingRatingCount == 0
        ? 0.0
        : teachingRatingSum / teachingRatingCount;

    final totalReviewsCount = reviewsSnap.docs.length;
    final allRatingSum = learningRatingSum + teachingRatingSum;
    final allRatingCount = learningRatingCount + teachingRatingCount;

    // Overall average rating: prefer the pre-computed value stored on the user
    // document (written by rate_feedback_screen.dart after each review) for
    // accuracy. Fall back to computing from the reviews stream if absent.
    double averageRating;
    final storedAvg = _numValue(userData['averageRating']);
    if (storedAvg > 0) {
      averageRating = storedAvg;
    } else {
      averageRating = allRatingCount == 0
          ? 0.0
          : allRatingSum / allRatingCount;
    }

    // 8. Streaks
    final learningDates = activitiesSnap.docs
        .where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return d['type'] == 'session_completed' && d['role'] == 'learner';
    })
        .map((doc) => _dateValue((doc.data() as Map<String, dynamic>)['timestamp']) ?? now)
        .toList();
    final teachingDates = activitiesSnap.docs
        .where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return d['type'] == 'session_completed' && d['role'] == 'mentor';
    })
        .map((doc) => _dateValue((doc.data() as Map<String, dynamic>)['timestamp']) ?? now)
        .toList();

    final learningStreak = _calculateStreak(learningDates);
    final teachingStreak = _calculateStreak(teachingDates);

    // 9. Badges
    int unlockedBadges = 0;
    if (completedSwapsCount >= 1) unlockedBadges++;
    if (skillsLearned.length >= 3) unlockedBadges++;
    if (skillsTeaching.length >= 3) unlockedBadges++;
    if (currentLevel >= 5) unlockedBadges++;
    if (successRate >= 80 && completedSwapsCount >= 1) unlockedBadges++;
    if (completedSwapsCount >= 10) unlockedBadges++;

    // 10. Growth calculations (XP historical cuts)
    final thisWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = now.month == 1 ? DateTime(now.year - 1, 12, 1) : DateTime(now.year, now.month - 1, 1);

    final xpNow = totalXp;
    final xpStartThisWeek = _calculateXpAt(
      cutOff: thisWeekStart,
      swaps: swaps,
      sessions: sessions,
      requests: requestsList,
      uid: uid,
    );
    final xpStartLastWeek = _calculateXpAt(
      cutOff: lastWeekStart,
      swaps: swaps,
      sessions: sessions,
      requests: requestsList,
      uid: uid,
    );

    final xpStartThisMonth = _calculateXpAt(
      cutOff: thisMonthStart,
      swaps: swaps,
      sessions: sessions,
      requests: requestsList,
      uid: uid,
    );
    final xpStartLastMonth = _calculateXpAt(
      cutOff: lastMonthStart,
      swaps: swaps,
      sessions: sessions,
      requests: requestsList,
      uid: uid,
    );

    final xpEarnedThisWeek = xpNow - xpStartThisWeek;
    final xpEarnedLastWeek = xpStartThisWeek - xpStartLastWeek;
    final weeklyGrowthPercentage = xpEarnedLastWeek == 0
        ? (xpEarnedThisWeek > 0 ? 100.0 : 0.0)
        : ((xpEarnedThisWeek - xpEarnedLastWeek) / xpEarnedLastWeek) * 100.0;

    final xpEarnedThisMonth = xpNow - xpStartThisMonth;
    final xpEarnedLastMonth = xpStartThisMonth - xpStartLastMonth;
    final monthlyGrowthPercentage = xpEarnedLastMonth == 0
        ? (xpEarnedThisMonth > 0 ? 100.0 : 0.0)
        : ((xpEarnedThisMonth - xpEarnedLastMonth) / xpEarnedLastMonth) * 100.0;

    // 11. Activity Graphs – built from activity log timestamps
    final activityDates = activitiesSnap.docs
        .map((doc) => _dateValue((doc.data() as Map<String, dynamic>)['timestamp']) ?? now)
        .toList();
    final weeklyActivity = _weeklyActivity(activityDates);
    final monthlyActivity = _monthlyActivity(activityDates);

    DateTime? firstActivityAt;
    if (activityDates.isNotEmpty) {
      final sortedActivityDates = List<DateTime>.from(activityDates)..sort();
      firstActivityAt = sortedActivityDates.first;
    }

    DateTime? firstCompletedSwapAt;
    final completedSwapDates = swaps
        .where((s) => s.status.toLowerCase() == 'completed' || s.progress >= 1.0)
        .map((s) => s.lastSessionAt ?? s.createdAt)
        .toList()
      ..sort();
    if (completedSwapDates.isNotEmpty) {
      firstCompletedSwapAt = completedSwapDates.first;
    }

    // 12. Skill Growth
    final progressBySkill = <String, List<double>>{};
    for (final s in swaps) {
      final progress = s.totalSessions > 0 ? (s.completedSessions / s.totalSessions).clamp(0.0, 1.0) : 0.0;
      progressBySkill.putIfAbsent(s.skillName, () => []).add(progress);
    }
    final skillGrowth = progressBySkill.map((skill, values) {
      final average = values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
      return MapEntry(skill, average);
    });

    return AnalyticsData(
      uid: uid,
      name: name,
      username: username,
      initials: initials,
      imageUrl: imageUrl,
      totalXp: totalXp,
      learningHours: learningHours,
      teachingHours: teachingHours,
      skillsLearnedCount: skillsLearned.length,
      skillsTeachingCount: skillsTeaching.length,
      activeTeachingSwapsCount: activeTeachingSwapsCount,
      activeLearningSwapsCount: activeLearningSwapsCount,
      averageRating: averageRating,
      learningRating: learningRating,
      teachingRating: teachingRating,
      reviewsCount: totalReviewsCount,
      weeklyGrowthPercentage: weeklyGrowthPercentage.clamp(-100.0, 1000.0),
      monthlyGrowthPercentage: monthlyGrowthPercentage.clamp(-100.0, 1000.0),
      completedSessions: totalSessions,
      completedLearningSessions: finalCompletedLearningSessions,
      completedTeachingSessions: finalCompletedTeachingSessions,
      attendanceRate: attendanceRate,
      successRate: successRate,
      currentXp: totalXp,
      currentLevel: currentLevel,
      xpRequiredForNextLevel: xpRequiredForNextLevel,
      levelProgressPercentage: levelProgressPercentage,
      completedSwaps: completedSwapsCount,
      learningStreak: learningStreak,
      teachingStreak: teachingStreak,
      totalAchievements: unlockedBadges,
      skillsLearned: skillsLearned,
      skillsTeaching: skillsTeaching,
      weeklyActivity: weeklyActivity,
      monthlyActivity: monthlyActivity,
      skillGrowth: skillGrowth,
      unlockedBadges: unlockedBadges,
      totalBadges: 6,
      firstActivityAt: firstActivityAt,
      firstCompletedSwapAt: firstCompletedSwapAt,
    );
  }

  /// Persist a fresh AIAnalyticsSnapshot derived from the already-computed
  /// AnalyticsData so the Career Compass and Learning Roadmap screens always
  /// read accurate, real-time data.
  Future<void> _saveAiSnapshot(
    String uid,
    AnalyticsData data,
    List<SessionModel> sessions,
  ) async {
    try {
      // Build weeklyLearningHours from completed sessions this week
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      final weeklyLearningHours = <String, int>{
        for (final l in dayLabels) l: 0
      };

      for (final s in sessions) {
        if (s.learnerId != uid) continue;
        if (s.status.toLowerCase() != 'completed') continue;
        final day = DateTime(s.date.year, s.date.month, s.date.day);
        final diffDays = day.difference(weekStart).inDays;
        if (diffDays >= 0 && diffDays < 7) {
          final label = dayLabels[diffDays];
          // Count each completed session as 1 hour unit for the graph
          weeklyLearningHours[label] = (weeklyLearningHours[label] ?? 0) + 1;
        }
      }

      final snapshot = AIAnalyticsSnapshot(
        userId: uid,
        learningHours: data.learningHours,
        skillsGained: data.skillsLearnedCount,
        teachingHours: data.teachingHours,
        sessionSuccessRate: data.averageRating > 0
            ? (data.averageRating / 5.0).clamp(0.0, 1.0)
            : (data.successRate / 100.0).clamp(0.0, 1.0),
        mentorMatchAccuracy: data.successRate / 100.0,
        roadmapProgress: data.levelProgressPercentage,
        careerReadinessScore: (data.currentLevel / 10.0).clamp(0.0, 1.0),
        projectsCompleted: data.completedSwaps,
        isLearningConsistent: data.learningStreak >= 3,
        weeklyLearningHours: weeklyLearningHours,
        createdAt: DateTime.now(),
        period: 'weekly',
      );

      await AIRecommendationRepository().saveAnalyticsSnapshot(uid, snapshot);
    } catch (e) {
      debugPrint("Error saving AI analytics snapshot: $e");
    }
  }

  /// Sync Rating and Reviews (capital R) to all swapListings belonging to
  /// this user so listing cards always show accurate data.
  ///
  /// - If the user has reviews, use [data.averageRating] and [data.reviewsCount].
  /// - If no reviews yet, still write [data.completedSwaps] as [Reviews] so
  ///   the "N swaps_count" chip shows a meaningful number instead of 0.
  Future<void> _syncListingsStats(
    String uid,
    List<QueryDocumentSnapshot> listingDocs,
    AnalyticsData data,
  ) async {
    if (listingDocs.isEmpty) return;
    try {
      final batch = _db.batch();
      // Reviews field: prefer actual review count, fall back to completed swaps
      final reviewsValue = data.reviewsCount > 0
          ? data.reviewsCount
          : data.completedSwaps;
      // Rating: only write a non-zero rating when reviews actually exist
      final ratingValue = data.reviewsCount > 0 ? data.averageRating : 0.0;
      for (final doc in listingDocs) {
        batch.update(doc.reference, {
          'Rating': ratingValue,
          'Reviews': reviewsValue,
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error syncing listing stats: $e");
    }
  }

  String _getUsername(Map<String, dynamic> userData) {
    final stored = userData['username']?.toString().trim() ?? '';
    if (stored.isNotEmpty) return stored.startsWith('@') ? stored : '@$stored';
    return '@skillswapper';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  int _calculateXpAt({
    required DateTime cutOff,
    required List<SwapModel> swaps,
    required List<SessionModel> sessions,
    required List<Map<String, dynamic>> requests,
    required String uid,
  }) {
    final filteredSwaps = swaps.where((s) {
      if (s.status.toLowerCase() != 'completed') return false;
      final date = s.lastSessionAt ?? s.createdAt;
      return date.isBefore(cutOff);
    }).toList();

    final filteredSessions = sessions.where((s) {
      return s.status.toLowerCase() == 'completed' && s.date.isBefore(cutOff);
    }).toList();

    int acceptedRequests = 0;
    for (final r in requests) {
      final status = (r['status'] ?? '').toString().toLowerCase();
      final createdAt = _dateValue(r['createdAt']) ?? DateTime.now();
      if ((status == 'accepted' || status == 'completed') && createdAt.isBefore(cutOff)) {
        acceptedRequests++;
      }
    }

    final completedPairs = <String, List<SwapModel>>{};
    for (final swap in filteredSwaps) {
      completedPairs.putIfAbsent(swap.id, () => []).add(swap);
    }

    final learnedSet = <String>{};
    final teachingSet = <String>{};
    for (final entry in completedPairs.values) {
      for (final swap in entry) {
        if (swap.learnerId == uid) learnedSet.add(swap.skillName);
        if (swap.mentorId == uid) teachingSet.add(swap.skillName);
      }
    }

    final balancedCount = math.min(learnedSet.length, teachingSet.length);
    final totalSessionsCount = filteredSessions.length;
    final completedSwapsCount = filteredSwaps.length;

    return completedSwapsCount * 250 +
        totalSessionsCount * 60 +
        acceptedRequests * 40 +
        balancedCount * 90 +
        balancedCount * 110;
  }

  int _calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final uniqueDays = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()..sort();
    int currentStreak = 0;
    int maxStreak = 0;
    DateTime? prev;
    for (final day in uniqueDays) {
      if (prev == null) {
        currentStreak = 1;
      } else {
        final diff = day.difference(prev).inDays;
        if (diff == 1) {
          currentStreak++;
        } else if (diff > 1) {
          if (currentStreak > maxStreak) maxStreak = currentStreak;
          currentStreak = 1;
        }
      }
      prev = day;
    }
    if (currentStreak > maxStreak) maxStreak = currentStreak;

    if (uniqueDays.isNotEmpty) {
      final lastDay = uniqueDays.last;
      final today = DateTime.now();
      final todayDay = DateTime(today.year, today.month, today.day);
      final diff = todayDay.difference(lastDay).inDays;
      if (diff > 1) {
        return 0; // Streak broken/expired
      }
    }
    return currentStreak;
  }

  Map<String, int> _weeklyActivity(List<DateTime> dates) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final result = {for (final label in labels) label: 0};
    for (final date in dates) {
      final day = DateTime(date.year, date.month, date.day);
      final diff = day.difference(start).inDays;
      if (diff >= 0 && diff < 7) {
        result[labels[diff]] = result[labels[diff]]! + 1;
      }
    }
    return result;
  }

  Map<String, int> _monthlyActivity(List<DateTime> dates) {
    final now = DateTime.now();
    final result = <String, int>{};
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      result[_monthLabel(month.month)] = 0;
    }
    for (final date in dates) {
      final key = _monthLabel(date.month);
      if (result.containsKey(key) &&
          DateTime(now.year, now.month - 5, 1).isBefore(DateTime(date.year, date.month + 1, 1))) {
        result[key] = result[key]! + 1;
      }
    }
    return result;
  }

  String _monthLabel(int month) {
    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return labels[(month - 1).clamp(0, 11).toInt()];
  }

  void _backfillActivities(
      String uid,
      List<SwapModel> swaps,
      List<SessionModel> sessions,
      List<QueryDocumentSnapshot> requests,
      List<QueryDocumentSnapshot> listings,
      List<QueryDocumentSnapshot> existingLogs,
      ) async {
    final existingIds = existingLogs.map((doc) => doc.id).toSet();
    final batch = _db.batch();
    var hasUpdates = false;

    // 1. Backfill completed sessions
    for (final s in sessions) {
      if (s.status.toLowerCase() == 'completed') {
        final docId = 'session_completed_${s.swapId}_${s.id}_$uid';
        if (!existingIds.contains(docId)) {
          final isMentor = s.mentorId == uid;
          final swap = swaps.firstWhere(
                (sw) => sw.id == s.swapId,
            orElse: () => SwapModel(
              id: s.swapId,
              mentorId: s.mentorId,
              learnerId: s.learnerId,
              mentorName: '',
              learnerName: '',
              skillName: s.title,
              status: 'ongoing',
              progress: 0.0,
              conversationId: '',
              completedSessions: 0,
              totalSessions: 0,
              createdAt: DateTime.now(),
            ),
          );

          batch.set(
            _db.collection('users').doc(uid).collection('activities').doc(docId),
            {
              'type': 'session_completed',
              'role': isMentor ? 'mentor' : 'learner',
              'timestamp': Timestamp.fromDate(s.date),
              'xp': 60,
              'skillName': swap.skillName,
              'swapId': s.swapId,
              'details': isMentor ? 'Taught a session in ${swap.skillName}' : 'Learned in a session of ${swap.skillName}',
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
          hasUpdates = true;
        }
      }
    }

    // 2. Backfill completed swaps
    for (final s in swaps) {
      if (s.status.toLowerCase() == 'completed' || s.progress >= 1.0) {
        final docId = 'swap_completed_${s.id}_$uid';
        if (!existingIds.contains(docId)) {
          final isMentor = s.mentorId == uid;
          batch.set(
            _db.collection('users').doc(uid).collection('activities').doc(docId),
            {
              'type': 'swap_completed',
              'role': isMentor ? 'mentor' : 'learner',
              'timestamp': Timestamp.fromDate(s.lastSessionAt ?? s.createdAt),
              'xp': 250,
              'skillName': s.skillName,
              'swapId': s.id,
              'details': isMentor ? 'Completed teaching ${s.skillName}' : 'Completed learning ${s.skillName}',
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
          hasUpdates = true;
        }
      }
    }

    // 3. Backfill accepted requests
    for (final r in requests) {
      final rData = r.data() as Map<String, dynamic>? ?? {};
      final status = (rData['status'] ?? '').toString().toLowerCase();
      final createdAt = _dateValue(rData['createdAt']) ?? DateTime.now();
      if (status == 'accepted' || status == 'completed') {
        final docId = 'request_accepted_${r.id}_$uid';
        if (!existingIds.contains(docId)) {
          batch.set(
            _db.collection('users').doc(uid).collection('activities').doc(docId),
            {
              'type': 'request_accepted',
              'timestamp': Timestamp.fromDate(createdAt),
              'xp': 40,
              'details': 'Accepted a skill swap request',
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
          hasUpdates = true;
        }
      }
    }

    if (hasUpdates) {
      try {
        await batch.commit();
      } catch (e) {
        debugPrint("Error committing backfill activities batch: $e");
      }
    }
  }

  DateTime? _dateValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  double _numValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
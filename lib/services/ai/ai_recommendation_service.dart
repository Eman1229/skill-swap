// lib/services/ai/ai_recommendation_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_swap/models/ai/career_recommendation.dart';
import 'package:skill_swap/models/ai/mentor_recommendation.dart';
import 'package:skill_swap/models/ai/learning_roadmap_model.dart';
import 'package:skill_swap/models/ai/ai_analytics_snapshot.dart';
import 'package:skill_swap/models/ai/recommendation_feedback.dart';
import 'package:skill_swap/services/ai/ai_cache_service.dart';
import 'package:skill_swap/services/ai/career_compass_service.dart';
import 'package:skill_swap/services/ai/mentor_compass_service.dart';
import 'package:skill_swap/services/ai/learning_roadmap_service.dart';
import 'package:skill_swap/repositories/ai/ai_recommendation_repository.dart';
import 'package:skill_swap/services/skill_exchange_service.dart';

class AIRecommendationService {
  static final AIRecommendationService _instance = AIRecommendationService._internal();
  factory AIRecommendationService() => _instance;
  AIRecommendationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AICacheService _cache = AICacheService();
  final MentorCompassService _mentorService = MentorCompassService();
  final CareerCompassService _careerService = CareerCompassService();
  final LearningRoadmapService _roadmapService = LearningRoadmapService();
  final AIRecommendationRepository _repository = AIRecommendationRepository();

  // ── Fetch Cached Data ───────────────────────────────────────────────
  Future<List<MentorRecommendation>> getLatestMentors() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    try {
      final doc = await _db.collection('mentor_recommendations').doc(uid).get();
      if (!doc.exists) return [];
      final latestId = doc.data()?['latestId'] as String?;
      if (latestId == null) return [];

      final historyDoc = await _db
          .collection('mentor_recommendations')
          .doc(uid)
          .collection('history')
          .doc(latestId)
          .get();

      if (!historyDoc.exists) return [];
      final list = historyDoc.data()?['recommendations'] as List? ?? [];
      return list.map((e) => MentorRecommendation.fromMap(Map<String, dynamic>.from(e), historyDoc.id)).toList();
    } catch (e) {
      debugPrint('AIRecommendationService.getLatestMentors error: $e');
      return [];
    }
  }

  Future<CareerRecommendation?> getLatestCareer() async {
    return _careerService.getLatestRecommendation();
  }

  Future<LearningRoadmapModel?> getLatestRoadmap() async {
    return _roadmapService.getLatestRoadmap();
  }

  // ── Staleness & Auto-Regeneration ──────────────────────────────────
  Future<void> refreshIfStale({String? careerGoal, bool force = false}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      print('AIRecommendationService: refreshIfStale aborted - uid is null');
      return;
    }

    print('AIRecommendationService: refreshIfStale called with force=$force, careerGoal=$careerGoal');

    try {
      // 0. Auto-sync profile stats from ground-truth swaps in Firestore
      await SkillExchangeService().syncUserProfile(uid);

      // 1. Fetch current profile statistics for cache checks
      final userDoc = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      final currentSkills = List<String>.from(userData['learningSkills'] ?? []);
      final currentSwapCount = (userData['completedSwaps'] as num?)?.toInt() ?? 0;
      final currentRating = (userData['averageRating'] as num?)?.toDouble() ?? 0.0;

      print('AIRecommendationService: currentSwapCount=$currentSwapCount, skills=${currentSkills.length}, rating=$currentRating');

      // Check if Firestore already has fresh career recommendation
      bool isCareerDbFresh = false;
      try {
        final metaDoc = await _db.collection('career_recommendations').doc(uid).get();
        final metaDocData = metaDoc.data();
        if (metaDoc.exists && metaDocData != null) {
          final latestId = metaDocData['latestId'] as String?;
          if (latestId != null) {
            final historyDoc = await _db
                .collection('career_recommendations')
                .doc(uid)
                .collection('history')
                .doc(latestId)
                .get();
            final historyDocData = historyDoc.data();
            if (historyDoc.exists && historyDocData != null) {
              final triggerData = historyDocData['triggerData'] as Map?;
              if (triggerData != null) {
                final dbSwapCount = (triggerData['completedSwaps'] as num?)?.toInt() ?? 0;
                final dbSkills = List<String>.from(triggerData['skillsLearned'] ?? []);
                print('AIRecommendationService: dbSwapCount=$dbSwapCount, dbSkills=${dbSkills.length}');
                if (dbSwapCount >= currentSwapCount && _listsEqual(dbSkills, currentSkills)) {
                  isCareerDbFresh = true;
                  await _cache.markCareerFresh(uid, currentRating: currentRating, currentSwapCount: currentSwapCount, currentSkills: currentSkills);
                  print('AIRecommendationService: Firestore career recommendation is already fresh (swaps: $dbSwapCount). Skipping generation.');
                }
              }
            }
          }
        }
      } catch (e) {
        print('AIRecommendationService: Error checking career db freshness: $e');
      }

      // 2. Refresh Mentors
      final mentorStale = await _cache.isMentorStale(uid, currentSkills: currentSkills, currentSwapCount: currentSwapCount);
      print('AIRecommendationService: mentorStale=$mentorStale');
      if (mentorStale || force) {
        print('AIRecommendationService: Computing mentor recommendations...');
        await _mentorService.computeRecommendations();
        await _cache.markMentorFresh(uid, currentSkills: currentSkills, currentSwapCount: currentSwapCount);
        await _repository.logGeneration(userId: uid, type: 'mentor_generation', success: true);
      }

      // 3. Refresh Career Recommendations
      final careerStale = await _cache.isCareerStale(uid, currentRating: currentRating, currentSwapCount: currentSwapCount, currentSkills: currentSkills);
      print('AIRecommendationService: careerStale=$careerStale, isCareerDbFresh=$isCareerDbFresh');
      if ((careerStale && !isCareerDbFresh) || force) {
        print('AIRecommendationService: Triggering career recommendation generation...');
        await _careerService.generateRecommendation(careerGoal: careerGoal);
        await _cache.markCareerFresh(uid, currentRating: currentRating, currentSwapCount: currentSwapCount, currentSkills: currentSkills);
        await _repository.logGeneration(userId: uid, type: 'career_generation', success: true);
      }

      // Check if Firestore already has fresh learning roadmap
      bool isRoadmapDbFresh = false;
      String? roadmapTargetCareer;
      try {
        final roadmapMetaDoc = await _db.collection('learning_roadmaps').doc(uid).get();
        final roadmapMetaDocData = roadmapMetaDoc.data();
        if (roadmapMetaDoc.exists && roadmapMetaDocData != null) {
          roadmapTargetCareer = roadmapMetaDocData['targetCareer'] as String?;
          if (roadmapTargetCareer != null && roadmapTargetCareer.isNotEmpty) {
            final latestId = roadmapMetaDocData['latestId'] as String?;
            if (latestId != null) {
              final historyDoc = await _db
                  .collection('learning_roadmaps')
                  .doc(uid)
                  .collection('history')
                  .doc(latestId)
                  .get();
              final historyDocData = historyDoc.data();
              if (historyDoc.exists && historyDocData != null) {
                final triggerData = historyDocData['triggerData'] as Map?;
                if (triggerData != null) {
                  final dbSwapCount = (triggerData['completedSwaps'] as num?)?.toInt() ?? 0;
                  final dbSkills = List<String>.from(triggerData['currentSkills'] ?? []);
                  if (dbSwapCount >= currentSwapCount && _listsEqual(dbSkills, currentSkills)) {
                    isRoadmapDbFresh = true;
                    await _cache.markRoadmapFresh(uid, targetCareer: roadmapTargetCareer);
                    debugPrint('AIRecommendationService: Firestore learning roadmap is already fresh (swaps: $dbSwapCount). Skipping generation.');
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('AIRecommendationService: Error checking roadmap db freshness: $e');
      }

      // 3.5 Refresh/Regenerate Learning Roadmap
      String? targetCareer = roadmapTargetCareer;
      if (targetCareer == null || targetCareer.isEmpty) {
        final latestCareer = await getLatestCareer();
        if (latestCareer != null && latestCareer.careers.isNotEmpty) {
          targetCareer = latestCareer.careers.first.title;
        }
      }
      if (targetCareer == null || targetCareer.isEmpty) {
        targetCareer = userData['careerGoal']?.toString() ?? userData['targetCareer']?.toString();
      }

      if (targetCareer != null && targetCareer.isNotEmpty) {
        final roadmapStale = await _cache.isRoadmapStale(uid, targetCareer: targetCareer);
        if ((roadmapStale && !isRoadmapDbFresh) || force) {
          debugPrint('AIRecommendationService: Generating learning roadmap for $targetCareer');
          List<String> missingSkills = [];
          final latestCareer = await getLatestCareer();
          if (latestCareer != null) {
            final matchingPath = latestCareer.careers.firstWhere(
              (c) => c.title.toLowerCase() == targetCareer!.toLowerCase(),
              orElse: () => latestCareer.careers.first,
            );
            missingSkills = matchingPath.missingSkills;
          }

          await _roadmapService.generateRoadmap(
            targetCareer: targetCareer,
            currentSkills: currentSkills,
            missingSkills: missingSkills,
            learningHours: (userData['learningHours'] as num?)?.toDouble() ?? 0.0,
            completedSwaps: currentSwapCount,
            averageRating: currentRating,
          );
          await _cache.markRoadmapFresh(uid, targetCareer: targetCareer);
          await _repository.logGeneration(userId: uid, type: 'roadmap_generation', success: true);
        }
      }

      // 4. Generate/Save Weekly Analytics Snapshot
      await generateAndSaveSnapshot(uid, userData);
    } catch (e, stack) {
      debugPrint('AIRecommendationService.refreshIfStale error: $e\n$stack');
      await _repository.logGeneration(userId: uid, type: 'auto_refresh_failure', success: false, error: e.toString());
    }
  }

  // ── Analytics Snapshot Generator ────────────────────────────────────
  Future<void> generateAndSaveSnapshot(String uid, Map<String, dynamic> userData) async {
    try {
      // Gather data from user document
      final learningHours = (userData['learningHours'] as num?)?.toDouble() ?? 0.0;
      final teachingHours = (userData['teachingHours'] as num?)?.toDouble() ?? 0.0;
      final completedSwaps = (userData['completedSwaps'] as num?)?.toInt() ?? 0;
      final averageRating = (userData['averageRating'] as num?)?.toDouble() ?? 5.0;

      // Fetch progress overall
      final progressDoc = await _db.collection('roadmap_progress').doc(uid).get();
      final roadmapProgress = progressDoc.exists
          ? (progressDoc.data()?['overallPercent'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      // Compute readiness score
      // base: level/20 + swaps/10 + progress/2
      final currentLevel = (userData['level'] as num?)?.toDouble() ?? 1.0;
      final careerReadiness = ((currentLevel / 10.0) * 30 + (completedSwaps / 5.0) * 30 + roadmapProgress * 40).clamp(10.0, 100.0);

      final snapshot = AIAnalyticsSnapshot(
        userId: uid,
        learningHours: learningHours,
        skillsGained: List<String>.from(userData['learningSkills'] ?? []).length,
        teachingHours: teachingHours,
        sessionSuccessRate: averageRating / 5.0,
        mentorMatchAccuracy: 0.85, // base metric
        roadmapProgress: roadmapProgress,
        careerReadinessScore: careerReadiness,
        projectsCompleted: completedSwaps,
        isLearningConsistent: ((userData['learningStreak'] as num?)?.toInt() ?? 0) > 0,
        weeklyLearningHours: const {
          'Mon': 1, 'Tue': 0, 'Wed': 2, 'Thu': 1, 'Fri': 0, 'Sat': 3, 'Sun': 1
        },
        createdAt: DateTime.now(),
        period: 'weekly',
      );

      await _repository.saveAnalyticsSnapshot(uid, snapshot);
    } catch (e) {
      debugPrint('AIRecommendationService.generateAndSaveSnapshot error: $e');
    }
  }

  // ── Feedback Submit ─────────────────────────────────────────────────
  Future<void> submitFeedback(String recId, String type, int rating, String comment) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final feedback = RecommendationFeedback(
      id: '',
      userId: uid,
      recommendationId: recId,
      type: type,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    await _repository.submitFeedback(feedback);
  }

  bool _listsEqual(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    final sortedA = List.from(a)..sort();
    final sortedB = List.from(b)..sort();
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }
}

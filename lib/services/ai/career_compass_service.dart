// lib/services/ai/career_compass_service.dart
// Orchestrates career guidance using GPT-4o-mini via Cloud Function proxy.
// Reads user analytics from Firestore and sends structured prompts.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_swap/models/ai/career_recommendation.dart';
import 'package:skill_swap/services/ai/ai_profile_service.dart';
import 'package:skill_swap/services/ai/openai_service.dart';

class CareerCompassService {
  static final CareerCompassService _instance = CareerCompassService._internal();
  factory CareerCompassService() => _instance;
  CareerCompassService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OpenAIService _openai = OpenAIService();
  final AIProfileService _profileService = AIProfileService();

  Future<CareerRecommendation> generateRecommendation({String? careerGoal}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return CareerRecommendation.empty();

    try {
      final profile = await _profileService.buildProfile(uid);
      if (!profile.isEligibleForRecommendations) {
        throw StateError(
          'Complete at least $kMinCompletedSwapsForAI successful swaps to unlock Career Compass.',
        );
      }

      final result = await _openai.generateCareerRecommendation(
        skillsLearned: profile.skillsLearned,
        skillsTeaching: profile.skillsTeaching,
        completedSwaps: profile.completedSwaps,
        averageRating: profile.averageRating,
        learningHours: profile.learningHours,
        teachingHours: profile.teachingHours,
        learningStreak: profile.learningStreak,
        totalAchievements: profile.totalAchievements,
        successRate: profile.successRate,
        careerGoal: careerGoal ?? profile.careerGoal,
        interests: profile.interests,
        profileSummary: profile.profileSummary,
        recentSwapHistory: profile.recentSwapHistory,
      );

      final id = result['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
      return CareerRecommendation.fromMap(result, id);
    } catch (e, stack) {
      debugPrint('CareerCompassService.generateRecommendation error: $e\n$stack');
      rethrow;
    }
  }

  /// Fetches the latest cached career recommendation from Firestore.
  Future<CareerRecommendation?> getLatestRecommendation() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      final profile = await _profileService.buildProfile(uid);
      if (!profile.isEligibleForRecommendations) return null;

      final metaDoc = await _db.collection('career_recommendations').doc(uid).get();
      if (!metaDoc.exists) return null;

      final latestId = metaDoc.data()?['latestId'] as String?;
      if (latestId == null) return null;

      final historyDoc = await _db
          .collection('career_recommendations')
          .doc(uid)
          .collection('history')
          .doc(latestId)
          .get();

      if (!historyDoc.exists) return null;

      final data = historyDoc.data()!;
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
      }

      return CareerRecommendation.fromMap(data, historyDoc.id);
    } catch (e) {
      debugPrint('CareerCompassService.getLatestRecommendation error: $e');
      return null;
    }
  }
}

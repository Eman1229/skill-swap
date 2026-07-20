// lib/services/ai/career_compass_service.dart
// Orchestrates career guidance using GPT-4o-mini via Cloud Function proxy.
// Reads user analytics from Firestore and sends structured prompts.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_swap/models/ai/career_recommendation.dart';
import 'package:skill_swap/services/ai/openai_service.dart';

class CareerCompassService {
  static final CareerCompassService _instance = CareerCompassService._internal();
  factory CareerCompassService() => _instance;
  CareerCompassService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OpenAIService _openai = OpenAIService();

  Future<CareerRecommendation> generateRecommendation({String? careerGoal}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return CareerRecommendation.empty();

    try {
      // Fetch user profile
      final profile = await _fetchUserProfile(uid);

      // Call Cloud Function
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
        careerGoal: careerGoal,
      );

      // The Cloud Function already saves to Firestore
      // Parse and return
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
      // Convert Timestamp to DateTime
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
      }

      return CareerRecommendation.fromMap(data, historyDoc.id);
    } catch (e) {
      debugPrint('CareerCompassService.getLatestRecommendation error: $e');
      return null;
    }
  }

  Future<_UserProfile> _fetchUserProfile(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      // Also fetch swap listing for current skill
      final listingSnap = await _db
          .collection('swapListings')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      final skillsLearned = List<String>.from(userData['learningSkills'] ?? []);
      final skillsTeaching = List<String>.from(userData['teachingSkills'] ?? []);

      if (listingSnap.docs.isNotEmpty) {
        final ld = listingSnap.docs.first.data();
        final offering = (ld['offering'] as String?) ?? '';
        final wanting = (ld['wanting'] as String?) ?? '';
        if (offering.isNotEmpty && !skillsTeaching.contains(offering)) {
          skillsTeaching.insert(0, offering);
        }
        if (wanting.isNotEmpty && !skillsLearned.contains(wanting)) {
          skillsLearned.insert(0, wanting);
        }
      }

      return _UserProfile(
        skillsLearned: skillsLearned,
        skillsTeaching: skillsTeaching,
        completedSwaps: (userData['completedSwaps'] as num?)?.toInt() ?? 0,
        averageRating: (userData['averageRating'] as num?)?.toDouble() ??
            (userData['xp'] as num? ?? 0) / 200.0,
        learningHours: (userData['learningHours'] as num?)?.toDouble() ?? 0,
        teachingHours: (userData['teachingHours'] as num?)?.toDouble() ?? 0,
        learningStreak: (userData['learningStreak'] as num?)?.toInt() ?? 0,
        totalAchievements: (userData['totalAchievements'] as num?)?.toInt() ??
            (userData['unlockedBadges'] as num?)?.toInt() ?? 0,
        successRate: (userData['successRate'] as num?)?.toDouble() ?? 1.0,
      );
    } catch (e) {
      debugPrint('CareerCompassService._fetchUserProfile error: $e');
      return _UserProfile(
        skillsLearned: const [],
        skillsTeaching: const [],
        completedSwaps: 0,
        averageRating: 0,
        learningHours: 0,
        teachingHours: 0,
        learningStreak: 0,
        totalAchievements: 0,
        successRate: 0,
      );
    }
  }
}

class _UserProfile {
  final List<String> skillsLearned;
  final List<String> skillsTeaching;
  final int completedSwaps;
  final double averageRating;
  final double learningHours;
  final double teachingHours;
  final int learningStreak;
  final int totalAchievements;
  final double successRate;

  _UserProfile({
    required this.skillsLearned,
    required this.skillsTeaching,
    required this.completedSwaps,
    required this.averageRating,
    required this.learningHours,
    required this.teachingHours,
    required this.learningStreak,
    required this.totalAchievements,
    required this.successRate,
  });
}

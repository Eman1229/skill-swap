// lib/services/ai/ai_profile_service.dart
// Builds a rich AI profile from Firestore user data, listings, and swap history.
// Mirrors the server-side buildAIProfile() in functions/index.js.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_swap/services/user_skills_service.dart';

/// Minimum completed swaps required before Career Compass / Roadmap unlock.
const int kMinCompletedSwapsForAI = 2;

class AIUserProfile {
  final List<String> skillsLearned;
  final List<String> skillsTeaching;
  final List<String> interests;
  final String profileSummary;
  final int completedSwaps;
  final double averageRating;
  final double learningHours;
  final double teachingHours;
  final int learningStreak;
  final int totalAchievements;
  final double successRate;
  final String? careerGoal;
  final List<String> recentSwapHistory;

  const AIUserProfile({
    required this.skillsLearned,
    required this.skillsTeaching,
    required this.interests,
    required this.profileSummary,
    required this.completedSwaps,
    required this.averageRating,
    required this.learningHours,
    required this.teachingHours,
    required this.learningStreak,
    required this.totalAchievements,
    required this.successRate,
    this.careerGoal,
    required this.recentSwapHistory,
  });

  bool get isEligibleForRecommendations => completedSwaps >= kMinCompletedSwapsForAI;

  List<String> get allSkills => {...skillsLearned, ...skillsTeaching}.toList()..sort();

  Map<String, dynamic> toPromptPayload() => {
        'skillsLearned': skillsLearned,
        'skillsTeaching': skillsTeaching,
        'interests': interests,
        'profileSummary': profileSummary,
        'completedSwaps': completedSwaps,
        'averageRating': averageRating,
        'learningHours': learningHours,
        'teachingHours': teachingHours,
        'learningStreak': learningStreak,
        'totalAchievements': totalAchievements,
        'successRate': successRate,
        'careerGoal': careerGoal,
        'recentSwapHistory': recentSwapHistory,
      };
}

class AIProfileService {
  static final AIProfileService _instance = AIProfileService._internal();
  factory AIProfileService() => _instance;
  AIProfileService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<AIUserProfile> buildProfile(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final listingsSnap =
          await _db.collection('swapListings').where('userId', isEqualTo: uid).get();
      final swapsSnap = await _db
          .collection('swaps')
          .where('participants', arrayContains: uid)
          .get();

      final userData = userDoc.data() ?? {};
      final learned = <String>{
        ..._list(userData['learningSkills']),
        ..._list(userData['skillsLearned']),
        ..._list(userData['wantedSkills']),
        ..._list(userData['skillsWanted']),
        ..._list(userData['wanting']),
        ..._list(userData['learningSkill']),
        ...UserSkillsService.learningSkillsFromListingDocs(listingsSnap.docs),
      };
      final teaching = <String>{
        ..._list(userData['teachingSkills']),
        ..._list(userData['skillsTeaching']),
        ..._list(userData['offeredSkills']),
        ..._list(userData['skillsOffered']),
        ..._list(userData['offering']),
        ..._list(userData['teachingSkill']),
        ...UserSkillsService.teachingSkillsFromListingDocs(listingsSnap.docs),
      };
      final interests = <String>{
        ..._list(userData['interests']),
        ..._list(userData['interest']),
        ..._list(userData['skillsInterested']),
        ..._list(userData['careerInterests']),
        ..._list(userData['category']),
        ..._list(userData['categories']),
        ..._list(userData['tags']),
      };
      final recentSwapHistory = <String>[];
      final completedExchangeIds = <String>{};

      for (final doc in listingsSnap.docs) {
        final data = doc.data();
        for (final field in [
          data['interests'],
          data['tags'],
          data['categories'],
          data['interest'],
          data['skillsInterested'],
          data['careerInterests'],
        ]) {
          interests.addAll(_list(field));
        }
        for (final field in [
          data['wanting'], data['wantedSkill'], data['learningSkill'], data['skillsWanted'], data['wantedSkills']
        ]) {
          learned.addAll(_list(field));
        }
        for (final field in [
          data['offering'], data['offeredSkill'], data['teachingSkill'], data['skillsOffered'], data['offeredSkills']
        ]) {
          teaching.addAll(_list(field));
        }
      }

      for (final doc in swapsSnap.docs) {
        final data = doc.data();
        final skill = _text(data['skillName']);
        final isUserLearner = _text(data['learnerId']) == uid;
        final isUserMentor = _text(data['mentorId']) == uid;

        if (skill.isNotEmpty) {
          if (isUserLearner) learned.add(skill);
          if (isUserMentor) teaching.add(skill);

          final statusStr = _text(data['status']);
          final roleStr = isUserLearner ? 'learning' : (isUserMentor ? 'teaching' : 'swapping');
          recentSwapHistory.add('$roleStr $skill ($statusStr)');
        }

        if (!_isCompleted(data)) continue;
        if (skill.isEmpty) continue;

        final exchangeId = _exchangeId(doc.id, data);
        completedExchangeIds.add(exchangeId);

        if (isUserLearner) {
          recentSwapHistory.add('completed learning $skill');
        }
        if (isUserMentor) {
          recentSwapHistory.add('completed teaching $skill');
        }
      }

      final profileSummary = [
        _text(userData['name']),
        _text(userData['bio']),
        _text(userData['headline']),
        _text(userData['about']),
        _text(userData['location']),
      ].where((s) => s.isNotEmpty).join(' | ');

      final completedSwaps = completedExchangeIds.length;

      final totalSessions = [
        _num(userData['totalSessions'], 1).toInt(),
        completedSwaps,
        1,
      ].reduce((a, b) => a > b ? a : b);

      return AIUserProfile(
        skillsLearned: learned.toList()..sort(),
        skillsTeaching: teaching.toList()..sort(),
        interests: interests.toList()..sort(),
        profileSummary: profileSummary,
        completedSwaps: completedSwaps,
        averageRating: _num(userData['averageRating'], _num(userData['rating'])),
        learningHours: _num(userData['learningHours']),
        teachingHours: _num(userData['teachingHours']),
        learningStreak: _num(userData['learningStreak']).toInt(),
        totalAchievements: _num(
          userData['totalAchievements'],
          _num(userData['unlockedBadges']),
        ).toInt(),
        successRate: _num(
          userData['successRate'],
          completedSwaps / totalSessions,
        ),
        careerGoal: _text(userData['careerGoal']).isNotEmpty
            ? _text(userData['careerGoal'])
            : (_text(userData['targetCareer']).isNotEmpty
                ? _text(userData['targetCareer'])
                : (_text(userData['goal']).isNotEmpty ? _text(userData['goal']) : null)),
        recentSwapHistory: recentSwapHistory.toSet().toList().take(12).toList(),
      );
    } catch (e, stack) {
      debugPrint('AIProfileService.buildProfile error: $e\n$stack');
      return const AIUserProfile(
        skillsLearned: [],
        skillsTeaching: [],
        interests: [],
        profileSummary: '',
        completedSwaps: 0,
        averageRating: 0,
        learningHours: 0,
        teachingHours: 0,
        learningStreak: 0,
        totalAchievements: 0,
        successRate: 0,
        recentSwapHistory: [],
      );
    }
  }

  List<String> _list(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
    final text = value.toString().trim();
    return text.isEmpty ? [] : [text];
  }

  String _text(dynamic value) => value?.toString().trim() ?? '';

  double _num(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return fallback;
  }

  bool _isCompleted(Map<String, dynamic> data) {
    final status = _text(data['status']).toLowerCase();
    final progress = _num(data['progress']);
    return status == 'completed' || progress >= 1.0;
  }

  String _exchangeId(String docId, Map<String, dynamic> data) {
    final explicit = _text(data['exchangeId']);
    if (explicit.isNotEmpty) return explicit;
    final requestId = _text(data['requestId']);
    if (requestId.isNotEmpty) return requestId;
    return docId;
  }
}

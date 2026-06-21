// lib/services/ai/ai_cache_service.dart
// Manages staleness detection and cache invalidation for AI recommendations.
// Uses SharedPreferences to store lightweight metadata; actual data lives in Firestore.

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AICacheService {
  static final AICacheService _instance = AICacheService._internal();
  factory AICacheService() => _instance;
  AICacheService._internal();

  static const String _mentorKeyPrefix = 'ai_mentor_ts_';
  static const String _careerKeyPrefix = 'ai_career_ts_';
  static const String _roadmapKeyPrefix = 'ai_roadmap_ts_';
  static const String _skillHashPrefix = 'ai_skill_hash_';
  static const String _swapCountPrefix = 'ai_swap_count_';
  static const String _ratingHashPrefix = 'ai_rating_hash_';

  // Regenerate if older than this many hours
  static const int _mentorStalenessHours = 24;
  static const int _careerStalenessHours = 72;
  static const int _roadmapStalenessHours = 168; // 1 week

  // ── Mentor Cache ────────────────────────────────────────────────────
  Future<bool> isMentorStale(String uid, {
    required List<String> currentSkills,
    required int currentSwapCount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt('$_mentorKeyPrefix$uid');
      if (ts == null) return true;

      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(ts),
      );
      if (age.inHours >= _mentorStalenessHours) return true;

      // Check if skills changed
      final storedHash = prefs.getString('$_skillHashPrefix$uid');
      final currentHash = _hashList(currentSkills);
      if (storedHash != currentHash) return true;

      // Check if new swaps completed
      final storedCount = prefs.getInt('$_swapCountPrefix$uid') ?? 0;
      if (currentSwapCount > storedCount) return true;

      return false;
    } catch (e) {
      debugPrint('AICacheService.isMentorStale error: $e');
      return true;
    }
  }

  Future<void> markMentorFresh(String uid, {
    required List<String> currentSkills,
    required int currentSwapCount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_mentorKeyPrefix$uid', DateTime.now().millisecondsSinceEpoch);
      await prefs.setString('$_skillHashPrefix$uid', _hashList(currentSkills));
      await prefs.setInt('$_swapCountPrefix$uid', currentSwapCount);
    } catch (e) {
      debugPrint('AICacheService.markMentorFresh error: $e');
    }
  }

  // ── Career Cache ────────────────────────────────────────────────────
  Future<bool> isCareerStale(String uid, {
    required double currentRating,
    required int currentSwapCount,
    required List<String> currentSkills,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt('$_careerKeyPrefix$uid');
      if (ts == null) return true;

      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(ts),
      );
      if (age.inHours >= _careerStalenessHours) return true;

      final storedRatingHash = prefs.getString('$_ratingHashPrefix$uid');
      final currentRatingHash = currentRating.toStringAsFixed(1);
      if (storedRatingHash != currentRatingHash) return true;

      final storedSkillHash = prefs.getString('${_skillHashPrefix}career_$uid');
      if (storedSkillHash != _hashList(currentSkills)) return true;

      final storedCount = prefs.getInt('${_swapCountPrefix}career_$uid') ?? 0;
      if (currentSwapCount > storedCount) return true;

      return false;
    } catch (e) {
      return true;
    }
  }

  Future<void> markCareerFresh(String uid, {
    required double currentRating,
    required int currentSwapCount,
    required List<String> currentSkills,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_careerKeyPrefix$uid', DateTime.now().millisecondsSinceEpoch);
      await prefs.setString('$_ratingHashPrefix$uid', currentRating.toStringAsFixed(1));
      await prefs.setString('${_skillHashPrefix}career_$uid', _hashList(currentSkills));
      await prefs.setInt('${_swapCountPrefix}career_$uid', currentSwapCount);
    } catch (e) {
      debugPrint('AICacheService.markCareerFresh error: $e');
    }
  }

  // ── Roadmap Cache ───────────────────────────────────────────────────
  Future<bool> isRoadmapStale(String uid, {required String targetCareer}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt('$_roadmapKeyPrefix$uid');
      if (ts == null) return true;

      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(ts),
      );
      if (age.inHours >= _roadmapStalenessHours) return true;

      final storedCareer = prefs.getString('${_roadmapKeyPrefix}career_$uid') ?? '';
      if (storedCareer != targetCareer) return true;

      return false;
    } catch (e) {
      return true;
    }
  }

  Future<void> markRoadmapFresh(String uid, {required String targetCareer}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_roadmapKeyPrefix$uid', DateTime.now().millisecondsSinceEpoch);
      await prefs.setString('${_roadmapKeyPrefix}career_$uid', targetCareer);
    } catch (e) {
      debugPrint('AICacheService.markRoadmapFresh error: $e');
    }
  }

  /// Force-invalidate all caches (e.g., user changes career goal)
  Future<void> invalidateAll(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = [
        '$_mentorKeyPrefix$uid',
        '$_careerKeyPrefix$uid',
        '$_roadmapKeyPrefix$uid',
        '$_skillHashPrefix$uid',
        '${_skillHashPrefix}career_$uid',
        '$_swapCountPrefix$uid',
        '${_swapCountPrefix}career_$uid',
        '$_ratingHashPrefix$uid',
        '${_roadmapKeyPrefix}career_$uid',
      ];
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('AICacheService.invalidateAll error: $e');
    }
  }

  String _hashList(List<String> items) {
    final sorted = List<String>.from(items)..sort();
    return sorted.join('|');
  }
}

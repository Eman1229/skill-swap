// lib/services/ai/openai_service.dart
// Thin client for the three Firebase Cloud Functions that proxy OpenAI.
// The OpenAI API key never leaves the server — stored in Secret Manager.

import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();

  static const String _region = 'us-central1';
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: _region);

  Future<Map<String, dynamic>> _callFunction(
    String functionName,
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final callable = _functions.httpsCallable(
        functionName,
        options: HttpsCallableOptions(timeout: timeout),
      );
      final result = await callable.call(payload);
      return Map<String, dynamic>.from(_normalize(result.data) as Map);
    } catch (e) {
      debugPrint('OpenAIService.$functionName error: $e');
      rethrow;
    }
  }

  // ── Embeddings ──────────────────────────────────────────────────────
  /// Returns a list of embedding vectors for the given texts.
  /// Uses Cloud Function "getEmbedding" which calls text-embedding-3-small.
  Future<List<List<double>>> getEmbeddings(List<String> texts) async {
    final data = await _callFunction('getEmbedding', {'texts': texts});
    final embeddings = data['embeddings'] as List;
    return embeddings
        .map(
          (e) => List<double>.from(
            (e as List).map((v) => (v as num).toDouble()),
          ),
        )
        .toList();
  }

  dynamic _normalize(dynamic value) {
    if (value is Map) {
      return value.map((key, nestedValue) {
        return MapEntry(key.toString(), _normalize(nestedValue));
      });
    }
    if (value is List) {
      return value.map(_normalize).toList();
    }
    return value;
  }

  // ── Career Compass ──────────────────────────────────────────────────
  /// Calls the "generateCareerRecommendation" Cloud Function (GPT-4o-mini).
  Future<Map<String, dynamic>> generateCareerRecommendation({
    required List<String> skillsLearned,
    required List<String> skillsTeaching,
    required int completedSwaps,
    required double averageRating,
    required double learningHours,
    required double teachingHours,
    required int learningStreak,
    required int totalAchievements,
    required double successRate,
    String? careerGoal,
  }) async {
    return _callFunction(
      'generateCareerRecommendation',
      {
        'skillsLearned': skillsLearned,
        'skillsTeaching': skillsTeaching,
        'completedSwaps': completedSwaps,
        'averageRating': averageRating,
        'learningHours': learningHours,
        'teachingHours': teachingHours,
        'learningStreak': learningStreak,
        'totalAchievements': totalAchievements,
        'successRate': successRate,
        'careerGoal': careerGoal,
      },
      timeout: const Duration(seconds: 90),
    );
  }

  // ── Learning Roadmap ────────────────────────────────────────────────
  /// Calls the "generateLearningRoadmap" Cloud Function (GPT-4o-mini).
  Future<Map<String, dynamic>> generateLearningRoadmap({
    required String targetCareer,
    required List<String> currentSkills,
    required List<String> missingSkills,
    required double learningHours,
    required int completedSwaps,
    required double averageRating,
  }) async {
    return _callFunction(
      'generateLearningRoadmap',
      {
        'targetCareer': targetCareer,
        'currentSkills': currentSkills,
        'missingSkills': missingSkills,
        'learningHours': learningHours,
        'completedSwaps': completedSwaps,
        'averageRating': averageRating,
      },
      timeout: const Duration(seconds: 90),
    );
  }
}

// lib/services/ai/openai_service.dart
// Thin client for the three Firebase Cloud Functions that proxy OpenAI.
// The OpenAI API key never leaves the server — stored in Secret Manager.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ── Embeddings ──────────────────────────────────────────────────────
  /// Returns a list of embedding vectors for the given texts.
  /// Uses Cloud Function "getEmbedding" which calls text-embedding-3-small.
  Future<List<List<double>>> getEmbeddings(List<String> texts) async {
    try {
      final callable = _functions.httpsCallable(
        'getEmbedding',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result = await callable.call({'texts': texts});
      final data = result.data as Map<String, dynamic>;
      final embeddings = data['embeddings'] as List;
      return embeddings
          .map((e) => List<double>.from((e as List).map((v) => (v as num).toDouble())))
          .toList();
    } catch (e) {
      debugPrint('OpenAIService.getEmbeddings error: $e');
      rethrow;
    }
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
    try {
      final callable = _functions.httpsCallable(
        'generateCareerRecommendation',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
      );
      final result = await callable.call({
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
      });
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      debugPrint('OpenAIService.generateCareerRecommendation error: $e');
      rethrow;
    }
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
    try {
      final callable = _functions.httpsCallable(
        'generateLearningRoadmap',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
      );
      final result = await callable.call({
        'targetCareer': targetCareer,
        'currentSkills': currentSkills,
        'missingSkills': missingSkills,
        'learningHours': learningHours,
        'completedSwaps': completedSwaps,
        'averageRating': averageRating,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      debugPrint('OpenAIService.generateLearningRoadmap error: $e');
      rethrow;
    }
  }
}

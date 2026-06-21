// lib/repositories/ai/ai_recommendation_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/models/ai/recommendation_feedback.dart';
import 'package:skill_swap/models/ai/ai_analytics_snapshot.dart';

class AIRecommendationRepository {
  static final AIRecommendationRepository _instance = AIRecommendationRepository._internal();
  factory AIRecommendationRepository() => _instance;
  AIRecommendationRepository._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Feedback ────────────────────────────────────────────────────────
  Future<void> submitFeedback(RecommendationFeedback feedback) async {
    try {
      final docRef = _db
          .collection('recommendation_feedback')
          .doc(feedback.userId)
          .collection('feedback')
          .doc(); // Auto ID

      await docRef.set(feedback.toMap());

      // Optionally log audit log of feedback
      await _db
          .collection('ai_recommendation_logs')
          .doc(feedback.userId)
          .collection('logs')
          .add({
        'type': 'feedback_submitted',
        'recommendationId': feedback.recommendationId,
        'recommendationType': feedback.type,
        'rating': feedback.rating,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  // ── Logging ─────────────────────────────────────────────────────────
  Future<void> logGeneration({
    required String userId,
    required String type,
    required bool success,
    String? error,
  }) async {
    try {
      await _db
          .collection('ai_recommendation_logs')
          .doc(userId)
          .collection('logs')
          .add({
        'type': type,
        'success': success,
        if (error != null) 'error': error,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Fail silently for logs
    }
  }

  // ── Analytics Snapshots ─────────────────────────────────────────────
  Future<void> saveAnalyticsSnapshot(String userId, AIAnalyticsSnapshot snapshot) async {
    try {
      final dateKey = snapshot.createdAt.toIso8601String().substring(0, 10); // YYYY-MM-DD
      await _db
          .collection('analytics_snapshots')
          .doc(userId)
          .collection('history')
          .doc(dateKey)
          .set(snapshot.toMap());
    } catch (e) {
      throw Exception('Failed to save analytics snapshot: $e');
    }
  }

  Future<AIAnalyticsSnapshot?> getLatestAnalyticsSnapshot(String userId) async {
    try {
      final snap = await _db
          .collection('analytics_snapshots')
          .doc(userId)
          .collection('history')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      final data = doc.data();
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
      }
      return AIAnalyticsSnapshot.fromMap(data);
    } catch (e) {
      return null;
    }
  }
}

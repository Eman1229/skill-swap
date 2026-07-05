// lib/providers/ai/ai_recommendation_provider.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/models/ai/career_recommendation.dart';
import 'package:skill_swap/models/ai/mentor_recommendation.dart';
import 'package:skill_swap/models/ai/learning_roadmap_model.dart';
import 'package:skill_swap/models/ai/ai_analytics_snapshot.dart';
import 'package:skill_swap/services/ai/ai_recommendation_service.dart';
import 'package:skill_swap/services/ai/learning_roadmap_service.dart';
import 'package:skill_swap/repositories/ai/ai_recommendation_repository.dart';
import 'package:skill_swap/services/skill_exchange_service.dart';

class AIRecommendationProvider extends ChangeNotifier {
  final AIRecommendationService _service = AIRecommendationService();
  final LearningRoadmapService _roadmapService = LearningRoadmapService();
  final AIRecommendationRepository _repository = AIRecommendationRepository();

  List<MentorRecommendation> _mentorRecommendations = [];
  CareerRecommendation? _careerRecommendation;
  LearningRoadmapModel? _learningRoadmap;
  AIAnalyticsSnapshot? _analyticsSnapshot;
  bool _isLoading = false;
  String? _error;

  List<MentorRecommendation> get mentorRecommendations => _mentorRecommendations;
  CareerRecommendation? get careerRecommendation => _careerRecommendation;
  LearningRoadmapModel? get learningRoadmap => _learningRoadmap;
  AIAnalyticsSnapshot? get analyticsSnapshot => _analyticsSnapshot;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Load All Data ───────────────────────────────────────────────────
  Future<void> loadRecommendations({String? uid}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (uid != null) {
        await SkillExchangeService().syncUserProfile(uid);
      }

      final mentors = await _service.getLatestMentors();
      final career = await _service.getLatestCareer();
      final roadmap = await _service.getLatestRoadmap();
      
      _mentorRecommendations = mentors;
      _careerRecommendation = career;
      _learningRoadmap = roadmap;

      if (uid != null) {
        _analyticsSnapshot = await _repository.getLatestAnalyticsSnapshot(uid);
      }

      if (career == null && uid != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final userData = userDoc.data() ?? {};
        final completedSwaps = (userData['completedSwaps'] as num?)?.toInt() ?? 0;
        if (completedSwaps > 0) {
          _isLoading = false;
          await refreshRecommendations(uid: uid, force: true);
          return;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── Refresh/Regenerate ──────────────────────────────────────────────
  Future<void> refreshRecommendations({String? careerGoal, bool force = false, String? uid}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.refreshIfStale(careerGoal: careerGoal, force: force);
      
      final mentors = await _service.getLatestMentors();
      final career = await _service.getLatestCareer();
      final roadmap = await _service.getLatestRoadmap();

      _mentorRecommendations = mentors;
      _careerRecommendation = career;
      _learningRoadmap = roadmap;

      if (uid != null) {
        _analyticsSnapshot = await _repository.getLatestAnalyticsSnapshot(uid);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── Generate Roadmap ────────────────────────────────────────────────
  Future<void> generateRoadmap({
    required CareerPath careerPath,
    required List<String> currentSkills,
    required double learningHours,
    required int completedSwaps,
    required double averageRating,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final roadmap = await _roadmapService.generateRoadmap(
        targetCareer: careerPath.title,
        currentSkills: currentSkills,
        missingSkills: careerPath.missingSkills,
        learningHours: learningHours,
        completedSwaps: completedSwaps,
        averageRating: averageRating,
      );

      _learningRoadmap = roadmap;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── Toggle Roadmap Task ─────────────────────────────────────────────
  Future<void> toggleRoadmapTask(String taskId, bool isCompleted) async {
    try {
      await _roadmapService.toggleTaskCompletion(taskId, isCompleted);
      
      // Reload only the roadmap to update UI dynamically without full reload
      final roadmap = await _roadmapService.getLatestRoadmap();
      _learningRoadmap = roadmap;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── Submit Feedback ─────────────────────────────────────────────────
  Future<void> submitFeedback(String recId, String type, int rating, String comment) async {
    try {
      await _service.submitFeedback(recId, type, rating, comment);
    } catch (e) {
      debugPrint('AIRecommendationProvider.submitFeedback error: $e');
    }
  }
}

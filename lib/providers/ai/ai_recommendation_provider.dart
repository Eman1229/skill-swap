// lib/providers/ai/ai_recommendation_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/models/ai/career_recommendation.dart';
import 'package:skill_swap/models/ai/mentor_recommendation.dart';
import 'package:skill_swap/models/ai/learning_roadmap_model.dart';
import 'package:skill_swap/models/ai/ai_analytics_snapshot.dart';
import 'package:skill_swap/services/ai/ai_recommendation_service.dart';
import 'package:skill_swap/services/ai/learning_roadmap_service.dart';
import 'package:skill_swap/repositories/ai/ai_recommendation_repository.dart';
import 'package:skill_swap/services/skill_exchange_service.dart';
import 'package:skill_swap/services/ai/ai_profile_service.dart';

class AIRecommendationProvider extends ChangeNotifier {
  final AIRecommendationService _service = AIRecommendationService();
  final LearningRoadmapService _roadmapService = LearningRoadmapService();
  final AIRecommendationRepository _repository = AIRecommendationRepository();
  final AIProfileService _profileService = AIProfileService();

  List<MentorRecommendation> _mentorRecommendations = [];
  CareerRecommendation? _careerRecommendation;
  LearningRoadmapModel? _learningRoadmap;
  AIAnalyticsSnapshot? _analyticsSnapshot;
  bool _isLoading = false;
  String? _error;
  AIUserProfile? _aiProfile;

  StreamSubscription<DocumentSnapshot>? _userSubscription;
  int? _lastCompletedSwaps;
  List<String>? _lastLearningSkills;
  String? _lastActivitySignature;

  List<MentorRecommendation> get mentorRecommendations => _mentorRecommendations;
  CareerRecommendation? get careerRecommendation => _careerRecommendation;
  LearningRoadmapModel? get learningRoadmap => _learningRoadmap;
  AIAnalyticsSnapshot? get analyticsSnapshot => _analyticsSnapshot;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AIUserProfile? get aiProfile => _aiProfile;
  bool get isEligibleForAI => _aiProfile?.isEligibleForRecommendations ?? false;
  int get completedSwaps => _aiProfile?.completedSwaps ?? 0;

  // ── Load All Data ───────────────────────────────────────────────────
  Future<void> loadRecommendations({String? uid}) async {
    debugPrint('[AI Provider] loadRecommendations called (uid: $uid)');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (uid != null) {
        debugPrint('[AI Provider] Syncing user profile stats for $uid');
        await SkillExchangeService().syncUserProfile(uid);
        _aiProfile = await _profileService.buildProfile(uid);
      }

      debugPrint('[AI Provider] Fetching latest recommendations from Firestore...');
      final eligible = _aiProfile?.isEligibleForRecommendations ?? false;
      final mentors = eligible ? await _service.getLatestMentors() : <MentorRecommendation>[];
      final career = eligible ? await _service.getLatestCareer() : null;
      final roadmap = eligible ? await _service.getLatestRoadmap() : null;
      
      _mentorRecommendations = mentors;
      _careerRecommendation = career;
      _learningRoadmap = roadmap;
      debugPrint('[AI Provider] Loaded: ${mentors.length} mentors, career: ${career != null ? "Found" : "Null"}, roadmap: ${roadmap != null ? "Found" : "Null"}');

      if (uid != null) {
        _analyticsSnapshot = await _repository.getLatestAnalyticsSnapshot(uid);

        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final userData = userDoc.data() ?? {};
        _lastCompletedSwaps = (userData['completedSwaps'] as num?)?.toInt() ?? 0;
        _lastLearningSkills = List<String>.from(userData['learningSkills'] ?? []);
        _lastActivitySignature = _activitySignature(userData);

        debugPrint('[AI Provider] Initializing listener with lastCompletedSwaps: $_lastCompletedSwaps, skills count: ${_lastLearningSkills?.length}');
        listenToUserChanges(uid);
      }

      if (eligible && career == null && uid != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final userData = userDoc.data() ?? {};
        final completedSwaps = (userData['completedSwaps'] as num?)?.toInt() ?? 0;
        debugPrint('[AI Provider] No career recommendation yet. User completedSwaps count: $completedSwaps');
        if (completedSwaps >= kMinCompletedSwapsForAI) {
          debugPrint('[AI Provider] User has completed swaps but no career analysis. Force-refreshing recommendations...');
          _isLoading = false;
          await refreshRecommendations(uid: uid, force: true);
          return;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[AI Provider] loadRecommendations error: $e\n$stack');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── Refresh/Regenerate ──────────────────────────────────────────────
  Future<void> refreshRecommendations({String? careerGoal, bool force = false, String? uid}) async {
    debugPrint('[AI Provider] refreshRecommendations called (force: $force, uid: $uid)');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final activeUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
      if (activeUid != null) {
        await SkillExchangeService().syncUserProfile(activeUid);
        _aiProfile = await _profileService.buildProfile(activeUid);
        if (!_aiProfile!.isEligibleForRecommendations) {
          _mentorRecommendations = [];
          _careerRecommendation = null;
          _learningRoadmap = null;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
      debugPrint('[AI Provider] Calling service refreshIfStale (force: $force)...');
      await _service.refreshIfStale(careerGoal: careerGoal, force: force);
      
      debugPrint('[AI Provider] Fetching latest recommendations after refresh...');
      final mentors = await _service.getLatestMentors();
      final career = await _service.getLatestCareer();
      final roadmap = await _service.getLatestRoadmap();

      _mentorRecommendations = mentors;
      _careerRecommendation = career;
      _learningRoadmap = roadmap;
      debugPrint('[AI Provider] Post-refresh Loaded: ${mentors.length} mentors, career: ${career != null ? "Found" : "Null"}, roadmap: ${roadmap != null ? "Found" : "Null"}');

      if (activeUid != null) {
        _analyticsSnapshot = await _repository.getLatestAnalyticsSnapshot(activeUid);

        final userDoc = await FirebaseFirestore.instance.collection('users').doc(activeUid).get();
        final userData = userDoc.data() ?? {};
        _lastCompletedSwaps = (userData['completedSwaps'] as num?)?.toInt() ?? 0;
        _lastLearningSkills = List<String>.from(userData['learningSkills'] ?? []);
        _lastActivitySignature = _activitySignature(userData);
        debugPrint('[AI Provider] Reset listener tracking fields to swaps: $_lastCompletedSwaps, skills: ${_lastLearningSkills?.length}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[AI Provider] refreshRecommendations error: $e\n$stack');
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
    debugPrint('[AI Provider] generateRoadmap called for "${careerPath.title}"');
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
      debugPrint('[AI Provider] Roadmap generated successfully for target: ${roadmap.targetCareer}');
      _isLoading = false;
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[AI Provider] generateRoadmap error: $e\n$stack');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── Toggle Roadmap Task ─────────────────────────────────────────────
  Future<void> toggleRoadmapTask(String taskId, bool isCompleted) async {
    debugPrint('[AI Provider] toggleRoadmapTask called (taskId: $taskId, isCompleted: $isCompleted)');
    
    final originalRoadmap = _learningRoadmap;
    
    // 1. Perform Optimistic Update locally in memory
    if (_learningRoadmap != null) {
      try {
        final updatedStages = _learningRoadmap!.stages.map((stage) {
          final hasTask = stage.tasks.any((t) => t.id == taskId);
          if (!hasTask) return stage;

          final updatedTasks = stage.tasks.map((task) {
            if (task.id == taskId) {
              return task.copyWith(isCompleted: isCompleted);
            }
            return task;
          }).toList();

          final completedCount = updatedTasks.where((t) => t.isCompleted).length;
          final totalCount = updatedTasks.isEmpty ? 1 : updatedTasks.length;
          final completionPercent = completedCount / totalCount;

          return stage.copyWith(
            tasks: updatedTasks,
            completionPercent: completionPercent,
          );
        }).toList();

        final updatedMilestones = _learningRoadmap!.milestones.map((milestone) {
          final stage = updatedStages.firstWhere(
            (s) => s.stageNumber == milestone.stageNumber,
            orElse: () => updatedStages.first,
          );
          final allStageCompleted = stage.tasks.isNotEmpty && stage.tasks.every((t) => t.isCompleted);
          return milestone.copyWith(isCompleted: allStageCompleted);
        }).toList();

        _learningRoadmap = _learningRoadmap!.copyWith(
          stages: updatedStages,
          milestones: updatedMilestones,
        );
        notifyListeners();
      } catch (e) {
        debugPrint('[AI Provider] Optimistic update failed: $e');
      }
    }

    try {
      // 2. Perform actual database write in the background
      await _roadmapService.toggleTaskCompletion(taskId, isCompleted);
      
      // 3. Silently fetch database ground truth to ensure absolute alignment
      final roadmap = await _roadmapService.getLatestRoadmap();
      if (roadmap != null) {
        _learningRoadmap = roadmap;
        notifyListeners();
      }
    } catch (e, stack) {
      debugPrint('[AI Provider] toggleRoadmapTask error: $e\n$stack');
      _error = e.toString();
      
      // Rollback to original state on failure
      _learningRoadmap = originalRoadmap;
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

  // ── Firestore Stats Realtime Listener ───────────────────────────────
  void listenToUserChanges(String uid) {
    _userSubscription?.cancel();
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? {};
      final completedSwaps = (data['completedSwaps'] as num?)?.toInt() ?? 0;
      final learningSkills = List<String>.from(data['learningSkills'] ?? []);
      final activitySignature = _activitySignature(data);

      if (_lastCompletedSwaps != null &&
          (completedSwaps > _lastCompletedSwaps! ||
           !_listsEqual(learningSkills, _lastLearningSkills ?? []) ||
           activitySignature != _lastActivitySignature)) {
        debugPrint('[AI Provider] Detected completed swaps or learning skills change in Firestore. Auto-refreshing recommendations.');
        _lastCompletedSwaps = completedSwaps;
        _lastLearningSkills = learningSkills;
        _lastActivitySignature = activitySignature;

        // Perform a background refresh of recommendations dynamically
        // A changed profile/activity signal needs a new prompt even when the
        // cache has not yet aged out.
        Future.microtask(() => refreshRecommendations(uid: uid, force: true));
      }
    });
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

  String _activitySignature(Map<String, dynamic> data) {
    const fields = [
      'learningSkills', 'teachingSkills', 'interests', 'careerInterests',
      'careerGoal', 'targetCareer', 'goal', 'learningHours', 'teachingHours',
      'learningStreak', 'averageRating', 'rating', 'totalAchievements',
      'unlockedBadges', 'successRate', 'bio', 'headline', 'about', 'location',
    ];
    return fields.map((field) => '$field:${data[field] ?? ''}').join('|');
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}

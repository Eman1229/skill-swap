// lib/services/ai/learning_roadmap_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_swap/models/ai/learning_roadmap_model.dart';
import 'package:skill_swap/services/ai/ai_profile_service.dart';
import 'package:skill_swap/services/ai/openai_service.dart';

class LearningRoadmapService {
  static final LearningRoadmapService _instance = LearningRoadmapService._internal();
  factory LearningRoadmapService() => _instance;
  LearningRoadmapService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OpenAIService _openai = OpenAIService();
  final AIProfileService _profileService = AIProfileService();

  Future<LearningRoadmapModel> generateRoadmap({
    required String targetCareer,
    required List<String> currentSkills,
    required List<String> missingSkills,
    required double learningHours,
    required int completedSwaps,
    required double averageRating,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return LearningRoadmapModel.empty();

    try {
      final profile = await _profileService.buildProfile(uid);
      if (!profile.isEligibleForRecommendations) {
        throw StateError(
          'Complete at least $kMinCompletedSwapsForAI successful swaps to unlock your learning roadmap.',
        );
      }

      final mergedSkills = profile.allSkills.isNotEmpty ? profile.allSkills : currentSkills;

      final result = await _openai.generateLearningRoadmap(
        targetCareer: targetCareer,
        currentSkills: mergedSkills,
        missingSkills: missingSkills,
        learningHours: learningHours > 0 ? learningHours : profile.learningHours,
        completedSwaps: completedSwaps > 0 ? completedSwaps : profile.completedSwaps,
        averageRating: averageRating > 0 ? averageRating : profile.averageRating,
        interests: profile.interests,
        recentSwapHistory: profile.recentSwapHistory,
        profileSummary: profile.profileSummary,
        skillsTeaching: profile.skillsTeaching,
      );

      final id = result['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
      return LearningRoadmapModel.fromMap(result, id);
    } catch (e, stack) {
      debugPrint('LearningRoadmapService.generateRoadmap error: $e\n$stack');
      rethrow;
    }
  }

  /// Fetches the latest roadmap with progress merged.
  Future<LearningRoadmapModel?> getLatestRoadmap() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      final profile = await _profileService.buildProfile(uid);
      if (!profile.isEligibleForRecommendations) return null;

      final metaDoc = await _db.collection('learning_roadmaps').doc(uid).get();
      if (!metaDoc.exists) return null;

      final latestId = metaDoc.data()?['latestId'] as String?;
      if (latestId == null) return null;

      final roadmapDoc = await _db
          .collection('learning_roadmaps')
          .doc(uid)
          .collection('history')
          .doc(latestId)
          .get();

      if (!roadmapDoc.exists) return null;

      final roadmapData = roadmapDoc.data()!;
      if (roadmapData['createdAt'] is Timestamp) {
        roadmapData['createdAt'] = (roadmapData['createdAt'] as Timestamp).toDate();
      }

      final progressDoc = await _db.collection('roadmap_progress').doc(uid).get();
      RoadmapProgress progress;
      if (!progressDoc.exists || (progressDoc.data()?['currentRoadmapId'] as String? ?? '').isEmpty) {
        final initialProgress = {
          'currentRoadmapId': latestId,
          'completedTaskIds': progressDoc.exists ? List<String>.from(progressDoc.data()?['completedTaskIds'] ?? []) : <String>[],
          'completedMilestoneIds': progressDoc.exists ? List<String>.from(progressDoc.data()?['completedMilestoneIds'] ?? []) : <String>[],
          'overallPercent': progressDoc.exists ? (progressDoc.data()?['overallPercent'] as num?)?.toDouble() ?? 0.0 : 0.0,
          'currentStage': progressDoc.exists ? (progressDoc.data()?['currentStage'] as num?)?.toInt() ?? 1 : 1,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await _db.collection('roadmap_progress').doc(uid).set(initialProgress, SetOptions(merge: true));
        progress = RoadmapProgress.fromMap(initialProgress);
      } else {
        progress = RoadmapProgress.fromMap(progressDoc.data()!);
      }

      final baseRoadmap = LearningRoadmapModel.fromMap(roadmapData, roadmapDoc.id);

      final updatedStages = baseRoadmap.stages.map((stage) {
        final updatedTasks = stage.tasks.map((task) {
          final isCompleted = progress.completedTaskIds.contains(task.id);
          return task.copyWith(isCompleted: isCompleted);
        }).toList();

        final completedCount = updatedTasks.where((t) => t.isCompleted).length;
        final totalCount = updatedTasks.isEmpty ? 1 : updatedTasks.length;
        final completionPercent = completedCount / totalCount;

        return stage.copyWith(
          tasks: updatedTasks,
          completionPercent: completionPercent,
        );
      }).toList();

      final updatedMilestones = baseRoadmap.milestones.map((milestone) {
        final isCompleted = progress.completedMilestoneIds.contains(milestone.id);
        return milestone.copyWith(isCompleted: isCompleted);
      }).toList();

      return baseRoadmap.copyWith(
        stages: updatedStages,
        milestones: updatedMilestones,
      );
    } catch (e) {
      debugPrint('LearningRoadmapService.getLatestRoadmap error: $e');
      return null;
    }
  }

  /// Toggles task completion in Firestore and updates overall progress metrics.
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final progressRef = _db.collection('roadmap_progress').doc(uid);

      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(progressRef);
        final data = snapshot.exists ? snapshot.data()! : {};

        final completedTaskIds = List<String>.from(data['completedTaskIds'] ?? []);
        final completedMilestoneIds = List<String>.from(data['completedMilestoneIds'] ?? []);
        final currentRoadmapId = data['currentRoadmapId'] as String? ?? '';

        if (isCompleted) {
          if (!completedTaskIds.contains(taskId)) {
            completedTaskIds.add(taskId);
          }
        } else {
          completedTaskIds.remove(taskId);
        }

        if (currentRoadmapId.isNotEmpty) {
          final roadmapRef = _db
              .collection('learning_roadmaps')
              .doc(uid)
              .collection('history')
              .doc(currentRoadmapId);

          final roadmapSnap = await transaction.get(roadmapRef);
          if (roadmapSnap.exists) {
            final roadmapData = roadmapSnap.data()!;
            final baseRoadmap = LearningRoadmapModel.fromMap(roadmapData, roadmapSnap.id);

            final allTasks = baseRoadmap.stages.expand((s) => s.tasks).toList();
            final totalTasks = allTasks.length;

            final double overallPercent = totalTasks == 0
                ? 0.0
                : completedTaskIds.length / totalTasks;

            for (final stage in baseRoadmap.stages) {
              final stageTaskIds = stage.tasks.map((t) => t.id).toList();

              final allStageTasksCompleted = stageTaskIds.isNotEmpty &&
                  stageTaskIds.every((tid) => completedTaskIds.contains(tid));

              final milestone = baseRoadmap.milestones.firstWhere(
                (m) => m.stageNumber == stage.stageNumber,
                orElse: () => RoadmapMilestone(
                  id: 'dummy',
                  title: '',
                  description: '',
                  stageNumber: stage.stageNumber,
                  icon: 'school',
                  isCompleted: false,
                ),
              );

              if (milestone.id != 'dummy') {
                if (allStageTasksCompleted) {
                  if (!completedMilestoneIds.contains(milestone.id)) {
                    completedMilestoneIds.add(milestone.id);
                  }
                } else {
                  completedMilestoneIds.remove(milestone.id);
                }
              }
            }

            int currentStage = 1;
            for (final stage in baseRoadmap.stages) {
              final stageTaskIds = stage.tasks.map((t) => t.id).toList();
              final isStageCompleted = stageTaskIds.isNotEmpty &&
                  stageTaskIds.every((tid) => completedTaskIds.contains(tid));

              if (!isStageCompleted) {
                currentStage = stage.stageNumber;
                break;
              }
              currentStage = stage.stageNumber;
            }

            transaction.set(progressRef, {
              'currentStage': currentStage,
              'completedTaskIds': completedTaskIds,
              'completedMilestoneIds': completedMilestoneIds,
              'overallPercent': overallPercent,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        } else {
          transaction.set(progressRef, {
            'completedTaskIds': completedTaskIds,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });
    } catch (e) {
      debugPrint('LearningRoadmapService.toggleTaskCompletion error: $e');
      rethrow;
    }
  }

  /// Toggles milestone completion manually (fallback if needed).
  Future<void> toggleMilestoneCompletion(String milestoneId, bool isCompleted) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final progressRef = _db.collection('roadmap_progress').doc(uid);
      await progressRef.update({
        'completedMilestoneIds': isCompleted
            ? FieldValue.arrayUnion([milestoneId])
            : FieldValue.arrayRemove([milestoneId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('LearningRoadmapService.toggleMilestoneCompletion error: $e');
    }
  }
}

// lib/services/ai/learning_roadmap_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_swap/models/ai/learning_roadmap_model.dart';
import 'package:skill_swap/services/ai/openai_service.dart';

class LearningRoadmapService {
  static final LearningRoadmapService _instance = LearningRoadmapService._internal();
  factory LearningRoadmapService() => _instance;
  LearningRoadmapService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OpenAIService _openai = OpenAIService();

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
      final result = await _openai.generateLearningRoadmap(
        targetCareer: targetCareer,
        currentSkills: currentSkills,
        missingSkills: missingSkills,
        learningHours: learningHours,
        completedSwaps: completedSwaps,
        averageRating: averageRating,
      );

      final id = result['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Clear local SharedPreferences or database progress on new roadmap if desired
      // (The Cloud Function already initializes progress in Firestore)
      
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
      // 1. Get the latest roadmap metadata pointer
      final metaDoc = await _db.collection('learning_roadmaps').doc(uid).get();
      if (!metaDoc.exists) return null;

      final latestId = metaDoc.data()?['latestId'] as String?;
      if (latestId == null) return null;

      // 2. Fetch the roadmap history document
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

      // 3. Fetch current progress
      final progressDoc = await _db.collection('roadmap_progress').doc(uid).get();
      final progress = progressDoc.exists
          ? RoadmapProgress.fromMap(progressDoc.data()!)
          : RoadmapProgress.empty();

      // 4. Map and apply progress to stages and tasks
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

        // Fetch roadmap details to recalculate percentage and milestones
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

            // 1. Gather all tasks in the roadmap
            final allTasks = baseRoadmap.stages.expand((s) => s.tasks).toList();
            final totalTasks = allTasks.length;
            
            // Calculate overall percentage
            final double overallPercent = totalTasks == 0
                ? 0.0
                : completedTaskIds.length / totalTasks;

            // 2. Automatically complete milestones when all tasks of that stage are completed
            for (final stage in baseRoadmap.stages) {
              final stageTasks = stage.tasks;
              final stageTaskIds = stageTasks.map((t) => t.id).toList();
              
              final allStageTasksCompleted = stageTaskIds.isNotEmpty &&
                  stageTaskIds.every((tid) => completedTaskIds.contains(tid));

              // Find milestone for this stage
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

            // Determine current active stage (lowest stage number containing incomplete tasks)
            int currentStage = 1;
            for (final stage in baseRoadmap.stages) {
              final stageTaskIds = stage.tasks.map((t) => t.id).toList();
              final isStageCompleted = stageTaskIds.isNotEmpty &&
                  stageTaskIds.every((tid) => completedTaskIds.contains(tid));
              
              if (!isStageCompleted) {
                currentStage = stage.stageNumber;
                break;
              }
              // If all stages completed, currentStage is the last stage
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
          // If no roadmap yet, just write raw completion list
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

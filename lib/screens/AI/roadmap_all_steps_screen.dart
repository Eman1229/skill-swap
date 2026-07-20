// lib/screens/AI/roadmap_all_steps_screen.dart

import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_swap/providers/ai/ai_recommendation_provider.dart';
import 'package:skill_swap/models/ai/learning_roadmap_model.dart';

class RoadmapAllStepsScreen extends StatelessWidget {
  const RoadmapAllStepsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final provider = Provider.of<AIRecommendationProvider>(context);
    final roadmap = provider.learningRoadmap;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Journey Steps',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: roadmap == null
          ? Center(child: Text('no_active_roadmap_found'.tr()))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: roadmap.stages.length,
              itemBuilder: (context, index) {
                final stage = roadmap.stages[index];
                
                // Determine lock state
                // Stage 1 is always unlocked. Stage N is unlocked if Stage N-1 is completed.
                bool isUnlocked = true;
                if (index > 0) {
                  final prevStage = roadmap.stages[index - 1];
                  isUnlocked = prevStage.completionPercent >= 1.0;
                }

                return _buildTimelineStep(
                  context,
                  stage,
                  index + 1,
                  roadmap.stages.length,
                  isUnlocked,
                  isDark,
                  primaryColor,
                );
              },
            ),
    );
  }

  Widget _buildTimelineStep(
    BuildContext context,
    RoadmapStage stage,
    int stageNum,
    int totalStages,
    bool isUnlocked,
    bool isDark,
    Color primaryColor,
  ) {
    final isCompleted = stage.completionPercent >= 1.0;
    final inProgress = stage.completionPercent > 0.0 && stage.completionPercent < 1.0;

    final Color statusColor = isCompleted
        ? const Color(0xFF10B981)
        : (inProgress ? primaryColor : Colors.grey);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left Timeline Graphics ────────────────────────────────────
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? statusColor.withValues(alpha: 0.12)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked ? statusColor : Colors.grey,
                  width: 1.5,
                ),
              ),
              child: isUnlocked
                  ? (isCompleted
                      ? const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 18)
                      : Text(
                          '$stageNum',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ))
                  : const Icon(Icons.lock_rounded, color: Colors.grey, size: 14),
            ),
            if (stageNum < totalStages)
              Container(
                width: 2.0,
                height: 140, // Height of space between timeline icons
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
          ],
        ),
        const SizedBox(width: 16),

        // ── Right Content Card ────────────────────────────────────────
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnlocked
                    ? (inProgress ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)))
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STAGE $stageNum',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      '${stage.estimatedWeeks} Weeks',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  stage.stageName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  stage.description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 12),

                // Tasks Preview header
                Text(
                  'TASKS (${stage.tasks.where((t) => t.isCompleted).length}/${stage.tasks.length})',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                // Small preview of tasks
                ...stage.tasks.take(3).map((task) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            task.isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            size: 14,
                            color: task.isCompleted ? const Color(0xFF10B981) : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                color: task.isCompleted ? Colors.grey : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (stage.tasks.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      '+ ${stage.tasks.length - 3} more tasks',
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ).opacity(isUnlocked ? 1.0 : 0.5),
        ),
      ],
    );
  }
}

// Extension to apply opacity to Container decoration in older flutter versions if needed
extension on Container {
  Widget opacity(double value) {
    if (value == 1.0) return this;
    return Opacity(opacity: value, child: this);
  }
}

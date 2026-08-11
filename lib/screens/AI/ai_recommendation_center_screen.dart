// lib/screens/AI/ai_recommendation_center_screen.dart

import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/providers/ai/ai_recommendation_provider.dart';
import 'package:skill_swap/screens/AI/mentor_compass_screen.dart';
import 'package:skill_swap/screens/AI/career_compass_screen.dart';
import 'package:skill_swap/screens/AI/learning_roadmap_screen.dart';
import 'package:skill_swap/services/ai/ai_profile_service.dart';

class AIRecommendationCenterScreen extends StatefulWidget {
  const AIRecommendationCenterScreen({super.key});

  @override
  State<AIRecommendationCenterScreen> createState() => _AIRecommendationCenterScreenState();
}

class _AIRecommendationCenterScreenState extends State<AIRecommendationCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      Provider.of<AIRecommendationProvider>(context, listen: false)
          .refreshRecommendations(uid: uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final provider = Provider.of<AIRecommendationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isEligible = provider.isEligibleForAI;
    final completedSwaps = provider.completedSwaps;
    final remaining = (kMinCompletedSwapsForAI - completedSwaps).clamp(0, kMinCompletedSwapsForAI);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Recommendation Center',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              provider.refreshRecommendations(force: true, uid: uid);
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Analyzing your skills and profiles...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Banner ─────────────────────────────────────
                  _buildHeroBanner(primaryColor, isDark, isEligible, remaining),
                  const SizedBox(height: 20),

                  // ── Section Title ───────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Modules',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Mentor Compass Card (Always Active) ─────────────
                  _buildAIModuleCard(
                    title: 'mentor_compass'.tr(),
                    description: 'Get matched with top mentors based on skill compatibility and ratings.',
                    icon: Icons.explore_rounded,
                    badgeText: provider.mentorRecommendations.isNotEmpty
                        ? '${provider.mentorRecommendations.length} MATCHES'
                        : 'COMPUTE',
                    gradientColors: [const Color(0xFF00C2FF), const Color(0xFF6B8AFF)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MentorCompassScreen()),
                      );
                    },
                    extraInfo: provider.mentorRecommendations.isNotEmpty
                        ? 'Best match: ${provider.mentorRecommendations.first.matchScore.round()}% compatibility'
                        : 'Match based on your wanted skills',
                    isLocked: false,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),

                  // ── Career Compass Card (Locked for new users) ──────
                  isEligible
                      ? _buildAIModuleCard(
                          title: 'career_compass'.tr(),
                          description: 'Analyze your skillset against market demands to find the best career paths.',
                          icon: Icons.track_changes_rounded,
                          badgeText: provider.careerRecommendation != null
                              ? '${provider.careerRecommendation!.careers.length} PATHS'
                              : 'ANALYZE',
                          gradientColors: [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CareerCompassScreen()),
                            );
                          },
                          extraInfo: provider.careerRecommendation != null && provider.careerRecommendation!.careers.isNotEmpty
                              ? 'Top choice: ${provider.careerRecommendation!.careers.first.title}'
                              : 'Explore trending roles for you',
                          isLocked: false,
                          isDark: isDark,
                        )
                      : _buildLockedModuleCard(
                          title: 'career_compass'.tr(),
                          description: 'Analyze your skillset against market demands to find the best career paths.',
                          icon: Icons.track_changes_rounded,
                          gradientColors: [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
                          completedSwaps: completedSwaps,
                          remaining: remaining,
                          isDark: isDark,
                        ),
                  const SizedBox(height: 16),

                  // ── Learning Roadmap Card (Locked for new users) ────
                  isEligible
                      ? _buildAIModuleCard(
                          title: 'learning_roadmap'.tr(),
                          description: 'Interactive step-by-step learning roadmap tailored to your target career.',
                          icon: Icons.map_rounded,
                          badgeText: provider.learningRoadmap != null
                              ? '${(provider.learningRoadmap!.stages.fold<double>(0, (sum, s) => sum + s.completionPercent) / (provider.learningRoadmap!.stages.isEmpty ? 1 : provider.learningRoadmap!.stages.length) * 100).round()}% DONE'
                              : 'PLANNER',
                          gradientColors: [const Color(0xFF10B981), const Color(0xFF3B82F6)],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LearningRoadmapScreen()),
                            );
                          },
                          extraInfo: provider.learningRoadmap != null
                              ? 'Target: ${provider.learningRoadmap!.targetCareer}'
                              : 'Generate custom stage-based plan',
                          isLocked: false,
                          isDark: isDark,
                        )
                      : _buildLockedModuleCard(
                          title: 'learning_roadmap'.tr(),
                          description: 'Interactive step-by-step learning roadmap tailored to your target career.',
                          icon: Icons.map_rounded,
                          gradientColors: [const Color(0xFF10B981), const Color(0xFF3B82F6)],
                          completedSwaps: completedSwaps,
                          remaining: remaining,
                          isDark: isDark,
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroBanner(Color primaryColor, bool isDark, bool isEligible, int remaining) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0B1F3B), const Color(0xFF1E293B)]
              : [const Color(0xFFE0F2FE), const Color(0xFFF0F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Empowered by AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEligible
                      ? 'Discover peer mentors, map career goals, and track your structured learning paths seamlessly.'
                      : 'Mentor Compass is active! Complete $remaining more swap${remaining == 1 ? '' : 's'} to unlock Career Compass & Learning Roadmap.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.4,
                  ),
                ),
                if (!isEligible) ...[
                  const SizedBox(height: 10),
                  _buildSwapProgressBar(2 - remaining, isDark, primaryColor),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwapProgressBar(int done, bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Swap Progress',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$done / $kMinCompletedSwapsForAI',
              style: TextStyle(
                fontSize: 10,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: done / kMinCompletedSwapsForAI,
            minHeight: 5,
            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      ],
    );
  }

  /// Active AI module card — clickable, full colour.
  Widget _buildAIModuleCard({
    required String title,
    required String description,
    required IconData icon,
    required String badgeText,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required String extraInfo,
    required bool isLocked,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: gradientColors.first.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: gradientColors.first,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD700), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    extraInfo,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Locked AI module card — greyed out with lock icon and swap progress.
  Widget _buildLockedModuleCard({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required int completedSwaps,
    required int remaining,
    required bool isDark,
  }) {
    final lockedGradient = [
      Colors.grey.shade500,
      Colors.grey.shade600,
    ];

    return Opacity(
      opacity: 0.65,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: lockedGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 11, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text(
                        'LOCKED',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white38 : Colors.black38,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.lock_clock_outlined, color: Colors.grey, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Complete $remaining more swap${remaining == 1 ? '' : 's'} to unlock — '
                    'then generated from your real skills & activity.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Swap progress indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completedSwaps / kMinCompletedSwapsForAI,
                minHeight: 4,
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$completedSwaps / $kMinCompletedSwapsForAI swaps completed',
              style: const TextStyle(fontSize: 9.5, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

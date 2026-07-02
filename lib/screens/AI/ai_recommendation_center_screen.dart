// lib/screens/AI/ai_recommendation_center_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/providers/ai/ai_recommendation_provider.dart';
import 'package:skill_swap/screens/AI/mentor_compass_screen.dart';
import 'package:skill_swap/screens/AI/career_compass_screen.dart';
import 'package:skill_swap/screens/AI/learning_roadmap_screen.dart';

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
    final provider = Provider.of<AIRecommendationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

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
                  _buildHeroBanner(primaryColor, isDark),
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

                  // ── Mentor Compass Card ─────────────────────────────
                  _buildAIModuleCard(
                    title: 'Mentor Compass',
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
                  ),
                  const SizedBox(height: 16),

                  // ── Career Compass Card ─────────────────────────────
                  _buildAIModuleCard(
                    title: 'Career Compass',
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
                  ),
                  const SizedBox(height: 16),

                  // ── Learning Roadmap Card ───────────────────────────
                  _buildAIModuleCard(
                    title: 'Learning Roadmap',
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
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroBanner(Color primaryColor, bool isDark) {
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
                  'Discover peer mentors, map career goals, and track your structured learning paths seamlessly.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIModuleCard({
    required String title,
    required String description,
    required IconData icon,
    required String badgeText,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required String extraInfo,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFFFD700),
                  size: 14,
                ),
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
}

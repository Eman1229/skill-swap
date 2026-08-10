// lib/screens/AI/career_compass_screen.dart

import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/providers/ai/ai_recommendation_provider.dart';
import 'package:skill_swap/models/ai/career_recommendation.dart';
import 'package:skill_swap/screens/AI/learning_roadmap_screen.dart';
import 'package:skill_swap/repositories/ai/ai_recommendation_repository.dart';
import 'package:skill_swap/services/ai/ai_profile_service.dart';

class CareerCompassScreen extends StatefulWidget {
  const CareerCompassScreen({super.key});

  @override
  State<CareerCompassScreen> createState() => _CareerCompassScreenState();
}

class _CareerCompassScreenState extends State<CareerCompassScreen> {
  bool _isGeneratingRoadmap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<AIRecommendationProvider>(context, listen: false);
      if (provider.careerRecommendation == null && !provider.isLoading) {
        provider.loadRecommendations(
          uid: FirebaseAuth.instance.currentUser?.uid,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final provider = Provider.of<AIRecommendationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('career_compass'.tr(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isGeneratingRoadmap
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Building your personalized learning roadmap...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : provider.isLoading
              ? Center(
                  child: CircularProgressIndicator(color: primaryColor),
                )
              : !provider.isEligibleForAI
                  ? _buildUnlockState(context, isDark, provider.completedSwaps)
                  : provider.careerRecommendation == null || provider.careerRecommendation!.careers.isEmpty
                      ? _buildEmptyState(context, isDark)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Summary Card ──────────────────────────────────
                          _buildSummaryCard(provider.careerRecommendation!, isDark, primaryColor),
                          const SizedBox(height: 24),

                          // ── Career Paths List ─────────────────────────────
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
                                'Recommended Career Paths',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          ...provider.careerRecommendation!.careers.map((career) {
                            return _buildCareerCard(context, provider, career, isDark, primaryColor);
                          }),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes_rounded,
              size: 72,
              color: isDark ? Colors.white30 : Colors.black.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Career Analysis Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete some swaps and log skills to get custom career suggestions.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockState(BuildContext context, bool isDark, int completedSwaps) {
    final remaining = (kMinCompletedSwapsForAI - completedSwaps).clamp(0, kMinCompletedSwapsForAI);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock_outline_rounded, size: 72, color: isDark ? Colors.white30 : Colors.black38),
          const SizedBox(height: 16),
          const Text('Career Compass unlocks after 2 successful swaps', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Complete $remaining more successful ${remaining == 1 ? 'swap' : 'swaps'} to receive a roadmap based on your actual skills, progress, and swap activity.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget _buildSummaryCard(
    CareerRecommendation recommendation,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, color: primaryColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Your AI Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.careerSummary,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 14),

          // Strength Areas
          const Text(
            'STRENGTH AREAS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recommendation.strengthAreas.map((s) => _buildSummaryChip(s, const Color(0xFF10B981), isDark)).toList(),
          ),
          const SizedBox(height: 14),

          // Growth Areas
          const Text(
            'GROWTH AREAS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recommendation.growthAreas.map((g) => _buildSummaryChip(g, const Color(0xFFF59E0B), isDark)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCareerCard(
    BuildContext context,
    AIRecommendationProvider provider,
    CareerPath career,
    bool isDark,
    Color primaryColor,
  ) {
    final demandColor = career.demandIndicator.toLowerCase() == 'high'
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.06),
                  spreadRadius: 1,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: Title, Fit % ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        career.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: demandColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${career.demandIndicator.toUpperCase()} DEMAND',
                              style: TextStyle(
                                color: demandColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            career.salaryRange,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor, width: 2),
                    color: primaryColor.withValues(alpha: 0.05),
                  ),
                  child: Text(
                    '${career.fitScore}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              career.description,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Required vs Missing Skills ──────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Required
                const Text(
                  'REQUIRED SKILLS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: career.requiredSkills.map((s) => _buildSkillChip(s, isDark, false)).toList(),
                ),
                const SizedBox(height: 14),

                // Missing
                const Text(
                  'MISSING SKILLS (GAPS)',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: career.missingSkills.map((s) => _buildSkillChip(s, isDark, true)).toList(),
                ),
              ],
            ),
          ),

          // ── Footer CTA: Generate Roadmap ─────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '~${career.estimatedLearningMonths} months prep',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _handleRoadmapTap(context, provider, career),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.learningRoadmap?.targetCareer == career.title
                            ? 'Open Roadmap'
                            : 'Generate Roadmap',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String label, bool isDark, bool isMissing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMissing
            ? const Color(0xFFEF4444).withValues(alpha: 0.1)
            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMissing
              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
              : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isMissing ? const Color(0xFFEF4444) : (isDark ? Colors.white70 : Colors.black87),
          fontSize: 11,
          fontWeight: isMissing ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _handleRoadmapTap(
    BuildContext context,
    AIRecommendationProvider provider,
    CareerPath career,
  ) async {
    // If we already have a generated roadmap for this career title, navigate directly
    if (provider.learningRoadmap != null &&
        provider.learningRoadmap!.targetCareer.toLowerCase() == career.title.toLowerCase()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LearningRoadmapScreen()),
      );
      return;
    }

    // Otherwise, generate the roadmap
    setState(() {
      _isGeneratingRoadmap = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final snap = provider.analyticsSnapshot ?? (uid != null ? await AIRecommendationRepository().getLatestAnalyticsSnapshot(uid) : null);
      
      final learningHours = snap?.learningHours ?? 0.0;
      final completedSwaps = snap?.projectsCompleted ?? 0;
      final avgRating = snap?.sessionSuccessRate != null ? (snap!.sessionSuccessRate * 5.0) : 5.0;

      // Fetch user's current skills from Firestore to build embedding
      List<String> currentSkills = [];
      if (uid != null) {
        final uDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        currentSkills = List<String>.from(uDoc.data()?['learningSkills'] ?? []);
      }

      await provider.generateRoadmap(
        careerPath: career,
        currentSkills: currentSkills,
        learningHours: learningHours,
        completedSwaps: completedSwaps,
        averageRating: avgRating,
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LearningRoadmapScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${'failed_generate_roadmap'.tr()}: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingRoadmap = false;
        });
      }
    }
  }
}

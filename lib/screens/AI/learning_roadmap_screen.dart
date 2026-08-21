// lib/screens/AI/learning_roadmap_screen.dart

import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/providers/ai/ai_recommendation_provider.dart';
import 'package:skill_swap/models/ai/learning_roadmap_model.dart';
import 'package:skill_swap/screens/AI/career_compass_screen.dart';
import 'package:skill_swap/screens/AI/roadmap_all_steps_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skill_swap/services/ai/ai_profile_service.dart';
import 'package:skill_swap/theme/app_theme.dart';

class LearningRoadmapScreen extends StatefulWidget {
  const LearningRoadmapScreen({super.key});

  @override
  State<LearningRoadmapScreen> createState() => _LearningRoadmapScreenState();
}

class _LearningRoadmapScreenState extends State<LearningRoadmapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<AIRecommendationProvider>(context, listen: false);
      if (provider.learningRoadmap == null && !provider.isLoading) {
        provider.loadRecommendations(
          uid: FirebaseAuth.instance.currentUser?.uid,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final provider = Provider.of<AIRecommendationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (provider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('learning_roadmap'.tr(), textAlign: TextAlign.center),
          centerTitle: true,
        ),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    // ── Lock state: user hasn't completed 2 swaps yet ──────────────────
    if (!provider.isEligibleForAI) {
      return _buildLockedScreen(context, isDark, primaryColor, provider.completedSwaps);
    }

    final roadmap = provider.learningRoadmap;
    if (roadmap == null || roadmap.stages.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('learning_roadmap'.tr(), textAlign: TextAlign.center),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_rounded, size: 72, color: isDark ? Colors.white24 : Colors.black26),
                const SizedBox(height: 16),
                const Text(
                  'No Roadmap Found',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CareerCompassScreen()),
                    );
                  },
                  child: const Text(
                    'Go to the Career Compass screen and click "Generate Roadmap" for a career path.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Calculate total progress
    final totalStages = roadmap.stages.length;
    final double overallProgress = roadmap.stages.fold<double>(0.0, (sum, stage) => sum + stage.completionPercent) / (totalStages == 0 ? 1 : totalStages);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          roadmap.targetCareer,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          indicatorColor: primaryColor,
          labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Steps'),
            Tab(text: 'Resources'),
            Tab(text: 'Milestones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(roadmap, overallProgress, isDark, primaryColor),
          _buildStepsTab(provider, roadmap, isDark, primaryColor),
          _buildResourcesTab(roadmap, isDark, primaryColor),
          _buildMilestonesTab(provider, roadmap, isDark, primaryColor),
        ],
      ),
    );
  }

  // ── Lock State Screen ────────────────────────────────────────────────
  Widget _buildLockedScreen(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    int completedSwaps,
  ) {
    final remaining = (kMinCompletedSwapsForAI - completedSwaps).clamp(0, kMinCompletedSwapsForAI);

    return Scaffold(
      appBar: AppBar(
        title: Text('learning_roadmap'.tr(), textAlign: TextAlign.center),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock icon with gradient background
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFEFF6FF), const Color(0xFFDEEBFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFBFD7FF),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 44,
                  color: isDark ? Colors.white38 : Colors.blueGrey.shade300,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Learning Roadmap Locked',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Complete $remaining more swap${remaining == 1 ? '' : 's'} to unlock your personalised Learning Roadmap — built from your actual skills, completed swaps, and career goal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              // Progress bar
              AppGradientProgressBar(
                value: completedSwaps / kMinCompletedSwapsForAI,
                isCompleted: completedSwaps >= kMinCompletedSwapsForAI,
                height: 10,
              ),
              const SizedBox(height: 8),
              Text(
                '$completedSwaps / $kMinCompletedSwapsForAI swaps completed',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              // CTA button
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: const Text('Browse Mentors'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Overview Tab ────────────────────────────────────────────────────
  Widget _buildOverviewTab(
    LearningRoadmapModel roadmap,
    double overallProgress,
    bool isDark,
    Color primaryColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [const Color(0xFFEFF6FF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ROADMAP GOAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ON TRACK',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TranslatedText(
                  roadmap.targetCareer,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Estimated preparation: ${roadmap.estimatedMonths} Months',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall Completion',
                      style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                    Text(
                      '${(overallProgress * 100).round()}%',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppGradientProgressBar(
                  value: overallProgress,
                  isCompleted: overallProgress >= 1.0,
                  height: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Journey steps list
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Journey Steps',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RoadmapAllStepsScreen()),
                  );
                },
                child: Text('view_details'.tr()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: roadmap.stages.length,
            itemBuilder: (context, index) {
              final stage = roadmap.stages[index];
              return _buildStageOverviewItem(stage, index + 1, isDark, primaryColor);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStageOverviewItem(
    RoadmapStage stage,
    int stageNum,
    bool isDark,
    Color primaryColor,
  ) {
    final isCompleted = stage.completionPercent >= 1.0;
    final inProgress = stage.completionPercent > 0.0 && stage.completionPercent < 1.0;

    final Color statusColor = isCompleted
        ? const Color(0xFF10B981)
        : (inProgress ? primaryColor : Colors.grey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$stageNum',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  stage.stageName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  '${stage.estimatedWeeks} weeks • ${stage.tasks.length} tasks',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              stage.status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Steps Tab ───────────────────────────────────────────────────────
  Widget _buildStepsTab(
    AIRecommendationProvider provider,
    LearningRoadmapModel roadmap,
    bool isDark,
    Color primaryColor,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roadmap.stages.length,
      itemBuilder: (context, sIdx) {
        final stage = roadmap.stages[sIdx];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            title: Text(
              'Stage ${stage.stageNumber}: ${stage.stageName}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${(stage.completionPercent * 100).round()}% Completed',
              style: TextStyle(fontSize: 11.5, color: primaryColor, fontWeight: FontWeight.bold),
            ),
            childrenPadding: const EdgeInsets.all(12),
            children: stage.tasks.map((task) {
              return CheckboxListTile(
                title: TranslatedText(
                  task.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                subtitle: TranslatedText(
                  task.description,
                  style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                ),
                value: task.isCompleted,
                activeColor: primaryColor,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) {
                  if (val != null) {
                    provider.toggleRoadmapTask(task.id, val);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ── Resources Tab ───────────────────────────────────────────────────
  Widget _buildResourcesTab(
    LearningRoadmapModel roadmap,
    bool isDark,
    Color primaryColor,
  ) {
    // Collect all resources across all stages
    final resources = roadmap.stages.expand((s) => s.resources).toList();

    if (resources.isEmpty) {
      return Center(child: Text('no_recommended_resources'.tr()));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final res = resources[index];
        IconData resIcon = Icons.library_books_rounded;
        if (res.type.toLowerCase() == 'video') resIcon = Icons.play_circle_outline_rounded;
        if (res.type.toLowerCase() == 'course') resIcon = Icons.school_rounded;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              if (res.url.isNotEmpty) {
                final uri = Uri.tryParse(res.url);
                if (uri != null) {
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open link: ${res.url}')),
                      );
                    }
                  }
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(resIcon, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          res.title,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${res.platform} • ${res.type}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${res.learnersCount}',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const Text(
                        'LEARNERS',
                        style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Milestones Tab ──────────────────────────────────────────────────
  Widget _buildMilestonesTab(
    AIRecommendationProvider provider,
    LearningRoadmapModel roadmap,
    bool isDark,
    Color primaryColor,
  ) {
    // Use real weeklyLearningHours from the saved AIAnalyticsSnapshot.
    // Default to all-zeros (not fake data) when no snapshot exists yet.
    final weeklyActivity = provider.analyticsSnapshot?.weeklyLearningHours ?? const {
      'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Insight Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_incandescent_rounded, color: Color(0xFFFFD700), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    roadmap.aiInsight,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Custom Painter activity line chart
          const Text(
            'Weekly Study Activity (Hours)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            height: 160,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CustomPaint(
              painter: _ActivityChartPainter(
                data: weeklyActivity,
                primaryColor: primaryColor,
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Milestones grid
          const Text(
            'Achieved Milestones',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: roadmap.milestones.length,
            itemBuilder: (context, idx) {
              final ms = roadmap.milestones[idx];
              return _buildMilestoneBadge(ms, isDark, primaryColor);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneBadge(
    RoadmapMilestone ms,
    bool isDark,
    Color primaryColor,
  ) {
    final msColor = ms.isCompleted ? const Color(0xFFFFD700) : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ms.isCompleted
              ? const Color(0xFFFFD700).withValues(alpha: 0.3)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            ms.isCompleted ? Icons.emoji_events_rounded : Icons.lock_rounded,
            color: msColor,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            ms.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'Stage ${ms.stageNumber}',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painter for study activity chart ───────────────────────────
class _ActivityChartPainter extends CustomPainter {
  final Map<String, int> data;
  final Color primaryColor;
  final bool isDark;

  _ActivityChartPainter({
    required this.data,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final days = data.keys.toList();
    final values = data.values.toList();

    final maxVal = values.fold<int>(4, (m, v) => v > m ? v : m).toDouble();

    final double widthBetweenPoints = size.width / (days.length - 1);
    final double scaleY = size.height / maxVal;

    final points = <Offset>[];
    for (int i = 0; i < days.length; i++) {
      final x = i * widthBetweenPoints;
      final y = size.height - (values[i] * scaleY * 0.85); // buffer bottom/top
      points.add(Offset(x, y));
    }

    // Draw Grid Lines (horizontal)
    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black12
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = size.height - (i * (size.height / 3));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw Fill Area (Gradient)
    final fillPath = Path()
      ..moveTo(0, size.height);
    for (final pt in points) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor.withValues(alpha: 0.35), primaryColor.withValues(alpha: 0.01)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Draw Line
    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final linePath = Path()
      ..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw Dots & Labels
    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    final dotOuterPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : Colors.white
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      // Draw outer circle, then inner circle
      canvas.drawCircle(pt, 5.0, dotPaint);
      canvas.drawCircle(pt, 2.5, dotOuterPaint);

      // Draw value text above dot
      textPainter.text = TextSpan(
        text: '${values[i]}h',
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pt.dx - (textPainter.width / 2), pt.dy - 16));

      // Draw day labels at bottom
      textPainter.text = TextSpan(
        text: days[i],
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pt.dx - (textPainter.width / 2), size.height + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

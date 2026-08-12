// lib/screens/AI/mentor_compass_screen.dart

import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:skill_swap/providers/ai/ai_recommendation_provider.dart';
import 'package:skill_swap/models/ai/mentor_recommendation.dart';
import 'package:skill_swap/screens/Home%20Screens/swapping%20Available.dart';
import 'package:skill_swap/screens/Profile/profile%20screen.dart';

class MentorCompassScreen extends StatelessWidget {
  const MentorCompassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final provider = Provider.of<AIRecommendationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('mentor_compass'.tr(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: provider.isLoading
          ? Center(
        child: CircularProgressIndicator(color: primaryColor),
      )
          : provider.mentorRecommendations.isEmpty
          ? _buildEmptyState(context, isDark)
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.mentorRecommendations.length,
        itemBuilder: (context, index) {
          final mentor = provider.mentorRecommendations[index];
          return _buildMentorCard(context, mentor, index, isDark, primaryColor);
        },
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
              Icons.explore_off_rounded,
              size: 72,
              color: isDark ? Colors.white30 : Colors.black.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Matches Found Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Make sure you have offering and learning skills added to your profile, then click refresh.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorCard(
      BuildContext context,
      MentorRecommendation mentor,
      int index,
      bool isDark,
      Color primaryColor,
      ) {
    final mappedListing = SwapListing(
      id: mentor.id,
      name: mentor.mentorName,
      initials: mentor.mentorInitials,
      avatarColor: Colors.purple,
      offering: mentor.mentorSkill,
      wanting: mentor.mentorWantingSkill,
      rating: mentor.mentorStats.averageRating,
      reviews: mentor.mentorStats.totalReviews,
      category: 'All',
      imageUrl: mentor.mentorImageUrl,
      userId: mentor.mentorId,
      portfolioFile: mentor.portfolioFile,
    );


    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: mentor.isBestSwap
              ? const Color(0xFF00C2FF)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: mentor.isBestSwap ? 2 : 1,
        ),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Section 1: Header (Avatar + Name + Skills + Match Badge) ─
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF6B8AFF).withValues(alpha: 0.15),
                  backgroundImage: mentor.mentorImageUrl != null
                      ? NetworkImage(mentor.mentorImageUrl!)
                      : null,
                  child: mentor.mentorImageUrl == null
                      ? Text(
                    mentor.mentorInitials,
                    style: const TextStyle(
                      color: Color(0xFF6B8AFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 14),

                // Name & Skills
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              mentor.mentorName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (mentor.isBestSwap)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C2FF).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'BEST SWAP',
                                style: TextStyle(
                                  color: Color(0xFF00C2FF),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.school_outlined, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Teaches: ${mentor.mentorSkill}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.favorite_border_rounded, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Learns: ${mentor.mentorWantingSkill}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Match Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: mentor.isBestSwap
                        ? const Color(0xFF00C2FF).withValues(alpha: 0.12)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${mentor.matchScore.round()}%',
                        style: TextStyle(
                          color: mentor.isBestSwap
                              ? const Color(0xFF00C2FF)
                              : (isDark ? Colors.white : Colors.black87),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        'MATCH',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),


          // ── Section 2: Why AI Recommends ────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Color(0xFF00C2FF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'WHY AI RECOMMENDS',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  mentor.whyRecommended.isNotEmpty
                      ? mentor.whyRecommended.first
                      : 'Curated match based on your skill profile',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),


          // ── Section 3: Skill Compatibility Bars ─────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SKILL COMPATIBILITY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                ...mentor.skillCompatibility.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${(entry.value * 100).round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.value,
                            minHeight: 6,
                            backgroundColor: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),


          // ── Section 4: Footer CTAs ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (mentor.portfolioFile.isNotEmpty) {
                        _openPortfolio(context, mentor.portfolioFile);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No portfolio uploaded by this mentor.')),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'View Portfolio',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(swap: mappedListing),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Start Swap',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Future<void> _openPortfolio(BuildContext context, String url) async {
    if (url.isEmpty) return;

    final fileName = _getPortfolioName(url);
    final isImage = url.toLowerCase().contains(RegExp(r'\.(jpg|jpeg|png|webp|gif|bmp)'));

    if (isImage) {
      _viewImage(context, url, fileName);
      return;
    }

    final Uri uri = Uri.parse(url);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${'opening'.tr()} $fileName..."),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error opening portfolio: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening portfolio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPortfolioName(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null || uri.pathSegments.isEmpty) {
      return url;
    }

    String lastSegment = uri.pathSegments.last;
    try {
      lastSegment = Uri.decodeComponent(lastSegment);
    } catch (_) {}

    if (lastSegment.isEmpty && uri.pathSegments.length > 1) {
      lastSegment = uri.pathSegments[uri.pathSegments.length - 2];
      try {
        lastSegment = Uri.decodeComponent(lastSegment);
      } catch (_) {}
    }

    final parts = lastSegment.split('_');
    if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts[0])) {
      return parts.sublist(1).join('_');
    }

    return lastSegment;
  }

  void _viewImage(BuildContext context, String imageUrl, String fileName) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: Colors.white, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'Could not load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                bottom: 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    fileName,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

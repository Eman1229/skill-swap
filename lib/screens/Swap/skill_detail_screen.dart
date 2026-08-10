import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/models/session_model.dart';
import 'package:skill_swap/models/learning_asset.dart';
import 'package:skill_swap/screens/Swap/create_session_screen.dart';
import 'package:skill_swap/screens/Swap/edit_session_screen.dart';
import 'package:skill_swap/screens/Swap/course_assets_screen.dart';
import 'package:skill_swap/screens/Swap/assignments_screen.dart';
import 'package:skill_swap/screens/Swap/session_detail_screen.dart';
import 'package:skill_swap/services/learning_assets_service.dart';
import 'package:skill_swap/services/chat_user_service.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/services/skill_exchange_service.dart';
import 'package:skill_swap/screens/Swap/rate_feedback_screen.dart';
import 'package:skill_swap/screens/Swap/certificate_screen.dart';
import 'package:skill_swap/services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SkillDetailScreen extends StatefulWidget {
  final SwapModel swap;
  final String? highlightedAssetId;

  const SkillDetailScreen({Key? key, required this.swap, this.highlightedAssetId}) : super(key: key);

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, bool> _launchingMeetings = {};

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  bool get _isMentor => _currentUserId == widget.swap.mentorId;

  // Formats relative days (e.g. "Today", "Tomorrow", or date)
  String _getRelativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(date.year, date.month, date.day).difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return DateFormat('MMM dd').format(date);
  }

  String _formatSessionTime(DateTime date) {
    final format = DateFormat('h:mm a');
    final end = date.add(const Duration(hours: 1)); // default duration 1h
    return '${format.format(date)} - ${format.format(end)}';
  }

  // Deduce skill category name based on skill titles
  String _getCategoryName(String skillName) {
    final name = skillName.toLowerCase();
    if (name.contains('photo') || name.contains('retouch') || name.contains('edit')) {
      return 'Photo Editing';
    }
    if (name.contains('music') || name.contains('guitar') || name.contains('piano')) {
      return 'Music / Instrument';
    }
    if (name.contains('flutter') || name.contains('code') || name.contains('dart') || name.contains('dev')) {
      return 'Software Development';
    }
    return 'Creative Skills';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('swaps').doc(widget.swap.id).snapshots(),
      builder: (context, swapSnapshot) {
        if (swapSnapshot.connectionState == ConnectionState.waiting && !swapSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00C2FF))),
          );
        }

        final swap = (swapSnapshot.hasData && swapSnapshot.data!.exists)
            ? SwapModel.fromDoc(swapSnapshot.data!)
            : widget.swap;

        return StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('swaps')
              .doc(swap.id)
              .collection('sessions')
              .orderBy('date', descending: false)
              .snapshots(),
          builder: (context, sessionsSnapshot) {
            final sessionDocs = sessionsSnapshot.data?.docs ?? [];
            final sessions = sessionDocs.map((doc) => SessionModel.fromDoc(doc)).toList();

            // Dynamic progress count calculations from actual sessions sub-collection
            final int totalSessions = sessions.length;
            final int completedSessions = sessions.where((s) => s.status == 'completed').length;
            final int remainingSessions = (totalSessions - completedSessions).clamp(0, totalSessions);
            final double progressPercentage = totalSessions > 0
                ? (completedSessions / totalSessions).clamp(0.0, 1.0)
                : 0.0;

            // Find next upcoming/active session (status is pending/accepted and date is in the future)
            SessionModel? nextSession;
            final now = DateTime.now();
            for (final s in sessions) {
              if (s.status != 'completed' && s.date.isAfter(now)) {
                if (nextSession == null || s.date.isBefore(nextSession.date)) {
                  nextSession = s;
                }
              }
            }

            return StreamBuilder<List<LearningAsset>>(
              stream: LearningAssetsService().watchCourseAssets(swap.id),
              builder: (context, assetsSnapshot) {
                final assets = assetsSnapshot.data ?? [];
                
                return StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('swaps')
                      .doc(swap.id)
                      .collection('assignments')
                      .snapshots(),
                  builder: (context, assignmentsSnapshot) {
                    final assignmentDocs = assignmentsSnapshot.data?.docs ?? [];
                    final assignmentsCount = assignmentDocs.length;

                    // Compute material grid counts
                    int pdfsCount = 0;
                    int videosCount = 0;
                    int linksCount = 0;

                    for (final asset in assets) {
                      final type = asset.fileType.toLowerCase();
                      if (type == 'pdf' || type.contains('doc') || type.contains('ppt')) {
                        pdfsCount++;
                      } else if (type == 'mp4' || type == 'mov' || type.contains('video')) {
                        videosCount++;
                      } else {
                        linksCount++;
                      }
                    }

                    return Scaffold(
                      backgroundColor: const Color(0xFF0A0F1D), // Dark premium color matching mockup
                      appBar: AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                        title: Text(
                          swap.skillName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        centerTitle: true,
                      ),
                      body: SafeArea(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Progress Section
                              _buildProgressCard(completedSessions, totalSessions, remainingSessions, progressPercentage),
                              const SizedBox(height: 24),

                              // 2. Upcoming Session Card
                              if (nextSession != null) ...[
                                _buildUpcomingSessionCard(nextSession),
                                const SizedBox(height: 24),
                              ],

                              // 3. Course Materials Section
                              _buildCourseMaterialsSection(swap, pdfsCount, videosCount, assignmentsCount, linksCount),
                              const SizedBox(height: 24),

                              // 4. Session Timeline Section
                              _buildSessionTimeline(swap, sessions),
                              const SizedBox(height: 24),

                              // 5. Swap Status Stepper Section
                              _buildSwapStatusCard(swap, sessions, completedSessions, totalSessions),
                              const SizedBox(height: 24),

                              // 6. Reviews & Ratings Section
                              _buildReviewsCard(swap),
                              const SizedBox(height: 24),

                              // 7. Certificate Section
                              _buildCertificateCard(swap),
                              const SizedBox(height: 24),

                              // 8. Course Details Section
                              _buildCourseDetailsCard(swap, totalSessions),
                              const SizedBox(height: 24),

                              // 9. Completion Workflow Section
                              _buildCompletionWorkflowSection(swap),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // 1. Progress Section Widget
  Widget _buildProgressCard(
    int completed,
    int total,
    int remaining,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2E), // Slick dark card color
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.donut_large_rounded, color: Color(0xFF00C2FF), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('progress_label'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toInt()}% Complete',
                style: const TextStyle(color: Color(0xFF00C2FF), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF1E293B),
              color: const Color(0xFF00C2FF),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildProgressMiniStat('Completed\nSessions', '$completed')),
              Expanded(child: _buildProgressMiniStat('Total\nSessions', '$total')),
              Expanded(child: _buildProgressMiniStat('Remaining\nSessions', '$remaining')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 10, height: 1.2),
        ),
      ],
    );
  }

  // 2. Upcoming Session Card Widget
  Widget _buildUpcomingSessionCard(SessionModel session) {
    final relativeDay = _getRelativeDay(session.date);
    final formattedDate = DateFormat('MMMM dd, yyyy').format(session.date);
    final formattedTime = _formatSessionTime(session.date);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF00C2FF), size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Upcoming Session',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  relativeDay,
                  style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              final sessionInfo = ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isNarrow ? constraints.maxWidth : constraints.maxWidth - 140,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.video_camera_back_rounded, color: Color(0xFF00C2FF), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.title.replaceAll(RegExp('Lesson', caseSensitive: false), 'Session'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_outlined, color: Colors.grey, size: 12),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  formattedDate,
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.grey, size: 12),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  formattedTime,
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              final buttons = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ElevatedButton(
                      onPressed: _launchingMeetings[session.id] == true
                          ? null
                          : () async {
                              if (session.meetingLink.isNotEmpty) {
                                final uri = Uri.tryParse(session.meetingLink);
                                if (uri != null) {
                                  setState(() {
                                    _launchingMeetings[session.id] = true;
                                  });
                                  try {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _launchingMeetings[session.id] = false;
                                      });
                                    }
                                  }
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('no_meeting_link_provided'.tr())),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _launchingMeetings[session.id] == true
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Join Session',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditSessionScreen(swapId: widget.swap.id, session: session),
                        ),
                      );
                    },
                    child: const Text(
                      'Reschedule',
                      style: TextStyle(color: Colors.grey, fontSize: 11, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              );

              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  sessionInfo,
                  buttons,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. Course Materials Grid Section Widget
  Widget _buildCourseMaterialsSection(
    SwapModel swap,
    int pdfsCount,
    int videosCount,
    int assignmentsCount,
    int linksCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.folder_open_rounded, color: Color(0xFF00C2FF), size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Course Materials',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseAssetsScreen(
                        courseId: swap.id,
                        initialCourse: swap,
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, color: Theme.of(context).colorScheme.primary, size: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildMaterialCard(
                    label: 'PDFs',
                    count: pdfsCount,
                    icon: Icons.picture_as_pdf_rounded,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseAssetsScreen(courseId: swap.id, initialCourse: swap),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMaterialCard(
                    label: 'Videos',
                    count: videosCount,
                    icon: Icons.play_circle_fill_rounded,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseAssetsScreen(courseId: swap.id, initialCourse: swap),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMaterialCard(
                    label: 'Assignments',
                    count: assignmentsCount,
                    icon: Icons.assignment_rounded,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignmentsScreen(swap: swap),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMaterialCard(
                    label: 'Links',
                    count: linksCount,
                    icon: Icons.link_rounded,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseAssetsScreen(courseId: swap.id, initialCourse: swap),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard({
    required String label,
    required int count,
    required IconData icon,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 2,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Session Timeline Section Widget
  Widget _buildSessionTimeline(SwapModel swap, List<SessionModel> sessions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.list_alt_rounded, color: Color(0xFF00C2FF), size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Session Timeline',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${sessions.length} Sessions',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  if (_isMentor && (swap.status == 'ongoing' || swap.status == 'More Sessions Requested')) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF00C2FF), size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateSessionScreen(swap: swap),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sessions.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('no_sessions_planned'.tr(), style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final isCompleted = session.status == 'completed';
                // Exactly one scheduled session is active at a time.
                final isActive = (index == sessions.indexWhere((s) => s.status != 'completed'));
                final isLocked = !isCompleted && !isActive;
                
                return _buildTimelineItem(swap, session, index, sessions.length, isCompleted, isActive, isLocked);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    SwapModel swap,
    SessionModel session,
    int index,
    int totalItems,
    bool isCompleted,
    bool isActive,
    bool isLocked,
  ) {
    final relativeDate = _getRelativeDay(session.date);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line and circle indicators
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green
                      : (isActive ? const Color(0xFF00C2FF) : Colors.transparent),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : (isActive ? const Color(0xFF00C2FF) : const Color(0xFF1E293B)),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : (isActive
                          ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
                          : const SizedBox.shrink()),
                ),
              ),
              if (index < totalItems - 1)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFF1E293B),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isLocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Complete the previous session to unlock this one.')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SessionDetailScreen(session: session)),
                );
              },
              onLongPress: () {
                if (_isMentor && swap.status != 'Waiting for Learner Confirmation' && swap.status != 'completed') {
                  _showSessionManagementMenu(context, session);
                }
              },
              child: Container(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Session ${index + 1}: ${session.title.replaceAll(RegExp('Lesson', caseSensitive: false), 'Session')}',
                        style: TextStyle(
                          color: isActive ? const Color(0xFF00C2FF) : (isCompleted ? Colors.white : Colors.grey),
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isLocked)
                      const Icon(Icons.lock_outline_rounded, color: Colors.grey, size: 16)
                    else
                      Text(
                        relativeDate,
                        style: TextStyle(
                          color: isActive ? const Color(0xFF00C2FF) : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionManagementMenu(BuildContext context, SessionModel session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text('mark_completed'.tr(), style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  await SkillExchangeService().completeSessionAndSync(
                    swapId: widget.swap.id,
                    sessionId: session.id,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('session_marked_completed'.tr()), backgroundColor: Colors.green),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF00C2FF)),
                title: const Text('Reschedule / Edit', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditSessionScreen(swapId: widget.swap.id, session: session),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                title: Text('delete_session'.tr(), style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF131A2E),
                      title: Text('delete_session_confirm_title'.tr()),
                      content: Text('delete_session_plan_confirm'.tr()),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr())),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: Text('delete'.tr(), style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FirebaseFirestore.instance
                        .collection('swaps')
                        .doc(widget.swap.id)
                        .collection('sessions')
                        .doc(session.id)
                        .delete();
                    await SkillExchangeService().syncSwapSessionCounts(widget.swap.id);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 5. Swap Status Section Widget
  Widget _buildSwapStatusCard(SwapModel swap, List<SessionModel> sessions, int completed, int total) {
    final requestDateStr = DateFormat('MMM dd').format(swap.createdAt);
    final acceptDateStr = DateFormat('MMM dd').format(swap.createdAt.add(const Duration(days: 1)));
    
    // Find teaching start date (first session or completion date)
    String startStr = 'Pending';
    if (sessions.isNotEmpty) {
      startStr = DateFormat('MMM dd').format(sessions.first.date);
    }

    final isCompleted = swap.status == 'completed';
    final isProgress = swap.status == 'ongoing' || swap.status == 'completion_requested';
    final completedDateStr = swap.completedAt != null ? DateFormat('MMM dd').format(swap.completedAt!) : 'Pending';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_alt_rounded, color: Color(0xFF00C2FF), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Swap Status',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHorizontalStepper(
            steps: [
              _StepperStep(label: 'Request Sent', date: requestDateStr, icon: Icons.send_rounded, isDone: true),
              _StepperStep(label: 'Accepted', date: acceptDateStr, icon: Icons.check_circle_rounded, isDone: true),
              _StepperStep(label: 'Teaching Started', date: startStr, icon: Icons.school_rounded, isDone: completed > 0),
              _StepperStep(label: 'In Progress', date: '$completed of $total', icon: Icons.play_arrow_rounded, isDone: isProgress || isCompleted, isActive: isProgress),
              _StepperStep(label: 'Completed', date: completedDateStr, icon: Icons.assignment_turned_in_rounded, isDone: isCompleted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStepper({required List<_StepperStep> steps}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Responsive Background line connector
        Positioned(
          left: 24,
          right: 24,
          top: 16,
          child: Container(
            height: 3,
            color: const Color(0xFF1E293B),
          ),
        ),
        // Responsive Foreground progress line connector
        Positioned(
          left: 24,
          right: 24,
          top: 16,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double fraction = 0.0;
              final done = steps.where((s) => s.isDone).length;
              if (done > 1) {
                fraction = (done - 1) / (steps.length - 1);
              }
              return Row(
                children: [
                  Container(
                    width: constraints.maxWidth * fraction,
                    height: 3,
                    color: const Color(0xFF00C2FF),
                  ),
                  const Spacer(),
                ],
              );
            },
          ),
        ),
        // Stepper Step Column Nodes
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: steps.map((step) {
            final isDone = step.isDone;
            final isActive = step.isActive;

            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDone ? const Color(0xFF00C2FF) : const Color(0xFF131A2E), // Solid bg masks line
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? Colors.white : (isDone ? const Color(0xFF00C2FF) : const Color(0xFF1E293B)),
                        width: isActive ? 2.0 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        step.icon,
                        color: isDone ? Colors.black : Colors.grey,
                        size: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                      color: isDone ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 8),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 6. Reviews & Ratings Section Widget
  Widget _buildReviewsCard(SwapModel swap) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('reviews')
          .where('swapId', isEqualTo: swap.id)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        
        // Find if this user left a review
        final leftReview = docs.any((doc) => doc.data() is Map && (doc.data() as Map)['reviewerId'] == _currentUserId);

        double totalStars = 0;
        for (final doc in docs) {
          final rating = (doc.data() as Map?)?['rating'];
          if (rating is num) {
            totalStars += rating.toDouble();
          }
        }
        final double average = docs.isNotEmpty ? totalStars / docs.length : 0.0;
        final String avgStr = docs.isNotEmpty ? average.toStringAsFixed(1) : '—';
        final String descStr = docs.isNotEmpty ? 'Based on ${docs.length} review(s)' : 'No reviews yet';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF131A2E),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFF00C2FF), size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Reviews & Ratings',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    docs.isEmpty ? 'Not yet rated' : 'Rated',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        avgStr,
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              final star = index + 1.0;
                              return Icon(
                                star <= average ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: Colors.amber,
                                size: 18,
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            descStr,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // If completed or waiting for learner confirmation, let them leave feedback
                  if ((swap.status == 'completed' || swap.status == 'Waiting for Learner Confirmation') && !leftReview)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RateFeedbackScreen(
                              swapId: swap.id,
                              revieweeId: _isMentor ? swap.learnerId : swap.mentorId,
                              revieweeName: _isMentor ? swap.learnerName : swap.mentorName,
                              revieweeRole: _isMentor ? 'learner' : 'mentor',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text('leave_review'.tr()),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 7. Certificate Section Widget
  Widget _buildCertificateCard(SwapModel swap) {
    final isCompleted = swap.status == 'completed';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: Color(0xFF00C2FF), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('certificate'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width > 400 ? MediaQuery.of(context).size.width - 250 : MediaQuery.of(context).size.width - 80,
                ),
                child: const Text(
                  'Complete all sessions and swap to unlock your certificate.',
                  style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                ),
              ),
              ElevatedButton.icon(
                onPressed: isCompleted
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CertificateScreen(swap: swap),
                          ),
                        );
                      }
                    : null,
                icon: Icon(isCompleted ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded, size: 16),
                label: Text(isCompleted ? 'View Certificate' : 'Locked'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? const Color(0xFF00C2FF) : const Color(0xFF1E293B),
                  foregroundColor: isCompleted ? Colors.black : Colors.grey,
                  disabledBackgroundColor: const Color(0xFF1E293B),
                  disabledForegroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 8. Course Details Section Widget
  Widget _buildCourseDetailsCard(SwapModel swap, int totalSessions) {
    final startedDateStr = DateFormat('MMMM dd, yyyy').format(swap.createdAt);
    final category = _getCategoryName(swap.skillName);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF00C2FF), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Course Details',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildUserDetailRow('Mentor', swap.mentorId, swap.mentorName),
                    const SizedBox(height: 16),
                    _buildUserDetailRow('Learner', swap.learnerId, swap.learnerName),
                    const SizedBox(height: 16),
                    _buildTextDetailRow('Started On', startedDateStr, Icons.calendar_month_outlined),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildTextDetailRow('Skill Category', category, Icons.school_outlined),
                    const SizedBox(height: 16),
                    _buildTextDetailRow('Duration', '$totalSessions Sessions', Icons.timer_outlined),
                    const SizedBox(height: 16),
                    _buildTextDetailRow('XP Earned', '+120 XP (Expected)', Icons.stars_outlined),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionWorkflowSection(SwapModel swap) {
    final status = swap.status;
    final isCompleted = status == 'completed';

    if (isCompleted) {
      return const SizedBox.shrink();
    }

    if (_isMentor) {
      // Teacher side
      if (status == 'ongoing' || status == 'More Sessions Requested') {
        final allCompleted = swap.totalSessions > 0 && swap.completedSessions == swap.totalSessions;
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF131A2E),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: allCompleted ? const Color(0xFF00C2FF).withValues(alpha: 0.3) : const Color(0xFF1E293B),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assignment_turned_in_rounded,
                      color: allCompleted ? const Color(0xFF00C2FF) : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Mark Teaching Complete',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  allCompleted
                      ? 'All sessions are finished! You can now request completion confirmation from the learner.'
                      : 'You can mark teaching as complete once all created sessions are completed.',
                  style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: allCompleted
                      ? () => _showTeacherCompletionDialog(swap)
                      : null,
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: allCompleted
                          ? const LinearGradient(colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)])
                          : null,
                      color: allCompleted ? null : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        'Request Completion',
                        style: TextStyle(
                          color: allCompleted ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (status == 'Waiting for Learner Confirmation') {
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF131A2E),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Awaiting Learner Confirmation',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You marked teaching as complete. Waiting for the learner to confirm completion and leave feedback.',
                        style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      // Learner side
      if (status == 'Waiting for Learner Confirmation') {
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF131A2E),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF00C2FF).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.celebration_rounded, color: Color(0xFF00C2FF), size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Teaching Completed',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${swap.mentorName} has marked teaching as complete. Please confirm if you are satisfied, or request more sessions if you need further help.',
                  style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _requestMoreSessions(swap),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF1E293B)),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Center(
                            child: Text(
                              'Need Sessions',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RateFeedbackScreen(
                                swapId: swap.id,
                                revieweeId: swap.mentorId,
                                revieweeName: swap.mentorName,
                                revieweeRole: 'mentor',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Center(
                            child: Text(
                              'Confirm Complete',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  void _showTeacherCompletionDialog(SwapModel swap) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('mark_teaching_complete_confirm'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to mark teaching as complete? This will lock editing and request completion confirmation from the learner.',
          style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(), style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await SkillExchangeService().requestSwapCompletion(
                  swapId: swap.id,
                  teacherId: swap.mentorId,
                  learnerId: swap.learnerId,
                  skillName: swap.skillName,
                  teacherName: swap.mentorName,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('completion_request_sent'.tr()), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${'error'.tr()}: $e"), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C2FF)),
            child: Text('confirm'.tr(), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _requestMoreSessions(SwapModel swap) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('request_more_sessions_confirm'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Do you want to request more learning sessions? This will unlock session management for your mentor.',
          style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr(), style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C2FF)),
            child: Text('request'.tr(), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.collection('swaps').doc(swap.id).update({
          'status': 'More Sessions Requested',
          'moreSessionsRequestedAt': FieldValue.serverTimestamp(),
        });

        await NotificationService().sendNotification(
          receiverId: swap.mentorId,
          type: 'swap',
          title:'more_sessions_requested_title'.tr(),
          body: '${swap.learnerName} has requested additional sessions for "${swap.skillName}".',
          actionRoute: '/skill_detail',
          actionId: swap.id,
          data: {
            'type': 'more_sessions_request',
            'swapId': swap.id,
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('request_sent_mentor'.tr()), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${'error'.tr()}: $e"), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  Widget _buildUserDetailRow(String label, String uid, String fallbackName) {
    return StreamBuilder<ChatUserProfile>(
      stream: ChatUserService().getUserProfile(uid),
      builder: (context, snapshot) {
        String name = fallbackName;
        String? avatarUrl;
        if (snapshot.hasData) {
          name = snapshot.data!.name;
          avatarUrl = snapshot.data!.imageUrl;
        }

        return Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1E293B),
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: Colors.grey, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepperStep {
  final String label;
  final String date;
  final IconData icon;
  final bool isDone;
  final bool isActive;

  _StepperStep({
    required this.label,
    required this.date,
    required this.icon,
    required this.isDone,
    this.isActive = false,
  });
}

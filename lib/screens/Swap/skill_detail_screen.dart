import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/models/session_model.dart';
import 'package:skill_swap/screens/Swap/create_session_screen.dart';
import 'package:skill_swap/screens/Swap/course_assets_screen.dart';
import 'package:skill_swap/screens/Swap/session_detail_screen.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';
import 'package:skill_swap/services/chat_user_service.dart';
import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/services/skill_exchange_service.dart';
import 'package:skill_swap/screens/Swap/confirm_swap_completion_screen.dart';
import 'package:skill_swap/screens/Swap/rate_feedback_screen.dart';
import 'package:skill_swap/screens/Swap/certificate_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final uid = _auth.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('swaps').doc(widget.swap.id).snapshots(),
      builder: (context, snapshot) {
        final swap = (snapshot.hasData && snapshot.data!.exists)
            ? SwapModel.fromDoc(snapshot.data!)
            : widget.swap;

        final isMentor = uid == swap.mentorId;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(swap),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressSection(swap),
                      _buildCompletionStatusSection(swap, isMentor, uid),
                      const SizedBox(height: 32),
                      _buildInfoSection(swap),
                      const SizedBox(height: 32),
                      CourseAssetsSection(
                        course: swap,
                        highlightedAssetId: widget.highlightedAssetId,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('sessions'.tr(),
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                          if (isMentor && swap.status == 'ongoing')
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => CreateSessionScreen(swap: swap)),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.add, color: Theme.of(context).colorScheme.primary, size: 16),
                                    const SizedBox(width: 4),
                                    Text('add_session'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSessionsList(swap),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(SwapModel swap) {
    return SliverAppBar(
      expandedHeight: 200,
      backgroundColor: Theme.of(context).colorScheme.surface,
      pinned: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(swap.skillName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, const Color(0xFF6B8AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Center(
              child: Icon(
                Icons.psychology_outlined,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
                size: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(SwapModel swap) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('overall_progress'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
              Text('${(swap.progress * 100).toInt()}%', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: swap.progress,
              backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              color: Theme.of(context).colorScheme.primary,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatMini(label: 'completed'.tr(), value: swap.completedSessions.toString()),
              Container(width: 1, height: 30, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6)),
              _StatMini(label: 'total'.tr(), value: swap.totalSessions.toString()),
              Container(width: 1, height: 30, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6)),
              _StatMini(label: 'status'.tr(), value: swap.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStatusSection(SwapModel swap, bool isMentor, String? uid) {
    if (swap.status == 'ongoing') {
      if (isMentor) {
        return Column(
          children: [
            const SizedBox(height: 24),
            _buildMarkAsCompleteCard(swap),
          ],
        );
      }
      return const SizedBox.shrink();
    } else if (swap.status == 'completion_requested') {
      return Column(
        children: [
          const SizedBox(height: 24),
          _buildAwaitingConfirmationCard(swap, isMentor, uid),
        ],
      );
    } else if (swap.status == 'completed') {
      return Column(
        children: [
          const SizedBox(height: 24),
          _buildCompletedSectionCard(swap, isMentor, uid),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMarkAsCompleteCard(SwapModel swap) {
    return InkWell(
      onTap: () => _showMarkAsCompleteDialog(swap),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_turned_in_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'mark_as_complete'.tr(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Once you and your partner agree that all learning is done, you can complete this swap.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAwaitingConfirmationCard(SwapModel swap, bool isMentor, String? uid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.watch_later_outlined, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'review_completion_request'.tr(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMentor
                          ? 'You have requested to complete this swap. We have notified ${swap.learnerName}. Once they confirm, the swap will be marked as complete.'
                          : '${swap.mentorName} has marked this swap as complete. Please review and confirm.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHorizontalStepper(
            steps: ['Requested by ${swap.mentorName}', 'Awaiting ${swap.learnerName}', 'Complete'],
            currentStep: 1,
            allCompleted: false,
          ),
          const SizedBox(height: 24),
          Text(
            'What happens next?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildChecklistItem('${swap.learnerName} will review and confirm completion.'),
          _buildChecklistItem('After confirmation, you can both add feedback.'),
          _buildChecklistItem('You will earn XP and unlock achievements.'),
          if (!isMentor) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ConfirmSwapCompletionScreen(swapId: swap.id)),
                );
              },
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).colorScheme.primary, const Color(0xFF008CCB)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text(
                    'Review Request',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedSectionCard(SwapModel swap, bool isMentor, String? uid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Swap Completed!',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Both you and ${isMentor ? swap.learnerName : swap.mentorName} have confirmed completion.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHorizontalStepper(
            steps: ['Requested by ${swap.mentorName}', 'Confirmed by ${swap.learnerName}', 'Complete'],
            currentStep: 2,
            allCompleted: true,
          ),
          const SizedBox(height: 24),
          Text(
            'What happens next?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildChecklistItem('Add feedback and rating for each other.'),
          _buildChecklistItem('Earn XP and see your achievements.'),
          _buildChecklistItem('Download your completion certificate.'),
          const SizedBox(height: 24),
          FutureBuilder<QuerySnapshot>(
            future: _db
                .collection('reviews')
                .where('swapId', isEqualTo: swap.id)
                .where('reviewerId', isEqualTo: uid)
                .get(),
            builder: (context, snapshot) {
              final hasReviewed = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

              return Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: hasReviewed
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RateFeedbackScreen(
                                    swapId: swap.id,
                                    revieweeId: isMentor ? swap.learnerId : swap.mentorId,
                                    revieweeName: isMentor ? swap.learnerName : swap.mentorName,
                                    revieweeRole: isMentor ? 'learner' : 'mentor',
                                  ),
                                ),
                              ).then((_) => setState(() {}));
                            },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: hasReviewed
                              ? null
                              : LinearGradient(
                                  colors: [Theme.of(context).colorScheme.primary, const Color(0xFF008CCB)],
                                ),
                          color: hasReviewed ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1) : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            hasReviewed ? 'Feedback Sent' : 'Add Review',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: hasReviewed ? Theme.of(context).colorScheme.onSurfaceVariant : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CertificateScreen(swap: swap),
                          ),
                        );
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.primary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Certificate',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStepper({
    required List<String> steps,
    required int currentStep,
    required bool allCompleted,
  }) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index % 2 != 0) {
          final stepIdx = (index - 1) ~/ 2;
          final isPassed = allCompleted || stepIdx < currentStep;
          return Expanded(
            child: Container(
              height: 3,
              color: isPassed ? Colors.green : Colors.grey[350],
            ),
          );
        } else {
          final stepIdx = index ~/ 2;
          final isActive = allCompleted || stepIdx <= currentStep;
          final isDone = allCompleted || stepIdx < currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDone ? Colors.green : (isActive ? Theme.of(context).colorScheme.primary : Colors.transparent),
                  border: Border.all(
                    color: isDone ? Colors.green : (isActive ? Theme.of(context).colorScheme.primary : Colors.grey[400]!),
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : (isActive
                          ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
                          : const SizedBox.shrink()),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[stepIdx],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMarkAsCompleteDialog(SwapModel swap) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 40),
        title: const Text(
          'Mark Swap as Complete?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to mark this swap as complete? Your learner will receive a request to confirm completion. The swap will only be completed after the learner confirms.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _requestCompletion(swap);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestCompletion(SwapModel swap) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending completion request...')),
      );

      await SkillExchangeService().requestSwapCompletion(
        swapId: swap.id,
        teacherId: swap.mentorId,
        learnerId: swap.learnerId,
        skillName: swap.skillName,
        teacherName: swap.mentorName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completion request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request completion: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildInfoSection(SwapModel swap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('details'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        StreamBuilder<ChatUserProfile>(
          stream: ChatUserService().getUserProfile(swap.mentorId),
          builder: (context, snapshot) {
            String mentorName = swap.mentorName;
            if (snapshot.hasData && snapshot.data!.name.isNotEmpty && snapshot.data!.name != 'Unknown User') {
              mentorName = snapshot.data!.name;
            }
            return _InfoRow(label: 'mentor'.tr(), value: mentorName);
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<ChatUserProfile>(
          stream: ChatUserService().getUserProfile(swap.learnerId),
          builder: (context, snapshot) {
            String learnerName = swap.learnerName;
            if (snapshot.hasData && snapshot.data!.name.isNotEmpty && snapshot.data!.name != 'Unknown User') {
              learnerName = snapshot.data!.name;
            }
            return _InfoRow(label: 'learner'.tr(), value: learnerName);
          },
        ),
        const SizedBox(height: 12),
        _InfoRow(label: 'started'.tr(), value: 'May 12, 2026'),
      ],
    );
  }

  Widget _buildSessionsList(SwapModel swap) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('swaps')
          .doc(swap.id)
          .collection('sessions')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text('no_sessions_yet'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.65))));
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final session = SessionModel.fromDoc(docs[index]);
            return _SessionTile(session: session);
          },
        );
      },
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  _StatMini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.65),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionModel session;
  _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = session.status == 'completed';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SessionDetailScreen(session: session),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isCompleted ? Colors.green : Colors.orange).withValues(
                  alpha: 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.pending_actions_rounded,
                color: isCompleted ? Colors.green : Colors.orange,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'May 24, 10:00 AM • ${session.duration}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Theme.of(context).colorScheme.outlineVariant,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

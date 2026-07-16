import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/services/skill_exchange_service.dart';
import 'package:skill_swap/screens/Swap/rate_feedback_screen.dart';

class ConfirmSwapCompletionScreen extends StatefulWidget {
  final String swapId;

  const ConfirmSwapCompletionScreen({super.key, required this.swapId});

  @override
  State<ConfirmSwapCompletionScreen> createState() => _ConfirmSwapCompletionScreenState();
}

class _ConfirmSwapCompletionScreenState extends State<ConfirmSwapCompletionScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SkillExchangeService _exchangeService = SkillExchangeService();

  bool _checked1 = false;
  bool _checked2 = false;
  bool _checked3 = false;
  bool _isLoading = false;

  Future<void> _handleConfirm(SwapModel swap) async {
    if (!_checked1 || !_checked2 || !_checked3) return;

    setState(() => _isLoading = true);

    try {
      await _exchangeService.confirmSwapCompletion(
        swapId: swap.id,
        learnerId: swap.learnerId,
        teacherId: swap.mentorId,
        skillName: swap.skillName,
        learnerName: swap.learnerName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('swap_completed_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );

        // Immediately navigate to Rate & Feedback screen to rate the teacher/mentor
        Navigator.pushReplacement(
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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${'error'.tr()}: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'confirm_completion'.tr(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('swaps').doc(widget.swapId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text("${'error'.tr()}: ${snapshot.error}", style: TextStyle(color: Colors.redAccent)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('swap_details_not_found'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
          }

          final swap = SwapModel.fromDoc(snapshot.data!);

          if (swap.status == 'completed') {
            return _buildAlreadyCompletedView(swap);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Alert Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assignment_turned_in_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'review_completion_request'.tr(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${swap.mentorName} has marked this swap as complete. Please review the sessions and confirm if you agree.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Progress Summary Section
                Text(
                  'progress_summary'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('completed_sessions'.tr(), swap.completedSessions.toString()),
                          Container(width: 1, height: 30, color: Theme.of(context).colorScheme.outlineVariant),
                          _buildStatItem('total_sessions'.tr(), swap.totalSessions.toString()),
                          Container(width: 1, height: 30, color: Theme.of(context).colorScheme.outlineVariant),
                          _buildStatItem('overall_progress'.tr(), '${(swap.progress * 100).toInt()}%'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: swap.progress,
                          minHeight: 8,
                          backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Checklist Title
                Text('confirm_completion'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Checklist item 1
                _buildChecklistItem(
                  title: "${'all_lessons_for'.tr()} \"${swap.skillName}\" ${'completed'.tr()}",
                  value: _checked1,
                  onChanged: (val) => setState(() => _checked1 = val ?? false),
                ),
                const SizedBox(height: 12),

                // Checklist item 2
                _buildChecklistItem(
                  title:'learned_what_promised'.tr(),
                  value: _checked2,
                  onChanged: (val) => setState(() => _checked2 = val ?? false),
                ),
                const SizedBox(height: 12),

                // Checklist item 3
                _buildChecklistItem(
                  title:'agree_to_finalize'.tr(),
                  value: _checked3,
                  onChanged: (val) => setState(() => _checked3 = val ?? false),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // Yes, Confirm Button
                  GestureDetector(
                    onTap: (_checked1 && _checked2 && _checked3) ? () => _handleConfirm(swap) : null,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: (_checked1 && _checked2 && _checked3)
                            ? LinearGradient(
                                colors: [Theme.of(context).colorScheme.primary, const Color(0xFF008CCB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: !(_checked1 && _checked2 && _checked3)
                            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)
                            : null,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: (_checked1 && _checked2 && _checked3)
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'mark_as_complete'.tr(),
                          style: TextStyle(
                            color: (_checked1 && _checked2 && _checked3)
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cancel Button
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      child: Text(
                        'not_yet'.tr(),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlreadyCompletedView(SwapModel swap) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            Text('swap_already_completed'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This swap for "${swap.skillName}" has already been marked as complete.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: Text('back_to_home'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
        checkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}

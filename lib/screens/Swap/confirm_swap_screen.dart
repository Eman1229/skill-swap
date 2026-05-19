import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/screens/Home Screens/swapping Available.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';


class ConfirmSwapScreen extends StatelessWidget {
  final SwapListing swap;

  ConfirmSwapScreen({Key? key, required this.swap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: Theme.of(context).colorScheme.onSurface, size: 16),
                    ),
                  ),
                  SizedBox(width: 14),
                  Text(
                    'confirm_swap'.tr(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Spacer(),

            // ── Card ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Text(
                    'swap_with_person'.tr(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'review_details'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 32),

                  // ── Person tile ──
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: swap.avatarColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              swap.initials,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 14),

                        // Name + badges
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                swap.name,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  _InfoChip(
                                    label: '${swap.reviews} ${'swaps_count'.tr()}',
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  SizedBox(width: 8),
                                  _InfoChip(
                                    label: swap.skillLevel.isNotEmpty
                                        ? swap.skillLevel
                                        : 'Intermediate',
                                    color: Color(0xFF6B8AFF),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // ── Swap detail ──
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SwapDetailItem(
                            label: 'they_offer'.tr(),
                            value: swap.offering,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.swap_horiz_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                        ),
                        Expanded(
                          child: _SwapDetailItem(
                            label: 'they_want'.tr(),
                            value: swap.wanting,
                            color: Color(0xFF6B8AFF),
                            alignRight: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Spacer(),

            // ── Bottom Buttons ──
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  // Message
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor:
                        Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                      ),
                      child: Text(
                        'message'.tr(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

                  // Confirm Swap
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) {
                            FirebaseFirestore.instance.collection('swaps').add({
                              'mentorId': swap.userId ?? swap.id,
                              'learnerId': uid,
                              'mentorName': swap.name,
                              'learnerName': FirebaseAuth.instance.currentUser?.displayName ?? 'Learner',
                              'skillName': swap.offering,
                              'status': 'ongoing',
                              'progress': 0.1,
                              'conversationId': '', // To be updated when chat starts
                              'completedSessions': 0,
                              'totalSessions': 8,
                              'participants': [uid, swap.userId ?? swap.id],
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                              Text('${'swap_request_sent'.tr()} ${swap.name}!'),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: StadiumBorder(),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'confirm_swap'.tr(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small helper widgets ─────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SwapDetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool alignRight;
  _SwapDetailItem({
    required this.label,
    required this.value,
    required this.color,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 11)),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }
}
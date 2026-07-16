import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/screens/Home Screens/swapping Available.dart';
import 'package:skill_swap/services/swap_request_repository.dart';

class ConfirmSwapScreen extends StatefulWidget {
  final SwapListing swap;

  ConfirmSwapScreen({Key? key, required this.swap}) : super(key: key);

  @override
  State<ConfirmSwapScreen> createState() => _ConfirmSwapScreenState();
}

class _ConfirmSwapScreenState extends State<ConfirmSwapScreen> {
  final SwapRequestRepository _requestRepo = SwapRequestRepository();
  bool _isSending = false;

  Future<void> _handleConfirmSwap() async {
    if (_isSending) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (uid == widget.swap.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('cannot_swap_with_yourself'.tr())),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // 1. Check for existing request first
      final existing = await _requestRepo.checkExistingRequest(widget.swap.userId ?? '');
      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${'request_already_exists'.tr()} ${existing.status.name} ${'and'.tr()} ${widget.swap.name}."),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return;
      }

      // 2. Resolve or find conversation ID
      String conversationId = '';
      final query = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: uid)
          .get();

      for (var doc in query.docs) {
        final parts = List<String>.from(doc.data()['participants'] ?? []);
        if (parts.contains(widget.swap.userId)) {
          conversationId = doc.id;
          break;
        }
      }

      // If no conversation exists, we can still send the request, 
      // but it's better to create one or handle it gracefully.
      // For now, let's assume we might need to create it if it doesn't exist.
      if (conversationId.isEmpty) {
        final convoRef = FirebaseFirestore.instance.collection('conversations').doc();
        conversationId = convoRef.id;
        await convoRef.set({
          'participants': [uid, widget.swap.userId],
          'lastMessage': 'Skill Swap Request',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'skill': widget.swap.offering,
          'wanting': widget.swap.wanting,
          'unreadCount': {uid: 0, widget.swap.userId: 1},
        });
      }

      // 2. Send the request via repository
      await _requestRepo.sendRequest(
        receiverId: widget.swap.userId ?? '',
        receiverName: widget.swap.name,
        offeredSkill: widget.swap.offering,
        requestedSkill: widget.swap.wanting,
        conversationId: conversationId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'swap_request_sent'.tr()} ${widget.swap.name}!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${'error'.tr()}: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final swap = widget.swap;
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
                      child: Text('message'.tr(),
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
                        onPressed: _isSending ? null : _handleConfirmSwap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: StadiumBorder(),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSending
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              )
                            : Text(
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
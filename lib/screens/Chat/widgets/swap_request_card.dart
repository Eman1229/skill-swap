import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/models/swap_request.dart';
import 'package:skill_swap/services/swap_request_repository.dart';

class SwapRequestCard extends StatefulWidget {
  final String requestId;
  final bool isMine;

  const SwapRequestCard({
    super.key,
    required this.requestId,
    required this.isMine,
  });

  @override
  State<SwapRequestCard> createState() => _SwapRequestCardState();
}

class _SwapRequestCardState extends State<SwapRequestCard> {
  bool _isProcessing = false;
  SwapRequestStatus? _loadingAction; // SwapRequestStatus.accepted or SwapRequestStatus.rejected

  Future<void> _updateStatus(SwapRequestRepository repo, SwapRequestStatus newStatus) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _loadingAction = newStatus;
    });

    try {
      await repo.updateRequestStatus(widget.requestId, newStatus);
    } catch (e) {
      debugPrint("Error updating swap request status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _loadingAction = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final SwapRequestRepository repo = SwapRequestRepository();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('swap_requests')
          .doc(widget.requestId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final request = SwapRequest.fromDoc(snapshot.data!);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getStatusColor(context, request.status).withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _getStatusColor(context, request.status).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(request.status),
                      color: _getStatusColor(context, request.status),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SKILL SWAP REQUEST',
                      style: TextStyle(
                        color: _getStatusColor(context, request.status),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    _StatusBadge(status: request.status),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Main Info ──
                    Row(
                      children: [
                        Expanded(
                          child: _SkillColumn(
                            label: widget.isMine ? 'You Offer' : 'They Offer',
                            skill: widget.isMine ? request.offeredSkill : request.requestedSkill,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.swap_horiz_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: _SkillColumn(
                            label: widget.isMine ? 'You Want' : 'They Want',
                            skill: widget.isMine ? request.requestedSkill : request.offeredSkill,
                            color: const Color(0xFF6B8AFF),
                            isRight: true,
                          ),
                        ),
                      ],
                    ),

                    if (request.status == SwapRequestStatus.pending && !widget.isMine) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Reject',
                              color: Colors.redAccent,
                              isLoading: _isProcessing && _loadingAction == SwapRequestStatus.rejected,
                              onPressed: _isProcessing
                                  ? null
                                  : () => _updateStatus(repo, SwapRequestStatus.rejected),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              label: 'Accept',
                              color: Theme.of(context).colorScheme.primary,
                              isPrimary: true,
                              isLoading: _isProcessing && _loadingAction == SwapRequestStatus.accepted,
                              onPressed: _isProcessing
                                  ? null
                                  : () => _updateStatus(repo, SwapRequestStatus.accepted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(BuildContext context, SwapRequestStatus status) {
    switch (status) {
      case SwapRequestStatus.pending: return Theme.of(context).colorScheme.primary;
      case SwapRequestStatus.accepted: return Colors.greenAccent;
      case SwapRequestStatus.rejected: return Colors.redAccent;
      case SwapRequestStatus.cancelled: return Colors.grey;
      case SwapRequestStatus.completed: return Colors.blueAccent;
    }
  }

  IconData _getStatusIcon(SwapRequestStatus status) {
    switch (status) {
      case SwapRequestStatus.pending: return Icons.hourglass_empty_rounded;
      case SwapRequestStatus.accepted: return Icons.check_circle_outline_rounded;
      case SwapRequestStatus.rejected: return Icons.cancel_outlined;
      case SwapRequestStatus.cancelled: return Icons.block_flipped;
      case SwapRequestStatus.completed: return Icons.verified_rounded;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final SwapRequestStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SkillColumn extends StatelessWidget {
  final String label;
  final String skill;
  final Color color;
  final bool isRight;

  const _SkillColumn({
    required this.label,
    required this.skill,
    required this.color,
    this.isRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 10)),
        const SizedBox(height: 4),
        TranslatedText(
          skill,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
          textAlign: isRight ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.isPrimary = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = isPrimary ? Theme.of(context).colorScheme.onSurface : color;
    final finalTextColor = onPressed == null ? Colors.grey : defaultTextColor;

    return SizedBox(
      height: 42, // Scaled down for card layout
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null
              ? Colors.grey.withOpacity(0.1)
              : (isPrimary ? color : Colors.transparent),
          foregroundColor: finalTextColor,
          elevation: 0,
          side: BorderSide(
            color: onPressed == null ? Colors.grey : color,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(finalTextColor),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: finalTextColor,
                ),
              ),
      ),
    );
  }
}

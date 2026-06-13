import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class ReportUserDialog extends StatefulWidget {
  final String reportedUserId;
  final String reportedUserName;
  final String source; // 'profile' or 'chat'

  const ReportUserDialog({
    Key? key,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.source,
  }) : super(key: key);

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  final _detailsController = TextEditingController();
  String? _selectedReason;
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Offensive behavior',
    'Inactive user',
    'Spam',
    'Inappropriate content',
    'Fraud or scam',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;

    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': uid,
        'reportedUserId': widget.reportedUserId,
        'reportedUserName': widget.reportedUserName,
        'reason': _selectedReason,
        'details': _detailsController.text.trim(),
        'source': widget.source,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report submitted successfully. Our team will review it within 24 hours.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.report_problem_rounded, color: colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Report User',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why are you reporting ${widget.reportedUserName}?',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Reason Dropdown ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedReason,
                        hint: Text(
                          'Select a reason',
                          style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 14),
                        ),
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: _reasons.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedReason = v),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Details Field ──
                  Text(
                    'Additional details (optional)',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                    ),
                    child: TextField(
                      controller: _detailsController,
                      maxLines: 3,
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Describe what happened...',
                        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.4), fontSize: 13),
                        contentPadding: const EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Buttons ──
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _selectedReason != null
                                ? LinearGradient(colors: [colorScheme.primary, const Color(0xFF6B8AFF)])
                                : null,
                            color: _selectedReason == null ? colorScheme.outlineVariant : null,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ElevatedButton(
                            onPressed: (_selectedReason == null || _isSubmitting) ? null : _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text(
                                    'Submit Report',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                          ),
                        ),
                      ),
                    ],
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

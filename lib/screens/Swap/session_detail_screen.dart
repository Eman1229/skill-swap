import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/models/session_model.dart';
import 'package:skill_swap/services/skill_exchange_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionDetailScreen extends StatefulWidget {
  final SessionModel session;
  const SessionDetailScreen({Key? key, required this.session}) : super(key: key);

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  bool _isCompleting = false;

  String _formatDate(DateTime dt) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final weekday = days[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$weekday, $month ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('swaps')
          .doc(widget.session.swapId)
          .collection('sessions')
          .doc(widget.session.id)
          .snapshots(),
      builder: (context, sessionSnapshot) {
        final currentSession = sessionSnapshot.hasData && sessionSnapshot.data!.exists
            ? SessionModel.fromDoc(sessionSnapshot.data!)
            : widget.session;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('swaps')
              .doc(currentSession.swapId)
              .collection('sessions')
              .orderBy('date')
              .snapshots(),
          builder: (context, sessionsSnapshot) {
            final scheduled = sessionsSnapshot.data?.docs
                    .map((doc) => SessionModel.fromDoc(doc))
                    .toList() ??
                <SessionModel>[];
            final index = scheduled.indexWhere((item) => item.id == currentSession.id);
            final hasIncompletePredecessor = index > 0 && scheduled
                .take(index)
                .any((item) => item.status.toLowerCase() != 'completed');
            final isLocked = currentSession.isLocked || hasIncompletePredecessor;
            return _buildPage(context, currentSession, isLocked);
          },
        );
      },
    );
  }

  Widget _buildPage(BuildContext context, SessionModel session, bool isLocked) {
    final dateStr = _formatDate(session.date);
    final timeStr = _formatTime(session.date);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('session_details'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.calendar_month_rounded, color: Theme.of(context).colorScheme.primary, size: 40),
                  ),
                  SizedBox(height: 24),
                  Text(
                    session.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context, session.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _getStatusColor(context, session.status).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      session.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(context, session.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  _DetailRow(icon: Icons.event_rounded, label: 'date'.tr(), value: dateStr),
                  SizedBox(height: 20),
                  _DetailRow(icon: Icons.access_time_rounded, label: 'time'.tr(), value: timeStr),
                  SizedBox(height: 20),
                  _DetailRow(icon: Icons.timer_outlined, label: 'duration'.tr(), value: session.duration),
                  if (session.status.toLowerCase() != 'completed' && !isLocked) ...[
                    const SizedBox(height: 28),
                    _CompletionAction(
                      isLoading: _isCompleting,
                      onTap: _isCompleting ? null : () => _markAsDone(context, session),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 40),
            if (session.status.toLowerCase() == 'accepted' && !isLocked)
              _PrimaryBtn(
                label: 'enter_meeting_room'.tr(),
                onTap: () => _openMeetingLink(context, session.meetingLink),
              ),
            if (isLocked) ...[
              const SizedBox(height: 16),
              Text(
                'This session is locked until the previous scheduled session is completed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
            SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                minimumSize: Size(double.infinity, 56),
              ),
              child: Text('go_back'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsDone(BuildContext context, SessionModel session) async {
    setState(() => _isCompleting = true);
    try {
      await SkillExchangeService().completeSessionAndSync(
        swapId: session.swapId,
        sessionId: session.id,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session marked as completed.'), backgroundColor: Colors.green),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.greenAccent;
      case 'pending': return Colors.orangeAccent;
      case 'accepted': return Theme.of(context).colorScheme.primary;
      default: return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  Future<void> _openMeetingLink(BuildContext context, String meetingLink) async {
    if (meetingLink.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no_meeting_link'.tr())),
      );
      return;
    }

    final link = meetingLink.trim();
    final uri = Uri.tryParse(link.contains('://') ? link : 'https://$link');
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('invalid_meeting_link'.tr())),
      );
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('could_not_open_link'.tr())),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('could_not_open_link'.tr())),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.outlineVariant, size: 20),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 12)),
            SizedBox(height: 4),
            Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

class _CompletionAction extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _CompletionAction({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.75), width: 2),
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mark as Completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 3),
                    Text('Tap when the session is finished', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  _PrimaryBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(label, style: TextStyle(color:
        Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

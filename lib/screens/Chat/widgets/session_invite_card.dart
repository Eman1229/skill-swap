import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/services/skill_exchange_service.dart';

class SessionInviteCard extends StatelessWidget {
  final String sessionId;
  final String swapId;
  final bool isMine; // True if the current user created the session invitation

  const SessionInviteCard({
    Key? key,
    required this.sessionId,
    required this.swapId,
    required this.isMine,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || sessionId.isEmpty || swapId.isEmpty) {
      return const SizedBox.shrink();
    }

    final sessionRef = FirebaseFirestore.instance
        .collection('swaps')
        .doc(swapId)
        .collection('sessions')
        .doc(sessionId);

    return StreamBuilder<DocumentSnapshot>(
      stream: sessionRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final d = snapshot.data!.data() as Map<String, dynamic>;
        final String title = d['title'] ?? 'Mentoring Session';
        final String duration = d['duration'] ?? '1 hour';
        final String status = d['status'] ?? 'pending';
        
        DateTime? date;
        final dateField = d['date'];
        if (dateField is Timestamp) {
          date = dateField.toDate();
        }

        final String dateStr = date != null
            ? "${date.day}/${date.month}/${date.year} at ${TimeOfDay.fromDateTime(date).format(context)}"
            : '';

        final Color statusColor = _getStatusColor(context, status);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MENTORING SESSION',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    _StatusBadge(status: status, color: statusColor),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.event_rounded, text: dateStr),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.timer_outlined, text: duration),

                    // Actions
                    if (status == 'pending' && !isMine) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Decline',
                              color: Colors.redAccent,
                              onPressed: () => _updateSessionStatus(context, sessionRef, 'cancelled'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              label: 'Accept',
                              color: Theme.of(context).colorScheme.primary,
                              isPrimary: true,
                              onPressed: () => _updateSessionStatus(context, sessionRef, 'accepted'),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (status == 'accepted') ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          if (isMine) ...[
                            Expanded(
                              child: _ActionButton(
                                label: 'Complete',
                                color: Colors.greenAccent,
                                onPressed: () => _completeSession(context, sessionRef),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: _ActionButton(
                              label: 'Join Meeting',
                              color: Theme.of(context).colorScheme.primary,
                              isPrimary: true,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Launching meeting room...')),
                                );
                              },
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

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orangeAccent;
      case 'accepted': return Theme.of(context).colorScheme.primary;
      case 'completed': return Colors.greenAccent;
      case 'cancelled': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  Future<void> _updateSessionStatus(BuildContext context, DocumentReference sessionRef, String newStatus) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Fetch sender name
      String senderName = 'Someone';
      try {
        final senderDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (senderDoc.exists) {
          senderName = senderDoc.data()?['name'] ?? 'Someone';
        }
      } catch (_) {}

      // Fetch session details to get title and creator ID
      final sessionSnap = await sessionRef.get();
      final sessionData = sessionSnap.data() as Map<String, dynamic>?;
      final String sessionTitle = sessionData?['title'] ?? 'Session';

      // The creator is the parent chat message sender (which is the mentor)
      // Let's retrieve other details from the parent swap Listing
      final swapDoc = await FirebaseFirestore.instance.collection('swaps').doc(swapId).get();
      final swapData = swapDoc.data();
      final String mentorId = swapData?['mentorId'] ?? '';
      final String learnerId = swapData?['learnerId'] ?? '';
      
      final String targetUserId = uid == mentorId ? learnerId : mentorId;

      final batch = FirebaseFirestore.instance.batch();
      batch.update(sessionRef, {'status': newStatus});
      
      // Inject message to chat
      final String convoId = swapData?['conversationId'] ?? '';
      if (convoId.isNotEmpty) {
        final msgRef = FirebaseFirestore.instance
            .collection('conversations')
            .doc(convoId)
            .collection('messages')
            .doc();

        batch.set(msgRef, {
          'senderId': uid,
          'text': newStatus == 'accepted' 
              ? 'I accepted your mentoring session invitation!' 
              : 'I declined your mentoring session invitation.',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'text',
          'status': 'sent',
        });

        batch.update(FirebaseFirestore.instance.collection('conversations').doc(convoId), {
          'lastMessage': newStatus == 'accepted' ? 'Session Invite Accepted' : 'Session Invite Declined',
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Send real-time notification
      if (targetUserId.isNotEmpty) {
        final String notificationTitle = newStatus == 'accepted' ? 'Session Accepted! 🎉' : 'Session Declined';
        final String notificationBody = newStatus == 'accepted'
            ? '$senderName accepted your invitation for session "$sessionTitle".'
            : '$senderName declined your invitation for session "$sessionTitle".';

        await FirebaseFirestore.instance.collection('notifications').add({
          'senderId': uid,
          'senderName': senderName,
          'senderProfilePic': '',
          'receiverId': targetUserId,
          'type': 'session',
          'title': notificationTitle,
          'body': notificationBody,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'actionRoute': '/session_details',
          'actionId': sessionId,
          'imageUrl': '',
          'data': {
            'sessionId': sessionId,
            'swapId': swapId,
            'type': 'session',
            'status': newStatus,
          },
        });
      }

    } catch (e) {
      debugPrint("Error updating session status: $e");
    }
  }

  Future<void> _completeSession(BuildContext context, DocumentReference sessionRef) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // 1. Fetch swap and session data
      final parentSwapRef = FirebaseFirestore.instance.collection('swaps').doc(swapId);
      final swapSnap = await parentSwapRef.get();
      if (!swapSnap.exists) return;

      final sData = swapSnap.data();
      final String learnerId = sData?['learnerId'] ?? '';
      
      final sessionSnap = await sessionRef.get();
      final sessionData = sessionSnap.data() as Map<String, dynamic>?;
      final String sessionTitle = sessionData?['title'] ?? 'Session';

      final batch = FirebaseFirestore.instance.batch();

      // Inject complete message to chat room
      final String convoId = sData?['conversationId'] ?? '';
      if (convoId.isNotEmpty) {
        final msgRef = FirebaseFirestore.instance
            .collection('conversations')
            .doc(convoId)
            .collection('messages')
            .doc();

        batch.set(msgRef, {
          'senderId': uid,
          'text': 'Mentoring session completed! 🎉 Nice progress!',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'text',
          'status': 'sent',
        });

        batch.update(FirebaseFirestore.instance.collection('conversations').doc(convoId), {
          'lastMessage': 'Mentoring Session Completed 🎉',
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      await SkillExchangeService().completeSessionAndSync(
        swapId: swapId,
        sessionId: sessionId,
      );

      // 2. Fetch sender (mentor) name for notification
      String mentorName = 'Your mentor';
      try {
        final mentorDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (mentorDoc.exists) {
          mentorName = mentorDoc.data()?['name'] ?? 'Your mentor';
        }
      } catch (_) {}

      // 3. Send Completed Notification to the learner
      if (learnerId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'senderId': uid,
          'senderName': mentorName,
          'senderProfilePic': '',
          'receiverId': learnerId,
          'type': 'session',
          'title': 'Session Completed! 🎉',
          'body': 'Your session "$sessionTitle" with $mentorName has been completed.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'actionRoute': '/session_details',
          'actionId': sessionId,
          'imageUrl': '',
          'data': {
            'sessionId': sessionId,
            'swapId': swapId,
            'type': 'session',
            'status': 'completed',
          },
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session completed successfully! 🎉'), backgroundColor: Colors.green),
      );

    } catch (e) {
      debugPrint("Error completing session: $e");
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? color : Colors.transparent,
          foregroundColor: isPrimary ? Colors.white : color,
          elevation: 0,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.zero,
        ),
        child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

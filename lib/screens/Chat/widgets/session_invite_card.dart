import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/models/session_model.dart';
import 'package:skill_swap/services/skill_exchange_service.dart';
import 'package:skill_swap/services/session_reminder_service.dart';
import 'package:skill_swap/utils/user_display_name.dart';
import 'package:url_launcher/url_launcher.dart';

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
    context.watch<LanguageProvider>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    if (sessionId.isEmpty || swapId.isEmpty) {
      return Center(
        child: Text(
          'Error: sessionId or swapId is empty!',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    final sessionRef = FirebaseFirestore.instance
        .collection('swaps')
        .doc(swapId)
        .collection('sessions')
        .doc(sessionId);

    return StreamBuilder<DocumentSnapshot>(
      stream: sessionRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading session: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.data!.exists) {
          return Center(
            child: Text(
              'Session document not found!',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final d = snapshot.data!.data() as Map<String, dynamic>;
        final String title = d['title'] ?? 'Mentoring Session';
        final String duration = d['duration'] ?? '1 hour';
        final String meetingLink = d['meetingLink'] ?? '';
        final String status = d['status'] ?? 'pending';

        DateTime? date;
        final dateField = d['date'];
        if (dateField is Timestamp) {
          date = dateField.toDate();
        }

        final String dateStr = date != null
            ? "${date.day}/${date.month}/${date.year} at ${TimeOfDay.fromDateTime(date).format(context)}"
            : '';

        final Color badgeColor = Theme.of(
          context,
        ).colorScheme.primary; // Blue theme
        final Color secondaryBadgeColor = const Color(
          0xFF6B8AFF,
        ); // Gradient end color
        final Color cardBg = Theme.of(context).colorScheme.surface;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      badgeColor.withOpacity(0.15),
                      secondaryBadgeColor.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(19),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: badgeColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SESSION INVITATION',
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    _StatusBadge(status: status, color: badgeColor),
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.event_rounded, text: dateStr),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.timer_outlined, text: duration),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _openMeetingLink(context, meetingLink),
                      child: _InfoRow(
                        icon: Icons.link_rounded,
                        text: meetingLink.isEmpty
                            ? 'No meeting link available'
                            : meetingLink,
                        color: badgeColor,
                      ),
                    ),

                    // Actions
                    if (status == 'pending' && !isMine) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'REJECT',
                              color: Colors.redAccent,
                              onPressed: () => _updateSessionStatus(
                                context,
                                sessionRef,
                                'rejected',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              label: 'ACCEPT',
                              color: badgeColor,
                              isPrimary: true,
                              onPressed: () => _updateSessionStatus(
                                context,
                                sessionRef,
                                'accepted',
                              ),
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
                                label: 'COMPLETE',
                                color: Colors.greenAccent,
                                textColor: Colors.black,
                                onPressed: () =>
                                    _completeSession(context, sessionRef),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: _ActionButton(
                              label: 'JOIN MEETING',
                              color: badgeColor,
                              isPrimary: true,
                              onPressed: () =>
                                  _openMeetingLink(context, meetingLink),
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

  Future<void> _openMeetingLink(
    BuildContext context,
    String meetingLink,
  ) async {
    if (meetingLink.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no_meeting_link'.tr())),
      );
      return;
    }

    final link = meetingLink.trim();
    final uri = Uri.tryParse(link.contains('://') ? link : 'https://$link');
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('invalid_meeting_link'.tr())));
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('could_not_open_link'.tr())),
      );
    }
  }

  Future<void> _updateSessionStatus(
    BuildContext context,
    DocumentReference sessionRef,
    String newStatus,
  ) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Fetch session details to get title and creator ID
      final sessionSnap = await sessionRef.get();
      final sessionData = sessionSnap.data() as Map<String, dynamic>?;
      final String sessionTitle = sessionData?['title'] ?? 'Session';

      // The creator is the parent chat message sender (which is the mentor)
      // Let's retrieve other details from the parent swap Listing
      final swapDoc = await FirebaseFirestore.instance
          .collection('swaps')
          .doc(swapId)
          .get();
      final swapData = swapDoc.data();
      final String mentorId = swapData?['mentorId'] ?? '';
      final String learnerId = swapData?['learnerId'] ?? '';

      final String targetUserId = uid == mentorId ? learnerId : mentorId;
      final mentorName = await UserDisplayName.resolve(
        FirebaseFirestore.instance,
        mentorId,
        fallback: UserDisplayName.isUsable(sessionData?['mentorName'])
            ? sessionData!['mentorName'].toString().trim()
            : UserDisplayName.isUsable(swapData?['mentorName'])
            ? swapData!['mentorName'].toString().trim()
            : '',
        authDisplayName: uid == mentorId
            ? FirebaseAuth.instance.currentUser?.displayName
            : null,
      );
      final learnerName = await UserDisplayName.resolve(
        FirebaseFirestore.instance,
        learnerId,
        fallback: UserDisplayName.isUsable(sessionData?['learnerName'])
            ? sessionData!['learnerName'].toString().trim()
            : UserDisplayName.isUsable(swapData?['learnerName'])
            ? swapData!['learnerName'].toString().trim()
            : '',
        authDisplayName: uid == learnerId
            ? FirebaseAuth.instance.currentUser?.displayName
            : null,
      );
      final rawSenderName = uid == mentorId ? mentorName : learnerName;
      final senderName = UserDisplayName.isUsable(rawSenderName)
          ? rawSenderName
          : 'Someone';

      final batch = FirebaseFirestore.instance.batch();
      batch.update(sessionRef, {
        'status': newStatus,
        if (UserDisplayName.isUsable(mentorName)) 'mentorName': mentorName,
        if (UserDisplayName.isUsable(learnerName)) 'learnerName': learnerName,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        if (newStatus == 'accepted') 'acceptedAt': FieldValue.serverTimestamp(),
        if (newStatus == 'rejected') 'rejectedAt': FieldValue.serverTimestamp(),
      });

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

        batch.update(
          FirebaseFirestore.instance.collection('conversations').doc(convoId),
          {
            'lastMessage': newStatus == 'accepted'
                ? 'Session Invite Accepted'
                : 'Session Invite Declined',
            'lastMessageAt': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
      await _deleteSessionNotification(uid);

      if (newStatus == 'accepted') {
        final dateField = sessionData?['date'] ?? sessionData?['sessionDate'];
        final DateTime? startTime = dateField is Timestamp
            ? dateField.toDate()
            : null;
        if (startTime != null) {
          final reminderService = SessionReminderService();
          final otherName = await reminderService.resolveOtherUserName(
            SessionModel(
              id: sessionId,
              swapId: swapId,
              title: sessionTitle,
              date: startTime,
              duration: sessionData?['duration'] ?? '',
              meetingLink: sessionData?['meetingLink'] ?? '',
              mentorId: mentorId,
              learnerId: learnerId,
              mentorName: mentorName,
              learnerName: learnerName,
              participantIds: List<String>.from(
                sessionData?['participantIds'] ?? [mentorId, learnerId],
              ),
              status: newStatus,
              createdAt: DateTime.now(),
            ),
            uid,
          );
          await reminderService.scheduleSessionReminder(
            sessionId: sessionId,
            swapId: swapId,
            sessionStartTime: startTime,
            otherUserName: otherName,
          );
        }
      } else if (newStatus == 'rejected') {
        await SessionReminderService().disableSessionReminders(
          sessionId: sessionId,
          swapId: swapId,
        );
      }

      // Send real-time notification
      if (targetUserId.isNotEmpty) {
        final String notificationTitle = newStatus == 'accepted'
            ? 'Session Accepted! 🎉'
            : 'Session Declined';
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
          'actionRoute': '/chat',
          'actionId': convoId,
          'imageUrl': '',
          'data': {
            'conversationId': convoId,
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

  Future<void> _deleteSessionNotification(String uid) async {
    final notificationSnap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    var hasDeletes = false;
    for (final doc in notificationSnap.docs) {
      final data = doc.data();
      if (data['type'] != 'session') continue;
      final payload = data['data'];
      if (payload is! Map<String, dynamic>) continue;
      if (payload['sessionId'] == sessionId || payload['swapId'] == swapId) {
        batch.delete(doc.reference);
        hasDeletes = true;
      }
    }
    if (hasDeletes) {
      await batch.commit();
    }
  }

  Future<void> _completeSession(
    BuildContext context,
    DocumentReference sessionRef,
  ) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // 1. Fetch swap and session data
      final parentSwapRef = FirebaseFirestore.instance
          .collection('swaps')
          .doc(swapId);
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

        batch.update(
          FirebaseFirestore.instance.collection('conversations').doc(convoId),
          {
            'lastMessage': 'Mentoring Session Completed 🎉',
            'lastMessageAt': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
      await SkillExchangeService().completeSessionAndSync(
        swapId: swapId,
        sessionId: sessionId,
      );
      await SessionReminderService().disableSessionReminders(
        sessionId: sessionId,
        swapId: swapId,
      );

      final mentorName = await UserDisplayName.resolve(
        FirebaseFirestore.instance,
        uid,
        fallback: UserDisplayName.isUsable(sData?['mentorName'])
            ? sData!['mentorName'].toString().trim()
            : '',
        authDisplayName: FirebaseAuth.instance.currentUser?.displayName,
      );
      final displayMentorName = UserDisplayName.isUsable(mentorName)
          ? mentorName
          : 'Someone';

      // 3. Send Completed Notification to the learner
      if (learnerId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'senderId': uid,
          'senderName': displayMentorName,
          'senderProfilePic': '',
          'receiverId': learnerId,
          'type': 'session',
          'title': 'Session Completed! 🎉',
          'body':
              'Your session "$sessionTitle" with $displayMentorName has been completed.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'actionRoute': '/chat',
          'actionId': convoId,
          'imageUrl': '',
          'data': {
            'conversationId': convoId,
            'sessionId': sessionId,
            'swapId': swapId,
            'type': 'session',
            'status': 'completed',
          },
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('session_completed_success'.tr()),
          backgroundColor: Colors.green,
        ),
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
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color:
              color ??
              Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color:
                  color ??
                  Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
  final Color? textColor;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.isPrimary = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = isPrimary
        ? Theme.of(context).colorScheme.onSurface
        : color;
    final finalTextColor = textColor ?? defaultTextColor;

    return SizedBox(
      height: 42, // Scaled down for card layout
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? color : Colors.transparent,
          foregroundColor: finalTextColor,
          elevation: 0,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              12,
            ), // Scaled down to match height
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13, // Scaled down for card layout
            fontWeight: FontWeight.bold,
            color: finalTextColor,
          ),
        ),
      ),
    );
  }
}

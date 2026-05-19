import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class NotificationsScreen extends StatelessWidget {
  NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'notifications'.tr(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: uid == null
          ? _buildEmptyState(context)
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('recipientId', isEqualTo: uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _NotificationCard(
                      title: data['title'] ?? 'New Notification',
                      message: data['message'] ?? '',
                      type: data['type'] ?? 'info',
                      timestamp: data['timestamp'] as Timestamp?,
                      isRead: data['isRead'] ?? false,
                      onTap: () {
                        // Mark as read
                        FirebaseFirestore.instance
                            .collection('notifications')
                            .doc(docs[index].id)
                            .update({'isRead': true});

                        // Handle navigation based on type if needed
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(26)),
            ),
            child: Icon(Icons.notifications_off_outlined, color: Theme.of(context).colorScheme.primary.withAlpha(128), size: 48),
          ),
          SizedBox(height: 24),
          Text(
            'all_caught_up'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'notifications_will_show'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 14),
          ),
        ],
      ),
    );
  }

  }


String _formatTime(DateTime dt) {
  final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final m = dt.minute.toString().padLeft(2, '0');
  final p = dt.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $p';
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String type;
  final Timestamp? timestamp;
  final bool isRead;
  final VoidCallback onTap;

  _NotificationCard({
    required this.title,
    required this.message,
    required this.type,
    this.timestamp,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'message':
        iconData = Icons.chat_bubble_rounded;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      case 'swap_request':
        iconData = Icons.swap_horiz_rounded;
        iconColor = Color(0xFFFBBF24);
        break;
      case 'swap_confirmed':
        iconData = Icons.check_circle_rounded;
        iconColor = Color(0xFF22C55E);
        break;
      default:
        iconData = Icons.notifications_rounded;
        iconColor = Color(0xFF6B8AFF);
    }

    final timeStr = timestamp != null
        ? _formatTime(timestamp!.toDate())
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Theme.of(context).colorScheme.surface.withAlpha(128) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRead ? Colors.transparent : Theme.of(context).colorScheme.primary.withAlpha(51),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant, fontSize: 11),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      message,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),

              // Unread Dot
              if (!isRead)
                Container(
                  margin: EdgeInsets.only(left: 8, top: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

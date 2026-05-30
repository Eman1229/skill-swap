import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';
import 'package:skill_swap/screens/Chat/conversation_screen.dart';
import 'package:skill_swap/screens/Swap/skill_detail_screen.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/screens/Home%20Screens/swapping%20Available.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'notifications'.tr(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          // StreamBuilder for Unread Counter badge in AppBar
          if (uid != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('receiverId', isEqualTo: uid)
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data?.docs.length ?? 0;
                if (unreadCount == 0) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(right: 16, top: 14, bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$unreadCount New',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: uid == null
          ? _buildEmptyState(context)
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('receiverId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _NotificationCard(
                      title: data['title'] ?? 'Notification',
                      body: data['body'] ?? '',
                      type: data['type'] ?? 'general',
                      timestamp: data['createdAt'] as Timestamp?,
                      isRead: data['isRead'] ?? false,
                      onTap: () => _handleNotificationClick(context, doc.id, data),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _handleNotificationClick(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    // 1. Mark notification as read in Firestore
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});

    final String deepLinkScreen = data['deepLinkScreen'] ?? '';
    final String referenceId = data['referenceId'] ?? '';
    final String senderId = data['senderId'] ?? '';

    if (deepLinkScreen.isEmpty || referenceId.isEmpty) return;

    // 2. Perform Deep Linking Navigation
    if (deepLinkScreen == 'chat') {
      final name = data['senderName'] ?? 'Swap Partner';
      final imageUrl = data['senderImageUrl'] as String?;
      final swap = SwapListing(
        id: referenceId, // Conversation ID
        userId: senderId,
        name: name,
        initials: name.trim().split(' ').length >= 2
            ? '${name.trim().split(' ')[0][0]}${name.trim().split(' ')[1][0]}'.toUpperCase()
            : (name.isNotEmpty ? name[0].toUpperCase() : 'U'),
        avatarColor: const Color(0xFF6B8AFF),
        offering: 'Skill Swap',
        wanting: 'Learning',
        rating: 0.0,
        reviews: 0,
        category: 'All',
        imageUrl: imageUrl,
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ConversationScreen(swap: swap)),
      );
    } else if (deepLinkScreen == 'swap_detail') {
      // Show loading spinner dialog while fetching the swap detail doc
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00C2FF)),
        ),
      );

      try {
        final doc = await FirebaseFirestore.instance
            .collection('swaps')
            .doc(referenceId)
            .get();

        Navigator.pop(context); // Dismiss loading dialog

        if (doc.exists) {
          final swapModel = SwapModel.fromDoc(doc);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SkillDetailScreen(swap: swapModel)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: Swap Details not found.")),
          );
        }
      } catch (e) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching swap details: $e")),
        );
      }
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'all_caught_up'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
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

class _NotificationCard extends StatelessWidget {
  final String title;
  final String body;
  final String type;
  final Timestamp? timestamp;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.title,
    required this.body,
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
      case 'swap':
        iconData = Icons.swap_horiz_rounded;
        iconColor = const Color(0xFFFBBF24); // Amber
        break;
      case 'progress':
        iconData = Icons.playlist_add_check_circle_rounded;
        iconColor = const Color(0xFF22C55E); // Green
        break;
      case 'review':
        iconData = Icons.star_rounded;
        iconColor = const Color(0xFFA855F7); // Purple
        break;
      default:
        iconData = Icons.notifications_rounded;
        iconColor = const Color(0xFF6B8AFF); // Slate Blue
    }

    final timeStr = timestamp != null ? _formatTime(timestamp!.toDate()) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead
            ? Theme.of(context).colorScheme.surface.withOpacity(0.4)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRead ? Colors.transparent : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
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

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }
}

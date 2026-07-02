import 'package:flutter/material.dart';
import 'package:skill_swap/models/notification_model.dart';
import 'package:skill_swap/screens/Chat/conversation_screen.dart';
import 'package:skill_swap/screens/Home Screens/swapping Available.dart';
import 'package:skill_swap/screens/Swap/course_assets_screen.dart';
import 'package:skill_swap/services/notification_repository.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';
import 'package:intl/intl.dart';
    import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/screens/Swap/confirm_swap_completion_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _repo = NotificationRepository();
  late Stream<List<NotificationModel>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream = _repo.notificationsStream();
  }

  Map<String, List<NotificationModel>> _groupNotifications(
    List<NotificationModel> list,
  ) {
    final Map<String, List<NotificationModel>> groups = {
      'Today': [],
      'Yesterday': [],
      'Older': [],
    };

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    for (var n in list) {
      final date = n.createdAt;
      if (date.isAfter(todayStart)) {
        groups['Today']!.add(n);
      } else if (date.isAfter(yesterdayStart)) {
        groups['Yesterday']!.add(n);
      } else {
        groups['Older']!.add(n);
      }
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'notifications'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, size: 22),
            onPressed: () => _repo.markAllAsRead(),
            tooltip: 'Mark all as read',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, size: 22),
            onPressed: () => _showClearAllDialog(),
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _notificationsStream = _repo.notificationsStream();
          });
        },
        color: const Color(0xFF00C2FF),
        child: StreamBuilder<List<NotificationModel>>(
          stream: _notificationsStream,
          builder: (context, snapshot) {
            // 1. Errors
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            // 2. Loading
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return _buildShimmerLoading();
            }

            final notifications = snapshot.data ?? [];

            // 3. Empty State
            if (notifications.isEmpty) {
              return _buildEmptyState();
            }

            // 4. Grouped Data List
            return _buildGroupedList(notifications);
          },
        ),
      ),
    );
  }

  Widget _buildGroupedList(List<NotificationModel> notifications) {
    final groups = _groupNotifications(notifications);
    final todayList = groups['Today']!;
    final yesterdayList = groups['Yesterday']!;
    final olderList = groups['Older']!;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (todayList.isNotEmpty) ...[
          _buildSectionHeaderSliver("Today"),
          _buildNotificationsListSliver(todayList),
        ],
        if (yesterdayList.isNotEmpty) ...[
          _buildSectionHeaderSliver("Yesterday"),
          _buildNotificationsListSliver(yesterdayList),
        ],
        if (olderList.isNotEmpty) ...[
          _buildSectionHeaderSliver("Older"),
          _buildNotificationsListSliver(olderList),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  Widget _buildSectionHeaderSliver(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF00C2FF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsListSliver(List<NotificationModel> list) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final notification = list[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _NotificationTile(
              notification: notification,
              onTap: () => _handleNotificationTap(notification),
              onDelete: () => _repo.deleteNotification(notification.id),
            ),
          );
        }, childCount: list.length),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          height: 80,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              'something_went_wrong'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C2FF),
              ),
              child: const Text("Retry", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'all_caught_up'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'notifications_will_show'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    _repo.markAsRead(notification.id);

    if (notification.type == NotificationType.assetUpload) {
      final courseId = notification.data['courseId'] ?? notification.data['swapId'] ?? '';
      final assetId = notification.data['assetId'] ?? notification.actionId ?? '';
      if (courseId.toString().isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseAssetsScreen(
              courseId: courseId.toString(),
              highlightedAssetId: assetId.toString(),
            ),
          ),
        );
        return;
      }
    }
    if (notification.actionRoute == '/confirm_completion' || notification.data['type'] == 'completion_request') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmSwapCompletionScreen(swapId: notification.actionId ?? ''),
        ),
      );
      return;
    }

    final String actionId = notification.actionId ?? '';
    final String convoId = actionId.isNotEmpty
        ? actionId
        : notification.data['conversationId'] ?? '';
    final String otherUid = notification.senderId;
    final String otherName = notification.senderName;

    if (convoId.isNotEmpty && otherUid.isNotEmpty) {
      final swap = SwapListing(
        id: convoId,
        userId: otherUid,
        name: otherName,
        initials: otherName.isNotEmpty ? otherName[0] : 'U',
        avatarColor: const Color(0xFF6B8AFF),
        offering: '',
        wanting: '',
        rating: 0.0,
        reviews: 0,
        category: 'All',
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ConversationScreen(swap: swap)),
      );
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('clear_all_notifications'.tr()),
        content: Text('clear_all_notifications_desc'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              _repo.clearAll();
              Navigator.pop(context);
            },
            child: Text(
              'clear'.tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color iconColor = _getIconColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.redAccent,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                : (isDark ? const Color(0xFF2E3E5C) : const Color(0xFFF0F7FF)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: notification.isRead
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              if (!notification.isRead)
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar or Custom Icon
              _buildAvatar(context),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF00C2FF),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTimestamp(notification.createdAt),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                            fontSize: 10,
                          ),
                        ),
                        // Badge Category
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getCategoryLabel(notification.type),
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final hasProfilePic = notification.senderProfilePic.isNotEmpty;
    final initials = notification.senderName.isNotEmpty
        ? notification.senderName
              .trim()
              .split(' ')
              .map((e) => e[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'U';

    return Stack(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: ClipOval(
            child: hasProfilePic
                ? Image.network(
                    notification.senderProfilePic,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildInitialsWidget(context, initials),
                  )
                : _buildInitialsWidget(context, initials),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _getIconColor(notification.type),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).cardColor,
                width: 1.5,
              ),
            ),
            child: Icon(
              _getIcon(notification.type),
              color: Colors.white,
              size: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsWidget(BuildContext context, String initials) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.swapRequest:
        return Icons.swap_horiz_rounded;
      case NotificationType.chatMessage:
        return Icons.chat_bubble_outline_rounded;
      case NotificationType.session:
        return Icons.chat_bubble_outline_rounded;
      case NotificationType.assetUpload:
        return Icons.folder_copy_rounded;
      case NotificationType.system:
        return Icons.campaign_rounded;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.swapRequest:
        return const Color(0xFF00C2FF);
      case NotificationType.chatMessage:
        return const Color(0xFF6B8AFF);
      case NotificationType.session:
        return Colors.greenAccent;
      case NotificationType.assetUpload:
        return const Color(0xFF00C2FF);
      case NotificationType.system:
        return Colors.orangeAccent;
    }
  }

  String _getCategoryLabel(NotificationType type) {
    switch (type) {
      case NotificationType.swapRequest:
        return "SWAP";
      case NotificationType.chatMessage:
        return "CHAT";
      case NotificationType.session:
        return "SESSION";
      case NotificationType.assetUpload:
        return "ASSET";
      case NotificationType.system:
        return "ALERT";
    }
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return DateFormat('hh:mm a').format(date);
    if (diff.inDays < 7) return DateFormat('EEEE').format(date);
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

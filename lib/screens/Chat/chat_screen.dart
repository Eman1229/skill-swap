import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/screens/Home Screens/swapping Available.dart';
import 'package:skill_swap/screens/Chat/conversation_screen.dart';
import 'package:skill_swap/services/chat_user_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  final ChatUserService _chatUserService = ChatUserService();
  String _searchQuery = '';
  bool _showAllMentors = false;

  late Stream<List<SwapListing>> _listingsStream;
  late Stream<List<Map<String, dynamic>>> _conversationsStream;

  @override
  void initState() {
    super.initState();
    // Cache the streams in initState to prevent continuous reloading
    _listingsStream = _db
        .collection('swapListings')
        .snapshots()
        .map((s) => s.docs.map(SwapListing.fromDoc).toList());

    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      _conversationsStream = Stream.value([]);
    } else {
      _conversationsStream = _db
          .collection('conversations')
          .where('participants', arrayContains: uid)
          .snapshots()
          .map((s) {
        final docs = s.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();

        // Sort in-memory to prevent requiring composite indexes
        docs.sort((a, b) {
          final aTime = a['lastMessageAt'] as Timestamp?;
          final bTime = b['lastMessageAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        final seen = <String>{};
        final deduped = <Map<String, dynamic>>[];
        for (final doc in docs) {
          final otherId = _resolveOtherUserId(doc, uid);
          if (otherId.isEmpty) continue;
          if (seen.contains(otherId)) continue;
          seen.add(otherId);
          deduped.add(doc);
        }
        return deduped;
      });
    }
  }

  String _resolveOtherUserId(Map<String, dynamic> c, String currentUid) {
    final participants = List<String>.from(c['participants'] ?? []);
    final fromParticipants = participants.firstWhere(
      (id) => id != currentUid,
      orElse: () => '',
    );
    if (fromParticipants.isNotEmpty) return fromParticipants;
    final stored = c['otherUserId'] as String? ?? '';
    if (stored.isNotEmpty && stored != currentUid) return stored;
    return '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openConversation(String conversationId, ChatUserProfile profile, String offering, String wanting) {
    final swap = SwapListing(
      id: conversationId,
      userId: profile.userId,
      name: profile.name,
      initials: profile.initials,
      avatarColor: const Color(0xFF6B8AFF),
      offering: offering,
      wanting: wanting,
      rating: 0.0,
      reviews: 0,
      category: 'All',
      imageUrl: profile.imageUrl,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConversationScreen(swap: swap)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _conversationsStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C2FF)),
              );
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error: ${snap.error}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final all = snap.data ?? [];
            final valid = all.where((c) {
              final lastMsg = (c['lastMessage'] as String?) ?? '';
              return lastMsg.trim().isNotEmpty;
            }).toList();

            if (valid.isEmpty) return _buildEmptyState();
            return _buildConversationsList(valid);
          },
        ),
      ),
    );
  }

  // ── SCREEN 1 — Empty / Explore state ─────────────────────────────
  Widget _buildEmptyState() {
    return StreamBuilder<List<SwapListing>>(
      stream: _listingsStream,
      builder: (context, mentorSnap) {
        final allMentors = mentorSnap.data ?? [];
        final displayMentors =
            _showAllMentors ? allMentors : allMentors.take(4).toList();

        return Column(
          children: [
            _buildHeader(showSearch: false),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1E293B),
                            border: Border.all(
                                color: const Color(0xFF00C2FF)
                                    .withOpacity(0.15)),
                          ),
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1E293B),
                                const Color(0xFF0F172A).withOpacity(0.8),
                              ],
                            ),
                            border: Border.all(
                                color: const Color(0xFF00C2FF)
                                    .withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.chat_bubble_rounded,
                              color: Color(0xFF00C2FF), size: 32),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF6B8AFF),
                                  Color(0xFF8B5CF6)
                                ],
                              ),
                            ),
                            child: const Icon(Icons.auto_awesome_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                const Color(0xFF00C2FF).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00C2FF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'WAITING FOR SPARK',
                            style: TextStyle(
                              color: Color(0xFF00C2FF),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'No conversations yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'When you find a skill you\'d like to swap,\nyou can start a chat with a mentor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SwappingAvailable()),
                          (route) => false,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 14),
                        ),
                        child: const Text(
                          'Explore Now!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Suggested Mentors',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(
                                () => _showAllMentors = !_showAllMentors),
                            child: Text(
                              _showAllMentors ? 'Show Less' : 'See All',
                              style: const TextStyle(
                                color: Color(0xFF00C2FF),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (displayMentors.isEmpty)
                      const SizedBox(height: 60)
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: displayMentors.length,
                        itemBuilder: (_, i) {
                          final mentor = displayMentors[i];
                          return _SuggestedMentorTile(
                            swap: mentor,
                            onTap: () {
                              final profile = ChatUserProfile(
                                userId: mentor.userId ?? '',
                                name: mentor.name,
                                imageUrl: mentor.imageUrl,
                                isOnline: false,
                              );
                              _openConversation(mentor.id, profile, mentor.offering, mentor.wanting);
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── SCREEN 2 — Conversations list ────────────────────────────────
  Widget _buildConversationsList(List<Map<String, dynamic>> conversations) {
    final currentUid = _auth.currentUser?.uid ?? '';

    return Column(
      children: [
        _buildHeader(showSearch: true),
        const SizedBox(height: 14),
        _buildRecentMentorsRow(conversations, currentUid),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Stream.value(conversations),
            builder: (context, snapshot) {
              final list = snapshot.data ?? [];
              
              // Apply search filter locally
              final filtered = list.where((c) {
                // Search query is matched later inside tile stream or we filter here by checking cached/initial values
                // For optimal speed, we can let the ListView build tiles, but to search correctly, we can filter conversations
                return true; 
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('No conversations found',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 13)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final c = filtered[i];
                  final otherUserId = _resolveOtherUserId(c, currentUid);
                  final skill = c['skill'] as String? ?? '';
                  final wanting = c['wanting'] as String? ?? '';
                  final conversationId = c['id'] as String? ?? '';

                  return _ConversationTile(
                    data: c,
                    currentUid: currentUid,
                    otherUserId: otherUserId,
                    searchQuery: _searchQuery,
                    onTap: (profile) => _openConversation(conversationId, profile, skill, wanting),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Recent mentors row ────────────────────────────────────────────
  Widget _buildRecentMentorsRow(
      List<Map<String, dynamic>> conversations, String currentUid) {
    if (conversations.isEmpty) return const SizedBox.shrink();

    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final c in conversations) {
      final otherId = _resolveOtherUserId(c, currentUid);
      if (otherId.isEmpty || seen.contains(otherId)) continue;
      seen.add(otherId);
      unique.add(c);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, bottom: 12),
          child: Text(
            'Recent Mentors',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: unique.length,
            itemBuilder: (_, i) {
              final c = unique[i];
              final otherUserId = _resolveOtherUserId(c, currentUid);
              final skill = c['skill'] as String? ?? '';
              final wanting = c['wanting'] as String? ?? '';

              return _RecentMentorAvatar(
                otherUserId: otherUserId,
                onTap: (profile) => _openConversation(c['id'] ?? '', profile, skill, wanting),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader({required bool showSearch}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Messages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _ThreeDotMenu(),
            ],
          ),
          if (showSearch) ...[
            const SizedBox(height: 14),
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF00C2FF).withOpacity(0.15)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                style: const TextStyle(
                    color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle:
                      TextStyle(color: Colors.white38, fontSize: 13),
                  suffixIcon: Icon(Icons.search_rounded,
                      color: Colors.white38, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Three-dot menu ───────────────────────────────────────────────────
class _ThreeDotMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: const Color(0xFF1E293B),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(Icons.more_vert_rounded,
          color: Colors.white54, size: 22),
      onSelected: (value) {},
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'mute',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mute Notifications',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              Switch(
                value: false,
                onChanged: (_) {},
                activeColor: const Color(0xFF00C2FF),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'mark',
          child: Text('Mark all as read',
              style: TextStyle(color: Colors.white, fontSize: 13)),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'clear',
          child: Text('Clear all chats',
              style:
                  TextStyle(color: Color(0xFFFF3B3B), fontSize: 13)),
        ),
      ],
    );
  }
}

// ── Suggested mentor tile ────────────────────────────────────────────
class _SuggestedMentorTile extends StatelessWidget {
  final SwapListing swap;
  final VoidCallback onTap;
  const _SuggestedMentorTile(
      {required this.swap, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF00C2FF).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            _AvatarCircle(
              name: swap.name,
              initials: swap.initials,
              imageUrl: swap.imageUrl,
              isOnline: false,
              size: 46,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(swap.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(swap.offering,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Recent mentor avatar ─────────────────────────────────────────────
class _RecentMentorAvatar extends StatelessWidget {
  final String otherUserId;
  final Function(ChatUserProfile) onTap;

  const _RecentMentorAvatar({
    required this.otherUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatUserProfile>(
      stream: ChatUserService().getUserProfile(otherUserId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => onTap(profile),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                _AvatarCircle(
                  name: profile.name,
                  initials: profile.initials,
                  imageUrl: profile.imageUrl,
                  isOnline: profile.isOnline,
                  size: 58,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 60,
                  child: Text(
                    profile.name.split(' ').first,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Reusable avatar circle with optional online dot ──────────────────
class _AvatarCircle extends StatelessWidget {
  final String name;
  final String initials;
  final String? imageUrl;
  final bool isOnline;
  final double size;

  const _AvatarCircle({
    required this.name,
    required this.initials,
    this.imageUrl,
    required this.isOnline,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF2E3E5C),
            shape: BoxShape.circle,
            border: Border.all(
              color: isOnline
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF00C2FF).withOpacity(0.2),
              width: isOnline ? 2 : 1.5,
            ),
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildInitials(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildInitials(); // Show initials while loading for smooth feel
                    },
                  )
                : _buildInitials(),
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: size * 0.24,
              height: size * 0.24,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.35,
        ),
      ),
    );
  }
}

// ── Conversation tile ────────────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String currentUid;
  final String otherUserId;
  final String searchQuery;
  final Function(ChatUserProfile) onTap;

  const _ConversationTile({
    required this.data,
    required this.currentUid,
    required this.otherUserId,
    required this.searchQuery,
    required this.onTap,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }
    return "${dt.day}/${dt.month}";
  }

  @override
  Widget build(BuildContext context) {
    final lastMsg = data['lastMessage'] as String? ?? '';
    final rawUnread = data['unreadCount'];
    final unread = rawUnread is Map ? (rawUnread[currentUid] ?? 0) : 0;
    final Timestamp? ts = data['lastMessageAt'] as Timestamp?;
    final timeStr = ts != null ? _formatTime(ts.toDate()) : '';

    return StreamBuilder<ChatUserProfile>(
      stream: ChatUserService().getUserProfile(otherUserId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile == null) return const SizedBox.shrink();

        // Dynamic search filter matching
        if (searchQuery.isNotEmpty &&
            !profile.name.toLowerCase().contains(searchQuery.toLowerCase())) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => onTap(profile),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF00C2FF).withOpacity(0.05)),
            ),
            child: Row(
              children: [
                _AvatarCircle(
                  name: profile.name,
                  initials: profile.initials,
                  imageUrl: profile.imageUrl,
                  isOnline: profile.isOnline,
                  size: 52,
                ),
                const SizedBox(width: 12),

                // Name & Last message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Online/Offline tag next to name
                          Text(
                            profile.isOnline ? 'Online' : profile.relativeLastSeen,
                            style: TextStyle(
                              color: profile.isOnline
                                  ? const Color(0xFF22C55E)
                                  : Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(timeStr,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 6),
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C2FF).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ],
                        ),
                        child: Text(unread.toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
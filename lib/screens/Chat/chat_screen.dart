import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/screens/Home Screens/swapping Available.dart';
import 'package:skill_swap/screens/Chat/conversation_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showAllMentors = false; // ── controls See All toggle

  Stream<List<SwapListing>> get _listingsStream => _db
      .collection('swapListings')
      .snapshots()
      .map((s) => s.docs.map(SwapListing.fromDoc).toList());

  Stream<List<Map<String, dynamic>>> get _conversationsStream {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return Stream.value([]);
    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((s) {
      final docs = s.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();
      docs.sort((a, b) {
        final aTs = a['lastMessageAt'] as Timestamp?;
        final bTs = b['lastMessageAt'] as Timestamp?;
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return bTs.compareTo(aTs);
      });
      return docs;
    });
  }

  String _resolveName(Map<String, dynamic> c, String currentUid) {
    final participants = List<String>.from(c['participants'] ?? []);
    final otherUserId = participants.firstWhere(
          (id) => id != currentUid,
      orElse: () => '',
    );
    if (c['otherUserId'] == otherUserId) {
      final name = c['otherName'] as String?;
      return (name != null && name.trim().isNotEmpty) ? name : 'Unknown';
    } else {
      final name = c['senderName'] as String?;
      return (name != null && name.trim().isNotEmpty) ? name : 'Unknown';
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

  void _openConversation(SwapListing swap) {
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
        // Show only 4 unless See All is tapped
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

                    // Icon area
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

                    // Badge
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

                    // Explore Now button
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

                    // Suggested Mentors header
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

                    // Mentor list — 4 or all
                    if (displayMentors.isEmpty)
                      const SizedBox(height: 60)
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: displayMentors.length,
                        itemBuilder: (_, i) => _SuggestedMentorTile(
                          swap: displayMentors[i],
                          onTap: () =>
                              _openConversation(displayMentors[i]),
                        ),
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

    final filtered = conversations.where((c) {
      final name = _resolveName(c, currentUid).toLowerCase();
      return _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildHeader(showSearch: true),
        const SizedBox(height: 14),
        _buildRecentMentorsRow(conversations, currentUid),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
            child: Text('No conversations found',
                style: TextStyle(
                    color: Colors.white38, fontSize: 13)),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final c = filtered[i];
              final otherUserId =
              _resolveOtherUserId(c, currentUid);
              final name = _resolveName(c, currentUid);
              final skill = c['skill'] as String? ?? '';
              final wanting = c['wanting'] as String? ?? '';
              final conversationId = c['id'] as String? ?? '';

              final initials =
              name.trim().split(' ').length >= 2
                  ? '${name.trim().split(' ')[0][0]}${name.trim().split(' ')[1][0]}'
                  .toUpperCase()
                  : name.isNotEmpty
                  ? name[0].toUpperCase()
                  : 'U';

              final swap = SwapListing(
                id: conversationId,
                userId: otherUserId,
                name: name,
                initials: initials,
                avatarColor: const Color(0xFF6B8AFF),
                offering: skill,
                wanting: wanting,
                rating: 0.0,
                reviews: 0,
                category: 'All',
              );

              return _ConversationTile(
                data: c,
                currentUid: currentUid,
                otherUserId: otherUserId,
                resolvedName: name,
                onTap: () => _openConversation(swap),
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
            itemCount: conversations.length,
            itemBuilder: (_, i) {
              final c = conversations[i];
              final otherUserId = _resolveOtherUserId(c, currentUid);
              final name = _resolveName(c, currentUid);
              final initials = name.trim().split(' ').length >= 2
                  ? '${name.trim().split(' ')[0][0]}${name.trim().split(' ')[1][0]}'
                  .toUpperCase()
                  : name.isNotEmpty
                  ? name[0].toUpperCase()
                  : 'U';

              final swap = SwapListing(
                id: c['id'] as String? ?? '',
                userId: otherUserId,
                name: name,
                initials: initials,
                avatarColor: const Color(0xFF6B8AFF),
                offering: c['skill'] as String? ?? '',
                wanting: c['wanting'] as String? ?? '',
                rating: 0.0,
                reviews: 0,
                category: 'All',
              );

              return _RecentMentorAvatar(
                swap: swap,
                otherUserId: otherUserId,
                onTap: () => _openConversation(swap),
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
                onChanged: (v) => setState(() => _searchQuery = v),
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
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: swap.avatarColor,
                  shape: BoxShape.circle),
              child: Center(
                child: Text(swap.initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
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
  final SwapListing swap;
  final String otherUserId;
  final VoidCallback onTap;
  const _RecentMentorAvatar({
    required this.swap,
    required this.otherUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: swap.avatarColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00C2FF),
                      width: 2.5,
                    ),
                  ),
                  child: Center(
                    child: Text(swap.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ),
                ),
                if (otherUserId.isNotEmpty)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherUserId)
                        .snapshots(),
                    builder: (context, snap) {
                      final userData = snap.data?.data()
                      as Map<String, dynamic>?;
                      final isOnline =
                          userData?['isOnline'] as bool? ?? false;
                      if (!isOnline) return const SizedBox.shrink();
                      return Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF0F172A),
                                width: 2),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              swap.name.split(' ').first,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 11),
            ),
          ],
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
  final String resolvedName;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.data,
    required this.currentUid,
    required this.otherUserId,
    required this.resolvedName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lastMsg = data['lastMessage'] as String? ?? '';
    final unread = (data['unreadCount'] as int?) ?? 0;
    final skill = data['skill'] as String? ?? '';
    final Timestamp? ts = data['lastMessageAt'] as Timestamp?;
    final timeStr = ts != null ? _formatTime(ts.toDate()) : '';

    final initials = resolvedName.trim().split(' ').length >= 2
        ? '${resolvedName.trim().split(' ')[0][0]}${resolvedName.trim().split(' ')[1][0]}'
        .toUpperCase()
        : resolvedName.isNotEmpty
        ? resolvedName[0].toUpperCase()
        : 'U';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF00C2FF).withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6B8AFF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),
                if (otherUserId.isNotEmpty)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherUserId)
                        .snapshots(),
                    builder: (context, snap) {
                      final userData = snap.data?.data()
                      as Map<String, dynamic>?;
                      final isOnline =
                          userData?['isOnline'] as bool? ?? false;
                      if (!isOnline) return const SizedBox.shrink();
                      return Positioned(
                        bottom: 1,
                        right: 1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF0F172A),
                                width: 2),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(resolvedName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(timeStr,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C2FF),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('$unread',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                  if (skill.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _SkillTag(
                        label: 'Skill: $skill',
                        color: const Color(0xFF00C2FF)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return 'Yesterday';
  }
}

// ── Skill tag ────────────────────────────────────────────────────────
class _SkillTag extends StatelessWidget {
  final String label;
  final Color color;
  const _SkillTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    );
  }
}
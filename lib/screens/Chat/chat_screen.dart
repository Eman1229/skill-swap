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

  int _selectedIndex = 1;

  Stream<List<SwapListing>> get _listingsStream => _db
      .collection('swapListings')
      .snapshots()
      .map((s) => s.docs.map(SwapListing.fromDoc).toList());

  Stream<List<Map<String, dynamic>>> get _conversationsStream {
    final uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _conversationsStream,
          builder: (context, convSnap) {
            final conversations = convSnap.data ?? [];
            final validConversations = conversations.where((c) {
              final lastMsg = (c['lastMessage'] as String?) ?? '';
              return lastMsg.trim().isNotEmpty;
            }).toList();
            final hasConversations = validConversations.isNotEmpty;

            return hasConversations
                ? _buildConversationsList(validConversations)
                : _buildEmptyState();
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1E293B),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                selected: _selectedIndex == 0,
                onTap: () {
                  setState(() => _selectedIndex = 0);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SwappingAvailable(),
                    ),
                        (route) => false,
                  );
                },
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Chat',
                selected: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              _NavItem(
                icon: Icons.swap_vert_rounded,
                activeIcon: Icons.swap_vert_rounded,
                label: 'Swaps',
                selected: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Settings',
                selected: _selectedIndex == 3,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SCREEN 1 — Empty state ───────────────────────────────────────
  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildHeader(showSearch: false),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Animated icon area
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
                            color:
                            const Color(0xFF00C2FF).withOpacity(0.15)),
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
                            color:
                            const Color(0xFF00C2FF).withOpacity(0.3)),
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
                            colors: [Color(0xFF6B8AFF), Color(0xFF8B5CF6)],
                          ),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Waiting badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF00C2FF).withOpacity(0.3)),
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

                // Suggested Mentors
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Suggested Mentors',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'See All',
                        style: TextStyle(
                          color: const Color(0xFF00C2FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                StreamBuilder<List<SwapListing>>(
                  stream: _listingsStream,
                  builder: (context, snap) {
                    final mentors = snap.data ?? [];
                    if (mentors.isEmpty) {
                      return const SizedBox(height: 60);
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: mentors.length,
                      itemBuilder: (_, i) =>
                          _SuggestedMentorTile(swap: mentors[i]),
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
  }

  // ── SCREEN 2 — Conversations list ───────────────────────────────
  Widget _buildConversationsList(List<Map<String, dynamic>> conversations) {
    final filtered = conversations.where((c) {
      final name = (c['otherName'] as String? ?? '').toLowerCase();
      return _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildHeader(showSearch: true),
        const SizedBox(height: 14),

        // Recent Mentors horizontal row
        StreamBuilder<List<SwapListing>>(
          stream: _listingsStream,
          builder: (context, snap) {
            final mentors = snap.data ?? [];
            if (mentors.isEmpty) return const SizedBox.shrink();
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
                    itemCount: mentors.length,
                    itemBuilder: (_, i) =>
                        _RecentMentorAvatar(swap: mentors[i]),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),

        // Conversations
        Expanded(
          child: filtered.isEmpty
              ? const Center(
            child: Text('No conversations found',
                style:
                TextStyle(color: Colors.white38, fontSize: 13)),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: filtered.length,
            itemBuilder: (_, i) =>
                _ConversationTile(data: filtered[i]),
          ),
        ),
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
                style:
                const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle:
                  TextStyle(color: Colors.white38, fontSize: 13),
                  suffixIcon: Icon(Icons.search_rounded,
                      color: Colors.white38, size: 20),
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 13)),
        ),
      ],
    );
  }
}

// ── Suggested mentor tile (empty state) ─────────────────────────────
class _SuggestedMentorTile extends StatelessWidget {
  final SwapListing swap;
  const _SuggestedMentorTile({required this.swap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationScreen(swap: swap),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  color: swap.avatarColor, shape: BoxShape.circle),
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

// ── Recent mentor avatar (conversations list) ────────────────────────
class _RecentMentorAvatar extends StatelessWidget {
  final SwapListing swap;
  const _RecentMentorAvatar({required this.swap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ConversationScreen(swap: swap)),
      ),
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
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0F172A), width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              swap.name.split(' ').first,
              style:
              const TextStyle(color: Colors.white54, fontSize: 11),
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
  const _ConversationTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // ✅ FIX: Always derive the OTHER person's ID from participants list,
    // not from otherUserId field (which only reflects the original sender's view)
    final participants = List<String>.from(data['participants'] ?? []);
    final otherUserId = participants.firstWhere(
          (id) => id != currentUid,
      orElse: () => '',
    );

    // ✅ FIX: Show correct name depending on who is viewing the conversation.
    // If I am the original sender, otherUserId == data['otherUserId'], so show otherName.
    // If I am the mentor (receiver), show senderName instead.
    final bool iAmTheSender = data['otherUserId'] == otherUserId;
    final name = iAmTheSender
        ? (data['otherName'] as String? ?? 'Unknown')
        : (data['senderName'] as String? ?? 'Unknown');

    final lastMsg = data['lastMessage'] as String? ?? '';
    final unread = (data['unreadCount'] as int?) ?? 0;
    final skill = data['skill'] as String? ?? '';
    final wanting = data['wanting'] as String? ?? '';
    final conversationId = data['id'] as String? ?? '';
    final Timestamp? ts = data['lastMessageAt'] as Timestamp?;
    final timeStr = ts != null ? _formatTime(ts.toDate()) : '';

    final initials = name.trim().split(' ').length >= 2
        ? '${name.trim().split(' ')[0][0]}${name.trim().split(' ')[1][0]}'
        .toUpperCase()
        : name.isNotEmpty
        ? name[0].toUpperCase()
        : '?';

    // ✅ FIX: Pass the correct otherUserId so ConversationScreen
    // resolves the same deterministic conversation doc for both users
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

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationScreen(swap: swap),
        ),
      ),
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
            // Avatar with online dot
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
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0F172A), width: 2),
                    ),
                  ),
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
                        child: Text(name,
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
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
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

// ── Bottom Nav Item ──────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected ? activeIcon : icon,
            color: selected ? const Color(0xFF00C2FF) : Colors.white38,
            size: 24,
          ),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF00C2FF)
                    : Colors.white38,
                fontSize: 10,
                fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
              )),
        ],
      ),
    );
  }
}
import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skill_swap/screens/Home Screens/swapping Available.dart';
import 'package:skill_swap/screens/Chat/conversation_screen.dart';
import 'package:skill_swap/services/chat_user_service.dart';
import 'package:skill_swap/services/chat_repository.dart';
import 'package:skill_swap/services/guest_mode_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatRepository _chatRepo = ChatRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  bool _showAllMentors = false;

  late Stream<List<SwapListing>> _listingsStream;
  late Stream<List<Map<String, dynamic>>> _conversationsStream;
  List<Map<String, dynamic>> _cachedConversations = [];

  @override
  void initState() {
    super.initState();
    _loadCachedConversations();

    if (GuestModeService().isGuestMode) {
      _listingsStream = Stream.value(
        GuestModeService().mockListings.map((m) => SwapListing(
          id: m.id,
          name: m.name,
          initials: m.initials,
          avatarColor: m.avatarColor,
          offering: m.offering,
          wanting: m.wanting,
          rating: m.rating,
          reviews: m.reviews,
          category: m.category,
          isLive: m.isLive,
          skillLevel: m.skillLevel,
          userId: m.userId,
          description: m.description,
          experience: m.experience,
          imageUrl: m.imageUrl,
          isFeatured: m.isFeatured,
        )).toList(),
      );

      _conversationsStream = Stream.value([
        {
          'id': 'demo_convo_101',
          'participants': [GuestModeService().guestUserId, 'user_sarah_1'],
          'lastMessage': 'Awesome! Let us schedule our first 1-on-1 swap session soon!',
          'lastMessageAt': Timestamp.now(),
          'otherUserId': 'user_sarah_1',
          'otherName': 'Sarah Jenkins',
          'otherUserInitials': 'SJ',
          'offering': 'Flutter Architecture & Web',
          'wanting': 'UI/UX System Design',
        }
      ]);
      return;
    }
    
    // Setup mentors stream
    _listingsStream = FirebaseFirestore.instance
        .collection('swapListings')
        .snapshots()
        .map((s) => s.docs.map(SwapListing.fromDoc).toList());

    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      _conversationsStream = Stream.value([]);
    } else {
      // Use raw Firestore map logic here for ChatScreen specifically to match existing UI map dependencies
      // but optimized to avoid loops in the map function.
      _conversationsStream = FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: uid)
          .snapshots()
          .map((s) {
        final docs = s.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();

        // Sort by latest message time
        docs.sort((a, b) {
          final aTime = a['lastMessageAt'] as Timestamp?;
          final bTime = b['lastMessageAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        // Dedupe by other user ID to keep one thread per person
        final seen = <String>{};
        final deduped = <Map<String, dynamic>>[];
        for (final doc in docs) {
          final otherId = _resolveOtherUserId(doc, uid);
          if (otherId.isEmpty) continue;
          if (seen.contains(otherId)) continue;
          seen.add(otherId);
          deduped.add(doc);
        }

        _saveConversationsToCache(deduped);
        
        // Mark as delivered in background using Repo helper
        for (var convo in deduped) {
          _chatRepo.markMessagesAsDelivered(convo['id']);
        }

        return deduped;
      });
    }
  }

  void _onMessageChanged(String v) {
    setState(() => _searchQuery = v.trim());
  }

  Future<void> _loadCachedConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_conversations');
      if (cachedStr != null) {
        final List<dynamic> decoded = jsonDecode(cachedStr);
        final list = decoded.map((c) {
          final Map<String, dynamic> map = Map<String, dynamic>.from(c);
          if (map['lastMessageAt'] is String) {
            final dt = DateTime.parse(map['lastMessageAt']);
            map['lastMessageAt'] = Timestamp.fromDate(dt);
          }
          return map;
        }).toList();
        if (mounted) {
          setState(() {
            _cachedConversations = list;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading cached conversations: $e");
    }
  }

  Future<void> _saveConversationsToCache(List<Map<String, dynamic>> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((c) {
        final Map<String, dynamic> copy = Map.from(c);
        if (copy['lastMessageAt'] is Timestamp) {
          copy['lastMessageAt'] = (copy['lastMessageAt'] as Timestamp).toDate().toIso8601String();
        }
        return copy;
      }).toList();
      await prefs.setString('cached_conversations', jsonEncode(jsonList));
    } catch (e) {
      debugPrint("Error saving cached conversations: $e");
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

  Future<void> _openConversation(String conversationId, ChatUserProfile profile, String offering, String wanting) async {
    // Navigate immediately, don't wait for Firestore write
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
    context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _conversationsStream,
          builder: (context, snap) {
            // Priority 1: Live data
            if (snap.hasData && snap.data!.isNotEmpty) {
              return _buildConversationsList(snap.data!);
            }
            
            // Priority 2: Cached data while loading
            if (snap.connectionState == ConnectionState.waiting && _cachedConversations.isNotEmpty) {
              return _buildConversationsList(_cachedConversations);
            }

            // Priority 3: Loading spinner if nothing yet
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C2FF)),
              );
            }
            
            // Priority 4: Empty state
            return _buildEmptyState();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    _buildEmptyIllustration(isDark),
                    const SizedBox(height: 28),
                    Text(
                      'No conversations yet',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'When you find a skill you\'d like to swap, you can start a chat with a mentor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildExploreButton(),
                    const SizedBox(height: 40),
                    _buildSuggestedMentorsSection(displayMentors),
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

  Widget _buildEmptyIllustration(bool isDark) {
     return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border.all(color: const Color(0xFF00C2FF).withOpacity(0.15)),
          ),
        ),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                isDark ? const Color(0xFF1E293B) : Colors.white,
                isDark ? const Color(0xFF0F172A).withOpacity(0.8) : Colors.white.withOpacity(0.9),
              ],
            ),
            border: Border.all(color: const Color(0xFF00C2FF).withOpacity(0.3)),
          ),
          child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF00C2FF), size: 32),
        ),
      ],
    );
  }

  Widget _buildExploreButton() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => SwappingAvailable()),
          (route) => false,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        ),
        child: Text('explore_now'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Widget _buildSuggestedMentorsSection(List<SwapListing> displayMentors) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('suggested_mentors'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => setState(() => _showAllMentors = !_showAllMentors),
                child: Text(_showAllMentors ? 'Show Less' : 'See All', style: const TextStyle(color: Color(0xFF00C2FF), fontSize: 13, fontWeight: FontWeight.w500)),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
      ],
    );
  }

  Widget _buildConversationsList(List<Map<String, dynamic>> conversations) {
    final currentUid = _auth.currentUser?.uid ?? '';
    final filtered = conversations.where((c) {
      final lastMsg = (c['lastMessage'] as String?) ?? '';
      return lastMsg.trim().isNotEmpty;
    }).toList();

    if (filtered.isEmpty) return _buildEmptyState();

    return Column(
      children: [
        _buildHeader(showSearch: true),
        const SizedBox(height: 14),
        _buildRecentMentorsRow(filtered, currentUid),
        Expanded(
          child: ListView.builder(
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
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMentorsRow(List<Map<String, dynamic>> conversations, String currentUid) {
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
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 12),
          child: Text('recent_mentors'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold)),
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

  Future<void> _markAllAsRead() async {
    try {
      await _chatRepo.markAllConversationsAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('all_messages_read'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${'error_marking_read'.tr()}: $e")),
        );
      }
    }
  }

  Future<void> _clearAllChats() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Clear all chats?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to clear all chat conversations? This action cannot be undone.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('cancel'.tr(),
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('clear_all'.tr(),
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _chatRepo.clearAllConversations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('all_chats_cleared'.tr())),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${'error_clearing_chats'.tr()}: $e")),
          );
        }
      }
    }
  }

  Widget _buildHeader({required bool showSearch}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUid = _auth.currentUser?.uid ?? '';

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
                  gradient: LinearGradient(colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('messages'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              if (currentUid.isNotEmpty)
                _ThreeDotMenu(
                  currentUid: currentUid,
                  onMarkAllAsRead: _markAllAsRead,
                  onClearAllChats: _clearAllChats,
                ),
            ],
          ),
          if (showSearch) ...[
            const SizedBox(height: 14),
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF00C2FF).withOpacity(0.15)),
                boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onMessageChanged,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText:'search_conversations'.tr(),
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 13),
                  suffixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThreeDotMenu extends StatelessWidget {
  final String currentUid;
  final VoidCallback onMarkAllAsRead;
  final VoidCallback onClearAllChats;

  const _ThreeDotMenu({
    required this.currentUid,
    required this.onMarkAllAsRead,
    required this.onClearAllChats,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .collection('settings')
          .doc('notifications')
          .snapshots(),
      builder: (context, snapshot) {
        bool isMuted = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          isMuted = data?['chatNotificationsMuted'] ?? false;
        }

        return PopupMenuButton<String>(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 22),
          onSelected: (val) async {
            if (val == 'mute') {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUid)
                  .collection('settings')
                  .doc('notifications')
                  .set({
                'chatNotificationsMuted': !isMuted,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            } else if (val == 'mark') {
              onMarkAllAsRead();
            } else if (val == 'clear') {
              onClearAllChats();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'mute',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('mute_notifications'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
                  Switch(
                    value: isMuted,
                    onChanged: (v) async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUid)
                          .collection('settings')
                          .doc('notifications')
                          .set({
                        'chatNotificationsMuted': v,
                        'updatedAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                      Navigator.of(context).pop();
                    },
                    activeTrackColor: const Color(0xFF00C2FF),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'mark',
              child: Text('mark_all_read'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'clear',
              child: Text('clear_all_chats'.tr(), style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 13)),
            ),
          ],
        );
      },
    );
  }
}

class _SuggestedMentorTile extends StatelessWidget {
  final SwapListing swap;
  final VoidCallback onTap;
  const _SuggestedMentorTile({required this.swap, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00C2FF).withOpacity(0.1)),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            _AvatarCircle(name: swap.name, initials: swap.initials, imageUrl: swap.imageUrl, isOnline: false, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(swap.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(swap.offering, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7), fontSize: 12)),
              ]),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3), size: 14),
          ],
        ),
      ),
    );
  }
}

class _RecentMentorAvatar extends StatelessWidget {
  final String otherUserId;
  final Function(ChatUserProfile) onTap;
  const _RecentMentorAvatar({required this.otherUserId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatUserProfile>(
      initialData: ChatUserService().getCachedProfile(otherUserId),
      stream: ChatUserService().getUserProfile(otherUserId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => onTap(profile),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: Column(children: [
              _AvatarCircle(name: profile.name, initials: profile.initials, imageUrl: profile.imageUrl, isOnline: profile.isOnline, size: 58),
              const SizedBox(height: 6),
              SizedBox(width: 60, child: Text(profile.name.split(' ').first, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8), fontSize: 11))),
            ]),
          ),
        );
      },
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String name;
  final String initials;
  final String? imageUrl;
  final bool isOnline;
  final double size;
  const _AvatarCircle({required this.name, required this.initials, this.imageUrl, required this.isOnline, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2E3E5C) : Colors.grey[200],
            shape: BoxShape.circle,
            border: Border.all(color: isOnline ? const Color(0xFF22C55E) : const Color(0xFF00C2FF).withOpacity(0.2), width: isOnline ? 2 : 1.5),
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(imageUrl!, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildInitials(), loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : _buildInitials())
                : _buildInitials(),
          ),
        ),
        if (isOnline)
          Positioned(bottom: 1, right: 1, child: Container(width: size * 0.24, height: size * 0.24, decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5)))),
      ],
    );
  }

  Widget _buildInitials() {
    return Center(child: Text(initials, style: TextStyle(color: const Color(0xFF00C2FF), fontWeight: FontWeight.bold, fontSize: size * 0.35)));
  }
}

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String currentUid;
  final String otherUserId;
  final String searchQuery;
  final Function(ChatUserProfile) onTap;
  const _ConversationTile({required this.data, required this.currentUid, required this.otherUserId, required this.searchQuery, required this.onTap});

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    return "${dt.day}/${dt.month}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lastMsg = data['lastMessage'] as String? ?? '';
    final rawUnread = data['unreadCount'];
    final unread = rawUnread is Map ? (rawUnread[currentUid] ?? 0) : 0;
    final Timestamp? ts = data['lastMessageAt'] as Timestamp?;
    final timeStr = ts != null ? _formatTime(ts.toDate()) : '';

    return StreamBuilder<ChatUserProfile>(
      initialData: ChatUserService().getCachedProfile(otherUserId),
      stream: ChatUserService().getUserProfile(otherUserId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile == null) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF00C2FF).withOpacity(0.05))),
            child: Row(children: [CircleAvatar(backgroundColor: Colors.grey[300], radius: 26), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 12, width: 100, color: Colors.grey[200]), const SizedBox(height: 8), Container(height: 10, width: 150, color: Colors.grey[100])]))]),
          );
        }

        if (searchQuery.isNotEmpty && !profile.name.toLowerCase().contains(searchQuery.toLowerCase())) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => onTap(profile),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00C2FF).withOpacity(0.05)),
              boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                _AvatarCircle(name: profile.name, initials: profile.initials, imageUrl: profile.imageUrl, isOnline: profile.isOnline, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(profile.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 6),
                      Text(profile.isOnline ? 'Online' : profile.relativeLastSeen, style: TextStyle(color: profile.isOnline ? const Color(0xFF22C55E) : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w500)),
                    ]),
                    const SizedBox(height: 5),
                    Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.9), fontSize: 13)),
                  ]),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(timeStr, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 11)),
                  const SizedBox(height: 6),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFF00C2FF).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 1))]),
                      child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}

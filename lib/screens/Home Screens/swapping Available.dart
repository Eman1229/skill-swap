import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/screens/Add%20skill/offer%20skill.dart';
import 'package:skill_swap/screens/Home%20Screens/see%20all.dart';
import 'package:skill_swap/screens/AI/ai_recommendation_center_screen.dart';
import 'package:skill_swap/screens/Chat/chat_screen.dart';
import 'package:skill_swap/screens/Profile/edit_profile_screen.dart';
import 'package:skill_swap/screens/Profile/my_profile_screen.dart';
import 'package:skill_swap/screens/Profile/profile%20screen.dart';
import 'package:skill_swap/screens/Swap/my_swaps_screen.dart';
import 'package:skill_swap/screens/Notifications/notifications_screen.dart';
import 'package:skill_swap/screens/Setting/settings_screen.dart';
import 'package:skill_swap/services/notification_repository.dart';
import 'package:skill_swap/models/session_model.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────
// ANIMATED GRADIENT BORDER WIDGET
// ─────────────────────────────────────────────────────────────────────
class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  const AnimatedGradientBorder({super.key, required this.child});

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: SweepGradient(
              transform: GradientRotation(_controller.value * 6.2832),
              colors: const [
                Color(0xFF3B82F6),  // blue
                Color(0xFF6A5CFF),  // medium purple
                Color(0xFF4B0082),  // deep purple
                Color(0xFF6A5CFF),  // medium purple
                Color(0xFF3B82F6),  // blue
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.7),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SWAP LISTING MODEL
// ─────────────────────────────────────────────────────────────────────
class SwapListing {
  final String id;
  final String name;
  final String initials;
  final Color avatarColor;
  final String offering;
  final String wanting;
  final double rating;
  final int reviews;
  final String category;
  final bool isLive;
  final String skillLevel;
  final String? userId;
  final String portfolioFile;
  final String description;
  final String experience;
  final String? imageUrl;

  SwapListing({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.offering,
    required this.wanting,
    required this.rating,
    required this.reviews,
    required this.category,
    this.isLive = false,
    this.skillLevel = '',
    this.userId,
    this.portfolioFile = '',
    this.description = '',
    this.experience = '',
    this.imageUrl,
  });

  factory SwapListing.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final String name = (d['name'] as String?) ?? 'Unknown';
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?');
    final Color color = d['avatarColor'] != null
        ? Color(d['avatarColor'] as int)
        : const Color(0xFF6B8AFF);

    return SwapListing(
      id: doc.id,
      name: name,
      initials: initials,
      avatarColor: color,
      offering: (d['offering'] as String?) ?? '',
      wanting: (d['wanting'] as String?) ?? '',
      rating: (d['Rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (d['Reviews'] as num?)?.toInt() ?? 0,
      category: (d['Category'] as String?) ?? 'All',
      isLive: (d['is Live'] as bool?) ?? false,
      skillLevel: (d['experienceLevel'] as String?) ?? '',
      userId: d['userId'] as String?,
      portfolioFile: (d['portfolio'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      experience: (d['experienceLevel'] as String?) ?? '',
      imageUrl: d['imageUrl'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────
class SwappingAvailable extends StatefulWidget {
  SwappingAvailable({Key? key}) : super(key: key);

  @override
  State<SwappingAvailable> createState() => _SwappingAvailableState();
}

class _SwappingAvailableState extends State<SwappingAvailable> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _selectedIndex = 0;
  int _selectedCategory = 0;
  String _userName = 'User';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _cachedImageUrl;
  List<SwapListing> _allSwaps = [];

  final List<String> _categories = [
    'All',
    'Design',
    'Coding',
    'Photos',
    'Data Analysis',
    'AI',
    'Music',
    'Drawing',
  ];

  late Stream<List<SwapListing>> _categoryStream;
  int _lastBuiltCategory = -1;

  Stream<List<SwapListing>> _buildCategoryStream(int categoryIndex) {
    Query query = _db.collection('swapListings');
    if (categoryIndex != 0) {
      query = query.where('Category', isEqualTo: _categories[categoryIndex]);
    }
    return query.snapshots().map(
          (snap) => snap.docs
          .map(SwapListing.fromDoc)
          .where((s) => s.userId != _auth.currentUser?.uid)
          .toList(),
    );
  }

  List<SwapListing> get _filteredSwaps {
    if (_searchQuery.isEmpty) return _allSwaps;
    final q = _searchQuery.trim().toLowerCase();
    return _allSwaps.where((swap) {
      return swap.name.toLowerCase().contains(q) ||
          swap.offering.toLowerCase().contains(q) ||
          swap.wanting.toLowerCase().contains(q) ||
          swap.category.toLowerCase().contains(q) ||
          swap.description.toLowerCase().contains(q);
    }).toList();
  }

  Stream<DocumentSnapshot?> get _myListingStream {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.empty();
    return _db
        .collection('swapListings')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty ? snap.docs.first : null);
  }

  Stream<List<SessionModel>> get _acceptedSessionsStream {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _db
        .collectionGroup('sessions')
        .where('participantIds', arrayContains: uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snap) {
      final sessions = snap.docs.map(SessionModel.fromDoc).toList();
      sessions.sort((a, b) => a.date.compareTo(b.date));
      return sessions;
    });
  }

  String get _initials {
    final parts = _userName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  void initState() {
    super.initState();
    _refreshCategoryStream();
  }

  void _refreshCategoryStream() {
    if (_lastBuiltCategory == _selectedCategory) return;
    _lastBuiltCategory = _selectedCategory;
    _categoryStream = _buildCategoryStream(_selectedCategory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _navigateToMyProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snap = await _db
        .collection('swapListings')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();

    if (!mounted) return;

    if (snap.docs.isNotEmpty) {
      final mySwap = SwapListing.fromDoc(snap.docs.first);
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditProfileScreen(swap: mySwap)),
      );
      if (result == true) setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No skill listing found for your profile.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  void _handleImageUrlChange(String? newUrl) {
    if (newUrl != null && newUrl != _cachedImageUrl) {
      if (_cachedImageUrl != null) {
        NetworkImage(_cachedImageUrl!).evict();
      }
      _cachedImageUrl = newUrl;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _buildBody(screenHeight),
        bottomNavigationBar: BottomAppBar(
          color: Theme.of(context).colorScheme.surface,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
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
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  selected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                const SizedBox(width: 48),
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
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                const Color(0xFF6B8AFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OfferSkillScreen()),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: const CircleBorder(),
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onSurface,
              size: 30,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // BODY
  // ─────────────────────────────────────────────────────────────────
  Widget _buildBody(double screenHeight) {
    switch (_selectedIndex) {
      case 1:
        return ChatScreen();
      case 2:
        return MySwapsScreen();
      case 3:
        return SettingsScreen();
      case 0:
      default:
        return SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────
              StreamBuilder<DocumentSnapshot?>(
                stream: _myListingStream,
                builder: (context, snapshot) {
                  String? liveImageUrl;
                  String liveInitials = _initials;

                  if (snapshot.hasData && snapshot.data != null) {
                    final data =
                    snapshot.data!.data() as Map<String, dynamic>?;
                    _userName = (data?['name'] as String?) ??
                        _auth.currentUser?.email?.split('@').first ??
                        'User';
                    liveImageUrl = data?['imageUrl'] as String?;
                    _handleImageUrlChange(liveImageUrl);

                    final name = (data?['name'] as String?) ?? _userName;
                    final parts = name.trim().split(' ');
                    liveInitials = parts.length >= 2
                        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                        : (parts[0].isNotEmpty
                        ? parts[0][0].toUpperCase()
                        : '?');
                  }

                  return _buildHeader(screenHeight, liveImageUrl, liveInitials);
                },
              ),

              // ── Swaps list ───────────────────────────────────────
              Expanded(
                child: StreamBuilder<List<SwapListing>>(
                  stream: _categoryStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    _allSwaps = snapshot.data ?? [];
                    final swaps = _filteredSwaps;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 22),
                          _buildSearchBar(),
                          const SizedBox(height: 20),
                          _buildCategoryChips(),
                          const SizedBox(height: 20),

                          // ✅ AI CARD WITH ANIMATED BORDER
                          _buildAIRecommendationCard(),
                          const SizedBox(height: 26),

                          if (swaps.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                _SectionTitle(title: 'Featured Swaps'),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SeeAllScreen(),
                                    ),
                                  ),
                                  child: Text(
                                    'See All',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 230,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: swaps.length,
                                separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
                                itemBuilder: (_, i) =>
                                    HorizontalSwapCard(swap: swaps[i]),
                              ),
                            ),
                            const SizedBox(height: 30),
                            _SectionTitle(title: 'Active Swap Sessions'),
                            const SizedBox(height: 14),
                            StreamBuilder<List<SessionModel>>(
                              stream: _acceptedSessionsStream,
                              builder: (context, sessionSnapshot) {
                                if (sessionSnapshot.hasError) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withAlpha(25),
                                      borderRadius:
                                      BorderRadius.circular(16),
                                      border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withAlpha(76)),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.info_outline_rounded,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Preparing sessions...',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Your sessions will appear here shortly once database indexing is complete. ${sessionSnapshot.error}',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontSize: 12),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                final sessions =
                                    sessionSnapshot.data ?? [];
                                if (sessionSnapshot.connectionState ==
                                    ConnectionState.waiting &&
                                    !sessionSnapshot.hasData) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  );
                                }
                                if (sessions.isEmpty) {
                                  return _buildEmptySessions();
                                }
                                return Column(
                                  children: sessions
                                      .map(
                                        (s) => Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 12),
                                      child: _LiveSessionCard(
                                          session: s),
                                    ),
                                  )
                                      .toList(),
                                );
                              },
                            ),
                          ] else ...[
                            const SizedBox(height: 40),
                            _buildEmptyHomeState(),
                          ],

                          const SizedBox(height: 100),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  AI RECOMMENDATION CARD — animated border + blue icon + blue link
  // ─────────────────────────────────────────────────────────────────
  Widget _buildAIRecommendationCard() {
    return AnimatedGradientBorder(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF101827),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                //  Solid blue robot icon
                const Icon(
                  Icons.smart_toy_rounded,
                  color: Color(0xFF2EA7FF),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI Smart Match',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                //  Dark pill accuracy badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '96% ACCURACY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'We analyzed your profile and found 3 perfect mentors for your current learning path.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            //  Solid blue link
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIRecommendationCenterScreen()),
                );
              },
              child: const Text(
                'View AI Recommendations →',
                style: TextStyle(
                  color: Color(0xFF2EA7FF),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // EMPTY HOME STATE
  // ─────────────────────────────────────────────────────────────────
  Widget _buildEmptyHomeState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No Swaps Available',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check Back Later Or Offer A Skill Yourself!',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.65),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(
      double screenHeight, String? imageUrl, String initials) {
    return Container(
      width: double.infinity,
      height: screenHeight * 0.16,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            const Color(0xFF6B8AFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MyProfileScreen()),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: imageUrl == null || imageUrl.isEmpty
                        ? Theme.of(context).colorScheme.surface
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 2,
                    ),
                  ),
                  child: imageUrl == null || imageUrl.isEmpty
                      ? Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color:
                        Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  )
                      : ClipOval(
                    child: Image.network(
                      imageUrl,
                      key: ValueKey(imageUrl),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                      cacheHeight: 300,
                      loadingBuilder:
                          (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_greeting, $_userName',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const Text(
                      'Keep growing every day!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationsScreen()),
              );
            },
            child: Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 22,
                  ),
                ),
                StreamBuilder<int>(
                  stream: NotificationRepository().unreadCountStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context)
                                .scaffoldBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // SEARCH BAR
  // ─────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) =>
            setState(() => _searchQuery = value.trim()),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search skills or topic...',
          hintStyle: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withOpacity(0.65),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.primary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.close,
              color:
              Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 14),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // CATEGORY CHIPS
  // ─────────────────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = _selectedCategory == index;
          return GestureDetector(
            onTap: () {
              if (_selectedCategory == index) return;
              setState(() {
                _selectedCategory = index;
                _refreshCategoryStream();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    const Color(0xFF6B8AFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: selected
                    ? null
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.25),
                ),
              ),
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: selected
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // EMPTY SESSIONS
  // ─────────────────────────────────────────────────────────────────
  Widget _buildEmptySessions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color:
          Theme.of(context).colorScheme.primary.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.15),
                  const Color(0xFF6B8AFF).withOpacity(0.15),
                ],
              ),
            ),
            child: const Icon(
              Icons.downloading_outlined,
              color: Color(0xFF6B8AFF),
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing Live Yet',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.65),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// HORIZONTAL SWAP CARD
// ─────────────────────────────────────────────────────────────────────
class HorizontalSwapCard extends StatelessWidget {
  final SwapListing swap;
  const HorizontalSwapCard({super.key, required this.swap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(swap: swap)),
        );
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withAlpha(38),
          ),
          boxShadow: [
            BoxShadow(
              color:
              Theme.of(context).colorScheme.primary.withAlpha(13),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: swap.imageUrl == null ? swap.avatarColor : null,
                shape: BoxShape.circle,
              ),
              child: swap.imageUrl != null
                  ? ClipOval(
                child: Image.network(
                  swap.imageUrl!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      swap.initials,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
                  : Center(
                child: Text(
                  swap.initials,
                  style: TextStyle(
                    color:
                    Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              swap.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.school_rounded,
                  size: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    swap.offering,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Looking For:',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.65),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              swap.wanting,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFBBF24),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  swap.rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${swap.reviews})',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.65),
                    fontSize: 11,
                  ),
                ),
                if (swap.isLive) ...[
                  const Spacer(),
                  _LiveBadge(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// LIVE SESSION CARD
// ─────────────────────────────────────────────────────────────────────
class _LiveSessionCard extends StatelessWidget {
  final SessionModel session;
  const _LiveSessionCard({required this.session});

  String _formatDateTime(BuildContext context) {
    return '${session.date.day}/${session.date.month}/${session.date.year} at ${TimeOfDay.fromDateTime(session.date).format(context)}';
  }

  Future<void> _openMeetingLink(BuildContext context) async {
    final meetingLink = session.meetingLink.trim();
    if (meetingLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No meeting link available.')));
      return;
    }
    final uri = Uri.tryParse(
      meetingLink.contains('://') ? meetingLink : 'https://$meetingLink',
    );
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid meeting link.')));
      return;
    }
    final launched =
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open meeting link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = session.title.trim().isNotEmpty
        ? session.title.trim()[0].toUpperCase()
        : 'S';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
          Theme.of(context).colorScheme.primary.withOpacity(0.25),
        ),
      ),
      child: InkWell(
        onTap: () => _openMeetingLink(context),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDateTime(context)} - ${session.meetingLink}',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _GradientButton(
                label: 'Join',
                onTap: () => _openMeetingLink(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// LIVE BADGE
// ─────────────────────────────────────────────────────────────────────
class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
        Theme.of(context).colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
          Theme.of(context).colorScheme.primary.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Live',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// GRADIENT BUTTON
// ─────────────────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            const Color(0xFF6B8AFF),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SECTION TITLE
// ─────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                const Color(0xFF6B8AFF),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// BOTTOM NAV ITEM
// ─────────────────────────────────────────────────────────────────────
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
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withOpacity(0.65),
            size: 24,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.65),
              fontSize: 10,
              fontWeight:
              selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
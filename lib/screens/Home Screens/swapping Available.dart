import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/screens/Add%20skill/offer%20skill.dart';
import 'package:skill_swap/screens/Home%20Screens/see%20all.dart';
import 'package:skill_swap/screens/Sign%20in/sign%20in.dart';
import 'package:skill_swap/screens/Chat/chat_screen.dart';
import 'package:skill_swap/screens/Profile/edit_profile_screen.dart';
import 'package:skill_swap/screens/Profile/profile%20screen.dart';
import 'package:skill_swap/screens/Swap/my_swaps_screen.dart';
import 'package:skill_swap/screens/Setting/settings_screen.dart';
import 'package:skill_swap/screens/Notifications/notifications_screen.dart';

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

  const SwapListing({
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

class SwappingAvailable extends StatefulWidget {
  const SwappingAvailable({Key? key}) : super(key: key);

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
  bool _isSearchVisible = false;

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

  Stream<DocumentSnapshot?> get _myListingStream {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('swapListings')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty ? snap.docs.first : null);
  }

  Stream<List<SwapListing>> get _swapsStream {
    Query query = _db.collection('swapListings');

    // Category filter
    if (_selectedCategory != 0) {
      query = query.where(
        'Category',
        isEqualTo: _categories[_selectedCategory],
      );
    }

    return query.snapshots().map((snap) {
      final allSwaps = snap.docs
          .map(SwapListing.fromDoc)
          .where((s) => s.userId != _auth.currentUser?.uid)
          .toList();

      // SEARCH FILTER
      if (_searchQuery.isEmpty) {
        return allSwaps;
      }

      return allSwaps.where((swap) {
        final query = _searchQuery.trim().toLowerCase();

        final name = swap.name.toLowerCase();
        final offering = swap.offering.toLowerCase();
        final wanting = swap.wanting.toLowerCase();
        final category = swap.category.toLowerCase();
        final description = swap.description.toLowerCase();

        return name.contains(query) ||
            offering.contains(query) ||
            wanting.contains(query) ||
            category.contains(query) ||
            description.contains(query);
      }).toList();
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

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
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

      if (result == true) {
        setState(() {});
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No skill listing found for your profile.'),
          backgroundColor: Color(0xFF00C2FF),
        ),
      );
    }
  }

  void _handleImageUrlChange(String? newUrl) {
    if (newUrl != null && newUrl != _cachedImageUrl) {
      // Evict only the previous (stale) URL
      if (_cachedImageUrl != null) {
        NetworkImage(_cachedImageUrl!).evict();
      }
      _cachedImageUrl = newUrl;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        backgroundColor: const Color(0xFF0F172A),
        body: _buildBody(screenHeight),
        bottomNavigationBar: BottomAppBar(
          color: const Color(0xFF1E293B),
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OfferSkillScreen()),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildBody(double screenHeight) {
    switch (_selectedIndex) {
      case 1:
        return const ChatScreen();
      case 2:
        return const MySwapsScreen();
      case 3:
        return const SettingsScreen();
      case 0:
      default:
        return SafeArea(
          child: Column(
            children: [
              StreamBuilder<DocumentSnapshot?>(
                stream: _myListingStream,
                builder: (context, snapshot) {
                  String? liveImageUrl;
                  String liveInitials = _initials;

                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    _userName =
                        (data?['name'] as String?) ??
                        _auth.currentUser?.email?.split('@').first ??
                        'User';
                    liveImageUrl = data?['imageUrl'] as String?;

                    // ✅ Evict only the stale old URL, keep the new one cached
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
              Expanded(
                child: StreamBuilder<List<SwapListing>>(
                  stream: _swapsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00C2FF),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    final swaps = snapshot.data ?? [];
                    final liveSessions = swaps.where((s) => s.isLive).toList();

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 22),

                          // SEARCH BAR
                          _buildSearchBar(),
                          const SizedBox(height: 20),

                          // CATEGORY CHIPS
                          _buildCategoryChips(),

                          const SizedBox(height: 26),

                          // FEATURED SWAPS
                          if (swaps.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const _SectionTitle(title: 'Featured Swaps'),

                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SeeAllScreen(),
                                    ),
                                  ),
                                  child: const Text(
                                    'See all',
                                    style: TextStyle(
                                      color: Color(0xFF00C2FF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: swaps.length > 3 ? 3 : swaps.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (_, i) => _SwapCard(swap: swaps[i]),
                            ),

                            const SizedBox(height: 30),

                            // ACTIVE SESSIONS
                            const _SectionTitle(title: 'Active Swap Sessions'),

                            const SizedBox(height: 14),

                            if (liveSessions.isNotEmpty)
                              ...liveSessions.map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _LiveSessionCard(swap: s),
                                ),
                              )
                            else
                              _buildEmptySessions(),
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

  Widget _buildEmptyHomeState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: Color(0xFF00C2FF),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No swaps available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later or offer a skill yourself!',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double screenHeight, String? imageUrl, String initials) {
    return Container(
      width: double.infinity,
      height: screenHeight * 0.16,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _navigateToMyProfile,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: imageUrl == null || imageUrl.isEmpty
                    ? const Color(0xFF1E293B)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: imageUrl == null || imageUrl.isEmpty
                  ? Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
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

                        // ✅ PREVENT CACHE ISSUE
                        cacheWidth: 300,
                        cacheHeight: 300,

                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },

                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_greeting, $_userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const Text(
                  'Keep growing every day!',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            child: Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0F172A),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF00C2FF).withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,

        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },

        style: const TextStyle(color: Colors.white, fontSize: 14),

        decoration: InputDecoration(
          hintText: 'Search skills or topic...',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),

          prefixIcon: const Icon(Icons.search, color: Color(0xFF00C2FF)),

          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,

          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
        ),
      ),
    );
  }

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
            onTap: () => setState(() => _selectedCategory = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: selected ? null : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : const Color(0xFF00C2FF).withOpacity(0.25),
                ),
              ),
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptySessions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF00C2FF).withOpacity(0.15)),
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
                  const Color(0xFF00C2FF).withOpacity(0.15),
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
          const Text(
            'Nothing live yet',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SWAP CARD
// ─────────────────────────────────────────────────────────────────────
class _SwapCard extends StatelessWidget {
  final SwapListing swap;
  const _SwapCard({required this.swap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C2FF).withAlpha(38)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C2FF).withAlpha(13),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen(swap: swap)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: swap.imageUrl == null ? swap.avatarColor : null,
                  shape: BoxShape.circle,
                ),
                child: swap.imageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          swap.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              swap.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          swap.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            swap.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFBBF24),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          swap.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${swap.reviews} Swaps)',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getCategoryIcon(swap.category),
                          color: Colors.white38,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          swap.category,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        if (swap.isLive) ...[
                          const SizedBox(width: 8),
                          _LiveBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      swap.offering,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12),
                        children: [
                          const TextSpan(
                            text: 'Looking for: ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: swap.wanting,
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'design':
        return Icons.brush_rounded;
      case 'coding':
        return Icons.code_rounded;
      case 'ai':
        return Icons.auto_awesome_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'drawing':
        return Icons.draw_rounded;
      case 'photos':
        return Icons.camera_alt_rounded;
      case 'data analysis':
        return Icons.analytics_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// LIVE SESSION CARD
// ─────────────────────────────────────────────────────────────────────
class _LiveSessionCard extends StatelessWidget {
  final SwapListing swap;
  const _LiveSessionCard({required this.swap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00C2FF).withOpacity(0.25)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen(swap: swap)),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: swap.avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    swap.initials,
                    style: const TextStyle(
                      color: Colors.white,
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
                      swap.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${swap.offering} ↔ ${swap.wanting}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _GradientButton(
                label: 'Join',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(swap: swap),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────
class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF00C2FF).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00C2FF).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF00C2FF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Live',
            style: TextStyle(
              color: Color(0xFF00C2FF),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
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
            gradient: const LinearGradient(
              colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
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
            color: selected ? const Color(0xFF00C2FF) : Colors.white38,
            size: 24,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF00C2FF) : Colors.white38,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

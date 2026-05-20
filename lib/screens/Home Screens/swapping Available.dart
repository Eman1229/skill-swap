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
        : Color(0xFF6B8AFF);

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

  // ── FIX: store the raw (unfiltered) list from Firestore here ──
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

  // ── FIX: single stable stream for the current category ──
  // Rebuilt only when the category actually changes.
  late Stream<List<SwapListing>> _categoryStream;
  int _lastBuiltCategory = -1; // sentinel so initState triggers a build

  Stream<List<SwapListing>> _buildCategoryStream(int categoryIndex) {
    Query query = _db.collection('swapListings');
    if (categoryIndex != 0) {
      query = query.where('Category', isEqualTo: _categories[categoryIndex]);
    }
    return query.snapshots().map((snap) => snap.docs
        .map(SwapListing.fromDoc)
        .where((s) => s.userId != _auth.currentUser?.uid)
        .toList());
  }

  // ── FIX: apply search + category filter purely in-memory ──
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
    _refreshCategoryStream(); // build stream for initial category (0)
  }

  /// Call this whenever _selectedCategory changes.
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
          content: Text('No skill listing found for your profile.'),
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
          shape: CircularNotchedRectangle(),
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
                SizedBox(width: 48),
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
              colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
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
            shape: CircleBorder(),
            child: Icon(Icons.add, color: Theme.of(context).colorScheme.onSurface, size: 30),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

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
              // ── Header (profile stream) ──────────────────────────────
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

              // ── Swaps list (stable stream) ───────────────────────────
              Expanded(
                child: StreamBuilder<List<SwapListing>>(
                  // FIX: use the stable cached stream; it never changes
                  // unless the category changes, so no flicker on search.
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
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      );
                    }

                    // FIX: cache the raw list; _filteredSwaps filters it
                    // reactively whenever _searchQuery or _allSwaps changes.
                    _allSwaps = snapshot.data ?? [];

                    final swaps = _filteredSwaps;
                    final liveSessions =
                    swaps.where((s) => s.isLive).toList();

                    return SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 22),

                          // SEARCH BAR
                          _buildSearchBar(),
                          SizedBox(height: 20),

                          // CATEGORY CHIPS
                          _buildCategoryChips(),

                          SizedBox(height: 26),

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
                                    'See all',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 14),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount:
                              swaps.length > 3 ? 3 : swaps.length,
                              separatorBuilder: (_, __) =>
                              SizedBox(height: 14),
                              itemBuilder: (_, i) =>
                                  _SwapCard(swap: swaps[i]),
                            ),
                            SizedBox(height: 30),
                            _SectionTitle(
                                title: 'Active Swap Sessions'),
                            SizedBox(height: 14),
                            if (liveSessions.isNotEmpty)
                              ...liveSessions.map(
                                    (s) => Padding(
                                  padding:
                                  EdgeInsets.only(bottom: 12),
                                  child: _LiveSessionCard(swap: s),
                                ),
                              )
                            else
                              _buildEmptySessions(),
                          ] else ...[
                            SizedBox(height: 40),
                            _buildEmptyHomeState(),
                          ],

                          SizedBox(height: 100),
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
          Icon(
            Icons.search_off_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No swaps available',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Check back later or offer a skill yourself!',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      double screenHeight, String? imageUrl, String initials) {
    return Container(
      width: double.infinity,
      height: screenHeight * 0.16,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    ? Theme.of(context).colorScheme.surface
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
              ),
              child: imageUrl == null || imageUrl.isEmpty
                  ? Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
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
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
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
                Text(
                  'Keep growing every day!',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NotificationsScreen()),
              );
            },
            child: Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
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
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border:
        Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,
        // FIX: setState updates _searchQuery → _filteredSwaps recomputes
        // inside the already-active StreamBuilder without touching the stream.
        onChanged: (value) => setState(() => _searchQuery = value.trim()),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search skills or topic...',
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 14),
          prefixIcon:
          Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon:
            Icon(Icons.close, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
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
        separatorBuilder: (_, __) => SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = _selectedCategory == index;
          return GestureDetector(
            onTap: () {
              if (_selectedCategory == index) return; // no-op if same
              setState(() {
                _selectedCategory = index;
                _refreshCategoryStream(); // rebuild stream for new category
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding:
              EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: selected ? null : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : Theme.of(context).colorScheme.primary.withOpacity(0.25),
                ),
              ),
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: selected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
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
      padding: EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
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
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  Color(0xFF6B8AFF).withOpacity(0.15),
                ],
              ),
            ),
            child: Icon(
              Icons.downloading_outlined,
              color: Color(0xFF6B8AFF),
              size: 26,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Nothing live yet',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 13),
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
  _SwapCard({required this.swap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(38)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(13),
            blurRadius: 16,
            offset: Offset(0, 6),
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
          padding: EdgeInsets.all(16),
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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            swap.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFBBF24),
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          swap.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '(${swap.reviews} Swaps)',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getCategoryIcon(swap.category),
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          swap.category,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
                            fontSize: 12,
                          ),
                        ),
                        if (swap.isLive) ...[
                          SizedBox(width: 8),
                          _LiveBadge(),
                        ],
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      swap.offering,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 12),
                        children: [
                          TextSpan(
                            text: 'Looking for: ',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: swap.wanting,
                            style:
                            TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
  _LiveSessionCard({required this.swap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border:
        Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
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
          padding:
          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      swap.name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${swap.offering} ↔ ${swap.wanting}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border:
        Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
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
          SizedBox(width: 4),
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

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding:
          EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
  _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 10),
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

  _NavItem({
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
            color:
            selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
            size: 24,
          ),
          SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color:
              selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
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
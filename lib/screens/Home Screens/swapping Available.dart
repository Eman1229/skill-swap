import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/screens/Home%20Screens/offer%20skill.dart';
import 'package:skill_swap/screens/Home%20Screens/see%20all.dart';
import 'package:skill_swap/screens/Sign%20in/sign%20in.dart';
import 'package:skill_swap/screens/Home%20Screens/Home%20Screen1.dart';

// ─────────────────────────────────────────────────────────────────────
// DATA MODEL — mirrors your Firestore document fields
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
  });

  /// Change field names here to match your actual Firestore schema.
  factory SwapListing.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final String name = (d['name'] as String?) ?? 'Unknown';
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : parts[0][0].toUpperCase();
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SWAPPING AVAILABLE SCREEN — shown when listings exist
// ─────────────────────────────────────────────────────────────────────
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

  // ── Firestore real-time stream filtered by selected category ────────
  Stream<List<SwapListing>> get _swapsStream {
    Query query = _db.collection('swapListings');
    if (_selectedCategory != 0) {
      query = query.where(
        'category',
        isEqualTo: _categories[_selectedCategory],
      );
    }
    return query.snapshots().map(
          (snap) => snap.docs.map(SwapListing.fromDoc).toList(),
    );
  }

  // ── Auth helpers ────────────────────────────────────────────────────
  String get _userName {
    final user = _auth.currentUser;
    if (user == null) return 'User';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return user.email?.split('@').first ?? 'User';
  }

  String get _initials {
    final parts = _userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
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

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP GRADIENT HEADER ─────────────────────────────────
            _buildHeader(screenHeight),

            // ── BODY — driven by Firestore stream ───────────────────
            Expanded(
              child: StreamBuilder<List<SwapListing>>(
                stream: _swapsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00C2FF),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Something went wrong.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }

                  final swaps = snapshot.data ?? [];
                  final liveSessions =
                  swaps.where((s) => s.isLive).toList();

                  // If all listings were deleted, go back to empty screen
                  if (swaps.isEmpty && mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OfferSkillScreen()),
                      );
                    });
                  }

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 22),
                        _buildSearchBar(),
                        const SizedBox(height: 20),
                        _buildCategoryChips(),
                        const SizedBox(height: 26),

                        // Featured Swaps header
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const _SectionTitle(
                                title: 'Featured Swaps'),
                            if (swaps.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SeeAllScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'See all',
                                  style: TextStyle(
                                    color: Color(0xFF00C2FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Listings list
                        if (swaps.isNotEmpty)
                          ListView.separated(
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            itemCount: swaps.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                            itemBuilder: (_, i) =>
                                _SwapCard(swap: swaps[i]),
                          )
                        else
                          _buildEmptyFeatured(),

                        const SizedBox(height: 30),

                        // Active Swap Sessions
                        const _SectionTitle(
                            title: 'Active Swap Sessions'),
                        const SizedBox(height: 14),

                        if (liveSessions.isNotEmpty)
                          ...liveSessions.map(
                                (s) => Padding(
                              padding:
                              const EdgeInsets.only(bottom: 12),
                              child: _LiveSessionCard(swap: s),
                            ),
                          )
                        else
                          _buildEmptySessions(),

                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── Gradient FAB ──────────────────────────────────────────────
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
            // TODO: navigate to Add Listing screen
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,

      // ── Bottom Nav Bar ────────────────────────────────────────────
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
    );
  }

  // ── Sub-builders ────────────────────────────────────────────────────

  Widget _buildHeader(double screenHeight) {
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.6), width: 2),
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
                  'Good $_greeting, $_userName',
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
                  style:
                  TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 22),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B3B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _signOut,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.white, size: 20),
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
        border: Border.all(
            color: const Color(0xFF00C2FF).withOpacity(0.2)),
      ),
      child: const TextField(
        style: TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search skills or topic...',
          hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
          suffixIcon: Icon(Icons.search, color: Color(0xFF00C2FF)),
          border: InputBorder.none,
          contentPadding:
          EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 8),
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

  Widget _buildEmptyFeatured() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
            color: const Color(0xFF00C2FF).withOpacity(0.15)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              color: Color(0xFF00C2FF), size: 40),
          SizedBox(height: 12),
          Text(
            'No results for this category',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
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
        border: Border.all(
            color: const Color(0xFF00C2FF).withOpacity(0.15)),
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
            child: const Icon(Icons.downloading_outlined,
                color: Color(0xFF6B8AFF), size: 26),
          ),
          const SizedBox(height: 12),
          const Text('Nothing live yet',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF00C2FF).withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C2FF).withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
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
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Live badge
                Row(
                  children: [
                    Expanded(
                      child: Text(swap.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (swap.isLive) _LiveBadge(),
                  ],
                ),
                const SizedBox(height: 8),

                // Skill badges
                Row(
                  children: [
                    _SkillBadge(
                        label: swap.offering,
                        icon: Icons.arrow_upward_rounded,
                        color: const Color(0xFF00C2FF)),
                    const SizedBox(width: 8),
                    const Icon(Icons.swap_horiz_rounded,
                        color: Colors.white38, size: 16),
                    const SizedBox(width: 8),
                    _SkillBadge(
                        label: swap.wanting,
                        icon: Icons.arrow_downward_rounded,
                        color: const Color(0xFF6B8AFF)),
                  ],
                ),
                const SizedBox(height: 10),

                // Rating + button
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFBBF24), size: 15),
                    const SizedBox(width: 4),
                    Text(swap.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Text('(${swap.reviews})',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                    const Spacer(),
                    _GradientButton(
                        label: 'Request Swap', onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        border: Border.all(
            color: const Color(0xFF00C2FF).withOpacity(0.25)),
      ),
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: swap.avatarColor, shape: BoxShape.circle),
            child: Center(
              child: Text(swap.initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
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
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text('${swap.offering} ↔ ${swap.wanting}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          _GradientButton(label: 'Join', onTap: () {}),
        ],
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
        border: Border.all(
            color: const Color(0xFF00C2FF).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Color(0xFF00C2FF), shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          const Text('Live',
              style: TextStyle(
                  color: Color(0xFF00C2FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SkillBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SkillBadge(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
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
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
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
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
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
            color:
            selected ? const Color(0xFF00C2FF) : Colors.white38,
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/models/swap_listing.dart';
import 'package:skill_swap/screens/Home Screens/profile screen.dart';

// ─────────────────────────────────────────────────────────────────────
// SEE ALL SCREEN
// ─────────────────────────────────────────────────────────────────────
class SeeAllScreen extends StatefulWidget {
  const SeeAllScreen({Key? key}) : super(key: key);

  @override
  State<SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends State<SeeAllScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  int _selectedCategory = 0;

  final List<String> _categories = [
    'All', 'Design', 'Coding', 'Photos',
    'Data Analysis', 'AI', 'Music', 'Drawing',
  ];

  Stream<List<SwapListing>> get _swapsStream {
    return _db.collection('swapListings').snapshots().map(
          (snap) => snap.docs.map(SwapListing.fromDoc).toList(),
    );
  }

  List<SwapListing> _applyFilters(List<SwapListing> all) {
    return all.where((s) {
      final matchCat = _selectedCategory == 0 ||
          s.category == _categories[_selectedCategory];
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.offering.toLowerCase().contains(q) ||
          s.wanting.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q);
      return matchCat && matchSearch;
    }).toList();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Top Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00C2FF).withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Search Bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF00C2FF).withOpacity(0.15),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    hintText: 'Search skills',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                    suffixIcon: Icon(Icons.search, color: Colors.white38, size: 20),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Category Chips ───────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
            ),

            const SizedBox(height: 16),

            // ── List ─────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<SwapListing>>(
                stream: _swapsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF00C2FF)),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white54)),
                    );
                  }

                  final all = snapshot.data ?? [];
                  final swaps = _applyFilters(all);

                  if (swaps.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              color: Color(0xFF00C2FF), size: 48),
                          const SizedBox(height: 14),
                          const Text('No swaps found',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(
                            'Try a different search or category',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    itemCount: swaps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _SwapListTile(swap: swaps[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── Bottom "Skill detail" bar ─────────────────────────────────
      bottomNavigationBar: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          border: Border(
            top: BorderSide(
                color: const Color(0xFF00C2FF).withOpacity(0.15)),
          ),
        ),
        child: Center(
          child: GestureDetector(
            onTap: () {
              // TODO: navigate to Skill Detail screen
            },
            child: const Text(
              'Skill detail',
              style: TextStyle(
                color: Color(0xFF00C2FF),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SWAP LIST TILE
// ─────────────────────────────────────────────────────────────────────
class _SwapListTile extends StatelessWidget {
  final SwapListing swap;
  const _SwapListTile({required this.swap});

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
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00C2FF).withOpacity(0.1),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Row 1: Avatar + Name + Category + Rating ──
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
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
                        fontSize: 16,
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
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _categoryIcon(swap.category),
                          const SizedBox(width: 4),
                          Text(
                            swap.category,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          if (swap.isLive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C2FF).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFF00C2FF).withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00C2FF),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Text('Live',
                                      style: TextStyle(
                                          color: Color(0xFF00C2FF),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFBBF24), size: 14),
                    const SizedBox(width: 3),
                    Text(
                      '${swap.rating.toStringAsFixed(1)}(${swap.reviews} Swaps)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              swap.offering,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Looking for: ',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  TextSpan(
                    text: swap.wanting,
                    style: const TextStyle(
                      color: Color(0xFF00C2FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryIcon(String category) {
    IconData icon;
    switch (category.toLowerCase()) {
      case 'design':
        icon = Icons.brush_rounded;
        break;
      case 'coding':
        icon = Icons.code_rounded;
        break;
      case 'ai':
        icon = Icons.auto_awesome_rounded;
        break;
      case 'music':
        icon = Icons.music_note_rounded;
        break;
      case 'drawing':
        icon = Icons.draw_rounded;
        break;
      case 'photos':
        icon = Icons.camera_alt_rounded;
        break;
      case 'data analysis':
        icon = Icons.bar_chart_rounded;
        break;
      default:
        icon = Icons.category_rounded;
    }
    return Icon(icon, color: Colors.white54, size: 13);
  }
}
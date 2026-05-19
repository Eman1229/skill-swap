import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/screens/Home Screens/swapping Available.dart';
import 'package:skill_swap/screens/Profile/profile%20screen.dart';

// ─────────────────────────────────────────────────────────────────────
// SEE ALL SCREEN
// ─────────────────────────────────────────────────────────────────────
class SeeAllScreen extends StatefulWidget {
  SeeAllScreen({Key? key}) : super(key: key);

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Top Bar ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(8, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // ── Search Bar ───────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search skills',
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 14),
                    suffixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), size: 20),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
              ),
            ),

            SizedBox(height: 14),

            // ── Category Chips ───────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final selected = _selectedCategory == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = index),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
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

            SizedBox(height: 16),

            // ── List ─────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<SwapListing>>(
                stream: _swapsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    );
                  }

                  final all = snapshot.data ?? [];
                  final swaps = _applyFilters(all);

                  if (swaps.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              color: Theme.of(context).colorScheme.primary, size: 48),
                          SizedBox(height: 14),
                          Text('No swaps found',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text(
                            'Try a different search or category',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 30),
                    itemCount: swaps.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
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
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
          ),
        ),
        child: Center(
          child: GestureDetector(
            onTap: () {
              // TODO: navigate to Skill Detail screen
            },
            child: Text(
              'Skill detail',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
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
  _SwapListTile({required this.swap});

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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
        ),
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Row 1: Avatar + Name + Category + Rating ──
            Row(
              children: [

                // ── UPDATED: show profile picture if available ──
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: swap.imageUrl == null || swap.imageUrl!.isEmpty
                        ? swap.avatarColor
                        : null,
                    shape: BoxShape.circle,
                  ),
                  child: swap.imageUrl != null && swap.imageUrl!.isNotEmpty
                      ? ClipOval(
                    child: Image.network(
                      swap.imageUrl!,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: swap.avatarColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        width: 46,
                        height: 46,
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
                              fontSize: 16,
                            ),
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
                // ── END UPDATED ──

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
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          _categoryIcon(context, swap.category),
                          SizedBox(width: 4),
                          Text(
                            swap.category,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          if (swap.isLive) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Text('Live',
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
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
                    Icon(Icons.star_rounded,
                        color: Color(0xFFFBBF24), size: 14),
                    SizedBox(width: 3),
                    Text(
                      '${swap.rating.toStringAsFixed(1)}(${swap.reviews} Swaps)',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 10),

            Text(
              swap.offering,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 4),

            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Looking for: ',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 12),
                  ),
                  TextSpan(
                    text: swap.wanting,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
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

  Widget _categoryIcon(BuildContext context, String category) {
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
    return Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 13);
  }
}

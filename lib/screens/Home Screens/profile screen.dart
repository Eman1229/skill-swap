import 'package:flutter/material.dart';
import 'package:skill_swap/models/swap_listing.dart';



// ─────────────────────────────────────────────────────────────────────
// PROFILE SCREEN
// ─────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  final SwapListing swap;

  const ProfileScreen({Key? key, required this.swap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // ── Scrollable Content ──────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Top gradient background ──
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                        ],
                      ),
                    ),
                  ),
                ),

                // ── Avatar overlapping gradient ──
                Transform.translate(
                  offset: const Offset(0, -60),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: swap.avatarColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0F172A),
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: swap.avatarColor.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              swap.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        swap.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFBBF24), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${swap.rating.toStringAsFixed(1)}(${swap.reviews} Swaps)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            _DetailRow(
                              label: 'Skill Title',
                              value: swap.offering,
                              isText: true,
                            ),
                            _Divider(),
                            _DetailRow(
                              label: 'Category',
                              value: swap.category,
                              isText: false,
                              icon: _categoryIcon(swap.category),
                            ),
                            _Divider(),
                            _DetailRow(
                              label: 'Skill Level',
                              value: swap.skillLevel,
                              isText: true,
                            ),
                            _Divider(),
                            _DetailRow(
                              label: 'No of swaps',
                              value: '${swap.reviews}',
                              isText: true,
                            ),
                            _Divider(),
                            _DetailRow(
                              label: 'Looking for',
                              value: swap.wanting,
                              isText: false,
                              isHighlight: true,
                            ),
                            _Divider(),
                            if (swap.portfolioFile.isNotEmpty) ...[
                              _DetailRow(
                                label: 'Portfolio',
                                value: swap.portfolioFile,
                                isText: false,
                                isLink: true,
                              ),
                              _Divider(),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              swap.description.isNotEmpty
                                  ? swap.description
                                  : 'No description provided.',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Experience',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              swap.experience.isNotEmpty
                                  ? swap.experience
                                  : 'No experience details provided.',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00C2FF),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'the skill available',
                              style: TextStyle(
                                color: Color(0xFF00C2FF),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Sticky Bottom Buttons ───────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF00C2FF).withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: navigate to chat screen
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFF00C2FF), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Message',
                        style: TextStyle(
                          color: Color(0xFF00C2FF),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                              Text('Swap request sent to ${swap.name}!'),
                              backgroundColor: const Color(0xFF00C2FF),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Request Swap',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'design': return Icons.brush_rounded;
      case 'coding': return Icons.code_rounded;
      case 'ai': return Icons.auto_awesome_rounded;
      case 'music': return Icons.music_note_rounded;
      case 'drawing': return Icons.draw_rounded;
      case 'photos': return Icons.camera_alt_rounded;
      case 'data analysis': return Icons.bar_chart_rounded;
      default: return Icons.category_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// DETAIL ROW WIDGET
// ─────────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isText;
  final IconData? icon;
  final bool isHighlight;
  final bool isLink;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isText = true,
    this.icon,
    this.isHighlight = false,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: isHighlight
                          ? const Color(0xFF00C2FF)
                          : isLink
                          ? const Color(0xFF6B8AFF)
                          : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration:
                      isLink ? TextDecoration.underline : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Colors.white.withOpacity(0.07),
      height: 1,
    );
  }
}
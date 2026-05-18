import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/screens/Swap/skill_detail_screen.dart';

class MyLearningScreen extends StatefulWidget {
  const MyLearningScreen({Key? key}) : super(key: key);

  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Learning',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: uid == null
          ? const Center(child: Text('Please login', style: TextStyle(color: Colors.white)))
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('swaps')
                        .where('learnerId', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF00C2FF)));
                      }

                      var docs = snapshot.data?.docs ?? [];
                      
                      // Filter logic
                      if (_selectedFilter != 'All') {
                        docs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['status']?.toString().toLowerCase() == _selectedFilter.toLowerCase();
                        }).toList();
                      }

                      if (docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      final swapsList = docs.map((doc) => SwapModel.fromDoc(doc)).toList();

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...swapsList.map((swap) {
                              return _LearningCard(swap: swap);
                            }).toList(),
                            const SizedBox(height: 32),
                            const Text('Performance Insights',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildInsights(swapsList, uid),
                            const SizedBox(height: 32),
                            const Text('Weekly Engagement',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildEngagementChart(swapsList),
                            const SizedBox(height: 40),
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

  Widget _buildFilters() {
    final filters = ['All', 'Ongoing', 'Completed', 'Upcoming'];
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == filters[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filters[index]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00C2FF) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No learning swaps found.', style: TextStyle(color: Colors.white54)),
    );
  }

  Widget _buildInsights(List<SwapModel> swaps, String uid) {
    // 1. XP / Skills Learned
    final completedSwaps = swaps.where((s) => s.status.toLowerCase() == 'completed').length;
    final totalCompletedSessions = swaps.fold<int>(0, (total, s) => total + s.completedSessions);
    
    // XP formula: 500 base + 1000 per completed swap + 100 per completed session
    final xp = 500 + (completedSwaps * 1000) + (totalCompletedSessions * 100);
    
    // 2. Total hours: completed sessions * 1.5
    final totalHours = (totalCompletedSessions * 1.5).toStringAsFixed(1);
    
    // 3. Average rating based on user listings
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('swapListings')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, listingsSnap) {
        double rating = 4.9;
        if (listingsSnap.hasData && listingsSnap.data!.docs.isNotEmpty) {
          double totalR = 0;
          int count = 0;
          for (final doc in listingsSnap.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final r = data['Rating'] as num?;
            if (r != null) {
              totalR += r.toDouble();
              count++;
            }
          }
          if (count > 0) {
            rating = totalR / count;
            if (rating == 0.0) {
              rating = 4.9;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('XP / Skills Learned: $completedSwaps',
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('$xp',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          const Text('+12% this week',
                              style: TextStyle(color: Color(0xFF00C2FF), fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C2FF).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: Color(0xFF00C2FF)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StatItem(
                      label: 'TOTAL HOURS',
                      value: totalHours,
                      icon: Icons.timer_outlined,
                      color: const Color(0xFF00C2FF)),
                  const Spacer(),
                  _StatItem(
                      label: 'RATING',
                      value: rating.toStringAsFixed(1),
                      icon: Icons.star_rounded,
                      color: Colors.pinkAccent),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEngagementChart(List<SwapModel> swaps) {
    // Count sessions or swaps per day of the week (1 = Monday, 7 = Sunday)
    final Map<int, int> dayCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    
    for (final s in swaps) {
      final date = s.lastSessionAt ?? s.createdAt;
      dayCounts[date.weekday] = (dayCounts[date.weekday] ?? 0) + 1 + s.completedSessions;
    }
    
    final maxCount = dayCounts.values.fold(0, (max, count) => count > max ? count : max);
    double getHeight(int day) {
      final count = dayCounts[day] ?? 0;
      if (maxCount == 0) return 20.0;
      return 20.0 + (count / maxCount) * 80.0;
    }

    final currentWeekday = DateTime.now().weekday;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Bar(height: getHeight(1), day: 'MON', active: currentWeekday == 1),
              _Bar(height: getHeight(2), day: 'TUE', active: currentWeekday == 2),
              _Bar(height: getHeight(3), day: 'WED', active: currentWeekday == 3),
              _Bar(height: getHeight(4), day: 'THU', active: currentWeekday == 4),
              _Bar(height: getHeight(5), day: 'FRI', active: currentWeekday == 5),
              _Bar(height: getHeight(6), day: 'SAT', active: currentWeekday == 6),
              _Bar(height: getHeight(7), day: 'SUN', active: currentWeekday == 7),
            ],
          ),
        ],
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  final SwapModel swap;
  const _LearningCard({required this.swap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('swapListings')
          .where('userId', isEqualTo: swap.mentorId)
          .limit(1)
          .snapshots(),
      builder: (context, mentorSnap) {
        String? imageUrl;
        if (mentorSnap.hasData && mentorSnap.data!.docs.isNotEmpty) {
          imageUrl = (mentorSnap.data!.docs.first.data() as Map<String, dynamic>)['imageUrl'] as String?;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00C2FF).withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.image, color: Colors.white24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(swap.skillName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(swap.mentorName, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C2FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(swap.status.toUpperCase(),
                        style: const TextStyle(color: Color(0xFF00C2FF), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Progress', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  Text('${(swap.progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: swap.progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  color: const Color(0xFF00C2FF),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Session ${swap.completedSessions} of ${swap.totalSessions}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SkillDetailScreen(swap: swap)),
                    ),
                    child: const Text('View Details >', style: TextStyle(color: Color(0xFF00C2FF), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final String day;
  final bool active;

  const _Bar({required this.height, required this.day, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF00C2FF) : const Color(0xFF334155),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

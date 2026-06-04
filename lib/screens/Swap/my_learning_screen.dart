import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/screens/Swap/skill_detail_screen.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';
import 'package:skill_swap/services/skill_exchange_service.dart';

class MyLearningScreen extends StatefulWidget {
  MyLearningScreen({Key? key}) : super(key: key);

  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SkillExchangeService _exchangeService = SkillExchangeService();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _exchangeService.rebalanceUser(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('my_learning'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: uid == null
          ? Center(child: Text('Please login', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)))
          : Column(
        children: [
          _buildFilters(),
          Expanded(
            child: StreamBuilder<List<SwapModel>>(
              stream: _exchangeService.watchLearningSwaps(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
                }

                var swapsList = snapshot.data ?? [];

                // Filter logic
                if (_selectedFilter != 'All') {
                  swapsList = swapsList.where((swap) {
                    return swap.status.toLowerCase() == _selectedFilter.toLowerCase();
                  }).toList();
                }

                if (swapsList.isEmpty) {
                  return _buildEmptyState();
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...swapsList.map((swap) {
                        return _LearningCard(swap: swap);
                      }).toList(),
                      SizedBox(height: 32),
                      Text('Performance Insights',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      _buildInsights(swapsList, uid),
                      SizedBox(height: 32),
                      Text('Weekly Engagement',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      _buildEngagementChart(swapsList),
                      SizedBox(height: 40),
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
      margin: EdgeInsets.symmetric(vertical: 16),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == filters[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filters[index]),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
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
    return Center(
      child: Text('No learning swaps found.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }

  Widget _buildInsights(List<SwapModel> swaps, String uid) {
    final completedSwaps = swaps.where((s) => s.status.toLowerCase() == 'completed').length;
    final totalCompletedSessions = swaps.fold<int>(0, (total, s) => total + s.completedSessions);
    final xp = 500 + (completedSwaps * 1000) + (totalCompletedSessions * 100);
    final totalHours = (totalCompletedSessions * 1.5).toStringAsFixed(1);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text('$xp',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Text('+12% this week',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.workspace_premium_rounded,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
          SizedBox(height: 20),
          Divider(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6)),
          SizedBox(height: 20),
          Row(
            children: [
              _StatItem(
                  label: 'TOTAL HOURS',
                  value: totalHours,
                  icon: Icons.timer_outlined,
                  color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementChart(List<SwapModel> swaps) {
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
  _LearningCard({required this.swap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(swap.mentorId)
          .snapshots(),
      builder: (context, mentorSnap) {
        String? imageUrl;
        String displayName = swap.mentorName;
        if (mentorSnap.hasData && mentorSnap.data!.exists) {
          final data = mentorSnap.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            imageUrl = data['imageUrl'] as String?;
            final name = data['name'] as String?;
            if (name != null && name.trim().isNotEmpty) {
              displayName = name;
            }
          }
        }

        final double calculatedProgress = swap.totalSessions > 0
            ? (swap.completedSessions / swap.totalSessions).clamp(0.0, 1.0)
            : 0.0;

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
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
                        errorBuilder: (_, __, ___) => Icon(Icons.image, color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                    )
                        : Icon(Icons.image, color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(swap.skillName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(displayName, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(swap.status.toUpperCase(),
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                  Text('${(calculatedProgress * 100).toInt()}%', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: calculatedProgress,
                  backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  color: Theme.of(context).colorScheme.primary,
                  minHeight: 6,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Session ${swap.completedSessions} of ${swap.totalSessions}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 12)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SkillDetailScreen(swap: swap)),
                    ),
                    child: Text('View Details >', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
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

  _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 10)),
            Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
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

  _Bar({required this.height, required this.day, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: active ? Theme.of(context).colorScheme.primary : Color(0xFF334155),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        SizedBox(height: 8),
        Text(day, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 10)),
      ],
    );
  }
}
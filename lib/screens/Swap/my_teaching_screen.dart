import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/screens/Swap/skill_detail_screen.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class MyTeachingScreen extends StatefulWidget {
  MyTeachingScreen({Key? key}) : super(key: key);

  @override
  State<MyTeachingScreen> createState() => _MyTeachingScreenState();
}

class _MyTeachingScreenState extends State<MyTeachingScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedFilter = 'All';

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
        title: Text('my_teaching'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: uid == null
          ? Center(child: Text('Please login', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)))
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('swaps')
                        .where('mentorId', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
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
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...swapsList.map((swap) {
                              return _TeachingCard(swap: swap);
                            }),
                            SizedBox(height: 32),
                            Text('Teaching Dashboard',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 16),
                            _buildTeachingStats(swapsList, uid),
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
                color: isSelected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.surface,
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
      child: Text('No teaching swaps found.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }

  Widget _buildTeachingStats(List<SwapModel> swaps, String uid) {
    // 1. Unique students
    final uniqueStudents = swaps.map((s) => s.learnerId).toSet().length;

    // 2. Hours: completed sessions * 1.5
    final totalSessions = swaps.fold<int>(0, (total, s) => total + s.completedSessions);
    final totalHours = (totalSessions * 1.5).toStringAsFixed(1);

    // 3. Rating: average rating of their swapListings
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('swapListings')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, listingsSnap) {
        double avgRating = 4.8;
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
            avgRating = totalR / count;
            if (avgRating == 0.0) {
              avgRating = 4.8;
            }
          }
        }

        return Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'STUDENTS',
                    value: '$uniqueStudents',
                    icon: Icons.people_alt_rounded,
                    color: Colors.blueAccent)),
            SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    label: 'HOURS',
                    value: totalHours,
                    icon: Icons.access_time_filled_rounded,
                    color: Colors.purpleAccent)),
            SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    label: 'RATING',
                    value: avgRating.toStringAsFixed(1),
                    icon: Icons.star_rounded,
                    color: Colors.orangeAccent)),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 12),
          Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 10, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _TeachingCard extends StatelessWidget {
  final SwapModel swap;
  _TeachingCard({required this.swap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('swapListings')
          .where('userId', isEqualTo: swap.learnerId)
          .limit(1)
          .snapshots(),
      builder: (context, learnerSnap) {
        String? imageUrl;
        if (learnerSnap.hasData && learnerSnap.data!.docs.isNotEmpty) {
          imageUrl = (learnerSnap.data!.docs.first.data() as Map<String, dynamic>)['imageUrl'] as String?;
        }

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)),
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
                      shape: BoxShape.circle,
                    ),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              imageUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.person, color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(swap.learnerName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(swap.skillName.toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 11, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(swap.status.toUpperCase(),
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress: ${(swap.progress * 100).toInt()}%', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                  Text('Session ${swap.completedSessions} of ${swap.totalSessions}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 12)),
                ],
              ),
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: swap.progress,
                  backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  color: Theme.of(context).colorScheme.secondary,
                  minHeight: 6,
                ),
              ),
              SizedBox(height: 20),
              _PrimaryBtnSmall(
                label: 'View Details',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SkillDetailScreen(swap: swap)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrimaryBtnSmall extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  _PrimaryBtnSmall({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

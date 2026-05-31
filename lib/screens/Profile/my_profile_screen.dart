import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap/screens/Home%20Screens/swapping%20Available.dart';
import 'package:skill_swap/screens/Profile/edit_profile_screen.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const _StateMessage(
        icon: Icons.lock_outline_rounded,
        title: 'Profile unavailable',
        message: 'Sign in again to view your profile.',
      );
    }

    return StreamBuilder<_ProfileData>(
      stream: _ProfileDataService().watch(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LoadingProfile();
        }
        if (snapshot.hasError) {
          return _StateMessage(
            icon: Icons.error_outline_rounded,
            title: 'Could not load profile',
            message: snapshot.error.toString(),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const _StateMessage(
            icon: Icons.person_search_rounded,
            title: 'No profile data yet',
            message: 'Create a skill listing to start building your profile.',
          );
        }

        return _ProfileContent(data: data);
      },
    );
  }
}

class ProgressAchievementsScreen extends StatelessWidget {
  const ProgressAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Progress & Achievements',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          bottom: TabBar(
            dividerColor: Colors.transparent,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: 'Progress'),
              Tab(text: 'Badges'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProgressView(),
            _BadgesView(),
          ],
        ),
      ),
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<_ProfileData>(
      stream: _ProfileDataService().watch(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LoadingProfile();
        }
        if (snapshot.hasError) return _StateMessage(icon: Icons.error, title: 'Error', message: snapshot.error.toString());
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProgressHero(data: data),
              const SizedBox(height: 16),
              _MetricGrid(
                items: [
                  _MetricItem('XP Points', '${data.xp}', Icons.bolt_rounded),
                  _MetricItem('Current Level', 'Level ${data.level}', Icons.military_tech_rounded),
                  _MetricItem('Skills Learned', '${data.skillsLearnedCount}', Icons.school_rounded),
                  _MetricItem('Skills Teaching', '${data.skillsTeachingCount}', Icons.record_voice_over_rounded),
                  _MetricItem('Completed Swaps', '${data.completedSwaps}', Icons.swap_horiz_rounded),
                  _MetricItem('Success Rate', '${data.successRate.round()}%', Icons.verified_rounded),
                ],
              ),
              const SizedBox(height: 18),
              const _SectionHeader(title: 'Weekly Activity'),
              const SizedBox(height: 10),
              _ActivityGraph(values: data.weeklyActivity, compactLabels: true),
              const SizedBox(height: 18),
              const _SectionHeader(title: 'Monthly Activity'),
              const SizedBox(height: 10),
              _ActivityGraph(values: data.monthlyActivity, compactLabels: false),
              const SizedBox(height: 18),
              const _SectionHeader(title: 'Skill Growth'),
              const SizedBox(height: 10),
              _SkillGrowthList(progress: data.skillGrowth),
            ],
          ),
        );
      },
    );
  }
}

class _BadgesView extends StatefulWidget {
  const _BadgesView();

  @override
  State<_BadgesView> createState() => _BadgesViewState();
}

class _BadgesViewState extends State<_BadgesView> {
  final Set<String> _syncing = {};

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<_ProfileData>(
      stream: _ProfileDataService().watch(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return _LoadingProfile();
        if (snapshot.hasError) return _StateMessage(icon: Icons.error, title: 'Error', message: snapshot.error.toString());
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();

        final badges = _BadgeCatalog.evaluate(data);
        final unlocked = badges.where((badge) => badge.unlocked).toList();
        final locked = badges.where((badge) => !badge.unlocked).toList();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncBadgeNotifications(uid, data, unlocked);
        });
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BadgesSummary(unlocked: unlocked.length, total: badges.length),
              const SizedBox(height: 18),
              const _SectionHeader(title: 'Unlocked Badges'),
              const SizedBox(height: 10),
              if (unlocked.isEmpty)
                const _EmptyCard(message: 'Your unlocked badges will appear here.')
              else
                ...unlocked.map((badge) => _BadgeTile(badge: badge)),
              const SizedBox(height: 18),
              const _SectionHeader(title: 'Locked Badges'),
              const SizedBox(height: 10),
              ...locked.map((badge) => _BadgeTile(badge: badge)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _syncBadgeNotifications(String uid, _ProfileData data, List<_BadgeStatus> unlocked) async {
    final db = FirebaseFirestore.instance;
    for (final badge in unlocked) {
      if (_syncing.contains(badge.id)) continue;
      _syncing.add(badge.id);
      try {
        final existing = await db
            .collection('notifications')
            .where('receiverId', isEqualTo: uid)
            .where('type', isEqualTo: 'system')
            .where('data.badgeId', isEqualTo: badge.id)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) continue;

        await db.collection('notifications').add({
          'senderId': 'system',
          'senderName': 'SkillSwapX',
          'senderProfilePic': '',
          'receiverId': uid,
          'type': 'system',
          'title': 'Badge unlocked',
          'body': 'You unlocked ${badge.title}.',
          'data': {
            'badgeId': badge.id,
            'badgeTitle': badge.title,
          },
          'isRead': false,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'actionRoute': '/badges',
          'actionId': badge.id,
          'imageUrl': data.imageUrl ?? '',
        });
      } catch (e) {
        debugPrint("Error syncing badge notifications: $e");
      } finally {
        _syncing.remove(badge.id);
      }
    }
  }
}

class _ProfileContent extends StatelessWidget {
  final _ProfileData data;

  const _ProfileContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        child: Column(
          children: [
            _ProfileHeader(data: data),
            const SizedBox(height: 16),
            _MetricGrid(
              items: [
                _MetricItem('Rating', data.rating.toStringAsFixed(1), Icons.star_rounded),
                _MetricItem('Total Swaps', '${data.totalSwaps}', Icons.swap_horiz_rounded),
                _MetricItem('Skills Learned', '${data.skillsLearnedCount}', Icons.school_rounded),
                _MetricItem('Skills Teaching', '${data.skillsTeachingCount}', Icons.record_voice_over_rounded),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Edit Profile',
                    icon: Icons.edit_rounded,
                    compact: true,
                    onTap: () => _openEditProfile(context, data),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'Progress & Badge',
                    icon: Icons.workspace_premium_rounded,
                    compact: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProgressAchievementsScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _SectionHeader(title: 'Skills Teaching'),
            const SizedBox(height: 10),
            _SkillChips(skills: data.skillsTeaching),
            const SizedBox(height: 18),
            const _SectionHeader(title: 'Skills Learned'),
            const SizedBox(height: 10),
            _SkillChips(skills: data.skillsLearned),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final _ProfileData data;

  const _ProfileHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openEditProfile(context, data),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: _cardDecoration(context),
        child: Column(
          children: [
            _ProfilePhoto(data: data, size: 94),
            const SizedBox(height: 12),
            Text(
              data.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              data.username,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _LevelPill(level: data.level),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RatingPill(rating: data.rating),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ThinProgress(value: data.levelProgress, height: 7),
          ],
        ),
      ),
    );
  }
}

class _ProgressHero extends StatelessWidget {
  final _ProfileData data;

  const _ProgressHero({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ProfilePhoto(data: data, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${data.level} Skill Sharer',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.xp} XP Points',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ThinProgress(value: data.levelProgress, height: 9),
          const SizedBox(height: 8),
          Text(
            '${(data.levelProgress * 100).round()}% to next level',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.68),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  final _ProfileData data;
  final double size;

  const _ProfilePhoto({required this.data, required this.size});

  @override
  Widget build(BuildContext context) {
    final imageUrl = data.imageUrl;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.6),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                key: ValueKey(imageUrl),
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _Initials(data: data),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _Initials(data: data);
                },
              )
            : _Initials(data: data),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final _ProfileData data;

  const _Initials({required this.data});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        data.initials,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricItem> items;

  const _MetricGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.45,
      ),
      itemBuilder: (context, index) => _MetricCard(item: items[index]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricItem item;

  const _MetricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: Theme.of(context).colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.68),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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

class _ActivityGraph extends StatelessWidget {
  final Map<String, int> values;
  final bool compactLabels;

  const _ActivityGraph({required this.values, required this.compactLabels});

  @override
  Widget build(BuildContext context) {
    final maxValue = values.values.fold<int>(0, math.max);
    return Container(
      height: compactLabels ? 150 : 170,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: _cardDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.entries.map((entry) {
          final ratio = maxValue == 0 ? 0.04 : (entry.value / maxValue).clamp(0.06, 1.0).toDouble();
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return FractionallySizedBox(
                            heightFactor: value,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    const Color(0xFF6B8AFF),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.68),
                      fontSize: compactLabels ? 10 : 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SkillGrowthList extends StatelessWidget {
  final Map<String, double> progress;

  const _SkillGrowthList({required this.progress});

  @override
  Widget build(BuildContext context) {
    if (progress.isEmpty) {
      return const _EmptyCard(message: 'Skill progress appears when swaps begin.');
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        children: progress.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${(entry.value * 100).round()}%',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ThinProgress(value: entry.value, height: 8),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final _BadgeStatus badge;

  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: badge.unlocked ? 1 : 0.52,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(context),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: badge.unlocked
                    ? const LinearGradient(
                        colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: badge.unlocked ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                badge.unlocked ? badge.icon : Icons.lock_rounded,
                color: badge.unlocked
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    badge.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.68),
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 9),
                  _ThinProgress(value: badge.progress, height: 6),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 58,
              child: Text(
                badge.unlocked && badge.unlockDate != null ? _shortDate(badge.unlockDate!) : '${(badge.progress * 100).round()}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: badge.unlocked
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.68),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgesSummary extends StatelessWidget {
  final int unlocked;
  final int total;

  const _BadgesSummary({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : unlocked / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$unlocked of $total Badges Unlocked',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _ThinProgress(value: progress, height: 9),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 46 : 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, const Color(0xFF6B8AFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: compact ? 17 : 19),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: compact ? 12 : 14, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _SkillChips extends StatelessWidget {
  final List<String> skills;

  const _SkillChips({required this.skills});

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return const _EmptyCard(message: 'No skills available yet.');
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(context),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skills.map((skill) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.28)),
            ),
            child: Text(
              skill,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).colorScheme.primary, const Color(0xFF6B8AFF)],
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
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ThinProgress extends StatelessWidget {
  final double value;
  final double height;

  const _ThinProgress({required this.value, required this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: value.clamp(0.0, 1.0).toDouble()),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, child) {
          return LinearProgressIndicator(
            minHeight: height,
            value: animatedValue,
            backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          );
        },
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  final int level;

  const _LevelPill({required this.level});

  @override
  Widget build(BuildContext context) {
    return _Pill(icon: Icons.military_tech_rounded, label: 'Level $level');
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;

  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    return _Pill(icon: Icons.star_rounded, label: rating.toStringAsFixed(1));
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.68),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LoadingProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 54),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.68),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;

  const _MetricItem(this.label, this.value, this.icon);
}

class _ProfileData {
  final String uid;
  final String name;
  final String username;
  final String initials;
  final String? imageUrl;
  final double rating;
  final int totalSwaps;
  final int completedSwaps;
  final int xp;
  final int level;
  final double levelProgress;
  final double successRate;
  final List<String> skillsLearned;
  final List<String> skillsTeaching;
  final Map<String, int> weeklyActivity;
  final Map<String, int> monthlyActivity;
  final Map<String, double> skillGrowth;
  final DateTime? firstActivityAt;
  final DateTime? firstCompletedSwapAt;

  const _ProfileData({
    required this.uid,
    required this.name,
    required this.username,
    required this.initials,
    required this.imageUrl,
    required this.rating,
    required this.totalSwaps,
    required this.completedSwaps,
    required this.xp,
    required this.level,
    required this.levelProgress,
    required this.successRate,
    required this.skillsLearned,
    required this.skillsTeaching,
    required this.weeklyActivity,
    required this.monthlyActivity,
    required this.skillGrowth,
    required this.firstActivityAt,
    required this.firstCompletedSwapAt,
  });

  int get skillsLearnedCount => skillsLearned.length;
  int get skillsTeachingCount => skillsTeaching.length;
}

class _ProfileDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<_ProfileData> watch(String uid) {
    late StreamController<_ProfileData> controller;
    final subscriptions = <StreamSubscription>[];
    DocumentSnapshot<Map<String, dynamic>>? userDoc;
    QuerySnapshot<Map<String, dynamic>>? listingsSnap;
    QuerySnapshot<Map<String, dynamic>>? swapsSnap;
    QuerySnapshot<Map<String, dynamic>>? requestsSnap;

    void emit() {
      if (listingsSnap == null || swapsSnap == null || requestsSnap == null || controller.isClosed) return;
      controller.add(_buildProfileData(uid, userDoc, listingsSnap!, swapsSnap!, requestsSnap!));
    }

    controller = StreamController<_ProfileData>.broadcast(
      onListen: () {
        subscriptions.add(_db.collection('users').doc(uid).snapshots().listen((snap) {
          userDoc = snap;
          emit();
        }, onError: controller.addError));
        subscriptions.add(_db
            .collection('swapListings')
            .where('userId', isEqualTo: uid)
            .snapshots()
            .listen((snap) {
          listingsSnap = snap;
          emit();
        }, onError: controller.addError));
        subscriptions.add(_db
            .collection('swaps')
            .where('participants', arrayContains: uid)
            .snapshots()
            .listen((snap) {
          swapsSnap = snap;
          emit();
        }, onError: controller.addError));
        subscriptions.add(_db
            .collection('swap_requests')
            .where('participants', arrayContains: uid)
            .snapshots()
            .listen((snap) {
          requestsSnap = snap;
          emit();
        }, onError: controller.addError));
      },
      onCancel: () async {
        for (final sub in subscriptions) {
          await sub.cancel();
        }
      },
    );

    return controller.stream;
  }

  _ProfileData _buildProfileData(
    String uid,
    DocumentSnapshot<Map<String, dynamic>>? userDoc,
    QuerySnapshot<Map<String, dynamic>> listingsSnap,
    QuerySnapshot<Map<String, dynamic>> swapsSnap,
    QuerySnapshot<Map<String, dynamic>> requestsSnap,
  ) {
    final user = _auth.currentUser;
    final userData = userDoc?.data() ?? {};
    final listingMaps = listingsSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    final swapMaps = swapsSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    final requestMaps = requestsSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

    String name = _stringValue(userData['name']);
    if (name.isEmpty && listingMaps.isNotEmpty) name = _stringValue(listingMaps.first['name']);
    if (name.isEmpty) name = user?.displayName ?? user?.email?.split('@').first ?? 'User';

    String? imageUrl = _nullableString(userData['imageUrl']);
    if ((imageUrl == null || imageUrl.isEmpty) && listingMaps.isNotEmpty) {
      imageUrl = _nullableString(listingMaps.first['imageUrl']);
    }
    imageUrl ??= user?.photoURL;

    final username = _username(userData, user);
    final teachingSet = <String>{};
    final learnedSet = <String>{};
    final progressBySkill = <String, List<double>>{};
    final activityDates = <DateTime>[];

    for (final listing in listingMaps) {
      final offering = _stringValue(listing['offering']);
      if (offering.isNotEmpty) {
        teachingSet.add(offering);
        progressBySkill.putIfAbsent(offering, () => []).add(0.35);
      }
      final wanting = _stringValue(listing['wanting']);
      if (wanting.isNotEmpty) learnedSet.add(wanting);
      final createdAt = _dateValue(listing['createdAt']);
      if (createdAt != null) activityDates.add(createdAt);
    }

    int completedSwaps = 0;
    for (final swap in swapMaps) {
      final skill = _stringValue(swap['skillName']);
      final progress = _numValue(swap['progress']).clamp(0.0, 1.0).toDouble();
      final status = _stringValue(swap['status']).toLowerCase();
      if (swap['mentorId'] == uid && skill.isNotEmpty) teachingSet.add(skill);
      if (swap['learnerId'] == uid && skill.isNotEmpty) learnedSet.add(skill);
      if (skill.isNotEmpty) progressBySkill.putIfAbsent(skill, () => []).add(progress);
      if (status == 'completed' || progress >= 1.0) completedSwaps++;

      final lastSessionAt = _dateValue(swap['lastSessionAt']);
      final createdAt = _dateValue(swap['createdAt']);
      if (lastSessionAt != null) activityDates.add(lastSessionAt);
      if (createdAt != null) activityDates.add(createdAt);
    }

    int acceptedRequests = 0;
    int closedRequests = 0;
    for (final request in requestMaps) {
      final status = _stringValue(request['status']).toLowerCase();
      if (status == 'accepted' || status == 'completed') acceptedRequests++;
      if (status == 'accepted' || status == 'completed' || status == 'rejected' || status == 'cancelled') {
        closedRequests++;
      }
      if (request['senderId'] == uid) {
        final offered = _stringValue(request['offeredSkill']);
        final requested = _stringValue(request['requestedSkill']);
        if (offered.isNotEmpty) teachingSet.add(offered);
        if (requested.isNotEmpty) learnedSet.add(requested);
      }
      if (request['receiverId'] == uid) {
        final offered = _stringValue(request['offeredSkill']);
        final requested = _stringValue(request['requestedSkill']);
        if (offered.isNotEmpty) learnedSet.add(offered);
        if (requested.isNotEmpty) teachingSet.add(requested);
      }
      final createdAt = _dateValue(request['createdAt']);
      if (createdAt != null) activityDates.add(createdAt);
    }

    final ratings = listingMaps.map((listing) => _numValue(listing['Rating'])).where((rating) => rating > 0).toList();
    final rating = ratings.isEmpty ? 0.0 : ratings.reduce((a, b) => a + b) / ratings.length;
    final totalSessions = swapMaps.fold<int>(0, (acc, swap) => acc + _intValue(swap['completedSessions']));
    final totalSwaps = swapMaps.length;
    final xp = completedSwaps * 250 +
        totalSessions * 60 +
        acceptedRequests * 40 +
        teachingSet.length * 90 +
        learnedSet.length * 110;
    final level = (xp ~/ 1000) + 1;
    final levelProgress = (xp % 1000) / 1000;
    final successRate = closedRequests == 0 ? 0.0 : (acceptedRequests / closedRequests) * 100;
    final skillGrowth = progressBySkill.map((skill, values) {
      final average = values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
      return MapEntry(skill, average.clamp(0.0, 1.0).toDouble());
    });

    activityDates.sort();
    final firstCompleted = swapMaps
        .where((swap) => _stringValue(swap['status']).toLowerCase() == 'completed' || _numValue(swap['progress']) >= 1.0)
        .map((swap) => _dateValue(swap['lastSessionAt']) ?? _dateValue(swap['createdAt']))
        .whereType<DateTime>()
        .toList()
      ..sort();

    return _ProfileData(
      uid: uid,
      name: name,
      username: username,
      initials: _initials(name),
      imageUrl: imageUrl,
      rating: rating,
      totalSwaps: totalSwaps,
      completedSwaps: completedSwaps,
      xp: xp,
      level: level,
      levelProgress: levelProgress,
      successRate: successRate.clamp(0.0, 100.0).toDouble(),
      skillsLearned: learnedSet.toList()..sort(),
      skillsTeaching: teachingSet.toList()..sort(),
      weeklyActivity: _weeklyActivity(activityDates),
      monthlyActivity: _monthlyActivity(activityDates),
      skillGrowth: skillGrowth,
      firstActivityAt: activityDates.isEmpty ? null : activityDates.first,
      firstCompletedSwapAt: firstCompleted.isEmpty ? null : firstCompleted.first,
    );
  }
}

class _BadgeCatalog {
  static List<_BadgeStatus> evaluate(_ProfileData data) {
    final badges = [
      _BadgeRule(
        id: 'first_swap',
        title: 'First Swap',
        description: 'Complete your first skill swap.',
        icon: Icons.handshake_rounded,
        target: 1,
        current: data.completedSwaps,
        unlockDate: data.firstCompletedSwapAt,
      ),
      _BadgeRule(
        id: 'skill_builder',
        title: 'Skill Builder',
        description: 'Learn three different skills.',
        icon: Icons.school_rounded,
        target: 3,
        current: data.skillsLearnedCount,
        unlockDate: data.firstActivityAt,
      ),
      _BadgeRule(
        id: 'mentor_mode',
        title: 'Mentor Mode',
        description: 'Teach three skills to the community.',
        icon: Icons.record_voice_over_rounded,
        target: 3,
        current: data.skillsTeachingCount,
        unlockDate: data.firstActivityAt,
      ),
      _BadgeRule(
        id: 'level_five',
        title: 'Level 5',
        description: 'Reach level five through XP.',
        icon: Icons.military_tech_rounded,
        target: 5,
        current: data.level,
        unlockDate: data.firstActivityAt,
      ),
      _BadgeRule(
        id: 'trusted_swapper',
        title: 'Trusted Swapper',
        description: 'Maintain an 80% success rate.',
        icon: Icons.verified_rounded,
        target: 80,
        current: data.successRate.round(),
        unlockDate: data.firstActivityAt,
      ),
      _BadgeRule(
        id: 'ten_swaps',
        title: 'Swap Streak',
        description: 'Complete ten skill swaps.',
        icon: Icons.local_fire_department_rounded,
        target: 10,
        current: data.completedSwaps,
        unlockDate: data.firstCompletedSwapAt,
      ),
    ];
    return badges.map((rule) => rule.status()).toList();
  }
}

class _BadgeRule {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int target;
  final int current;
  final DateTime? unlockDate;

  const _BadgeRule({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    required this.current,
    required this.unlockDate,
  });

  _BadgeStatus status() {
    final unlocked = current >= target;
    return _BadgeStatus(
      id: id,
      title: title,
      description: description,
      icon: icon,
      progress: target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0).toDouble(),
      unlocked: unlocked,
      unlockDate: unlocked ? unlockDate ?? DateTime.now() : null,
    );
  }
}

class _BadgeStatus {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final double progress;
  final bool unlocked;
  final DateTime? unlockDate;

  const _BadgeStatus({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.unlocked,
    required this.unlockDate,
  });
}

BoxDecoration _cardDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.16 : 0.12)),
    boxShadow: [
      BoxShadow(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.05 : 0.04),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

Future<void> _openEditProfile(BuildContext context, _ProfileData data) async {
  final db = FirebaseFirestore.instance;
  final snap = await db.collection('swapListings').where('userId', isEqualTo: data.uid).limit(1).get();
  if (!context.mounted) return;

  if (snap.docs.isNotEmpty) {
    final swap = SwapListing.fromDoc(snap.docs.first);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(swap: swap)));
    return;
  }

  final fallback = _swapFromProfile(data);
  await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(swap: fallback)));
}

SwapListing _swapFromProfile(_ProfileData data) {
  return SwapListing(
    id: data.uid,
    name: data.name,
    initials: data.initials,
    avatarColor: const Color(0xFF6B8AFF),
    offering: data.skillsTeaching.isNotEmpty ? data.skillsTeaching.first : '',
    wanting: data.skillsLearned.isNotEmpty ? data.skillsLearned.first : '',
    rating: data.rating,
    reviews: data.totalSwaps,
    category: 'All',
    userId: data.uid,
    imageUrl: data.imageUrl,
  );
}

String _username(Map<String, dynamic> userData, User? user) {
  final stored = _stringValue(userData['username']);
  if (stored.isNotEmpty) return stored.startsWith('@') ? stored : '@$stored';
  final emailName = user?.email?.split('@').first ?? '';
  if (emailName.isNotEmpty) return '@$emailName';
  return '@skillswapper';
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
}

String _stringValue(dynamic value) => value?.toString().trim() ?? '';

String? _nullableString(dynamic value) {
  final text = _stringValue(value);
  return text.isEmpty ? null : text;
}

double _numValue(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

int _intValue(dynamic value) => _numValue(value).round();

DateTime? _dateValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Map<String, int> _weeklyActivity(List<DateTime> dates) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  final result = {for (final label in labels) label: 0};
  for (final date in dates) {
    final day = DateTime(date.year, date.month, date.day);
    final diff = day.difference(start).inDays;
    if (diff >= 0 && diff < 7) {
      result[labels[diff]] = result[labels[diff]]! + 1;
    }
  }
  return result;
}

Map<String, int> _monthlyActivity(List<DateTime> dates) {
  final now = DateTime.now();
  final result = <String, int>{};
  for (int i = 5; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    result[_monthLabel(month.month)] = 0;
  }
  for (final date in dates) {
    final key = _monthLabel(date.month);
    if (result.containsKey(key) && DateTime(now.year, now.month - 5, 1).isBefore(DateTime(date.year, date.month + 1, 1))) {
      result[key] = result[key]! + 1;
    }
  }
  return result;
}

String _monthLabel(int month) {
  const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return labels[(month - 1).clamp(0, 11).toInt()];
}

String _shortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

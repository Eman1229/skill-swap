// lib/services/ai/mentor_compass_service.dart
// Recommends mentors using:
//   1. OpenAI text-embedding-3-small (via Cloud Function proxy)
//   2. Cosine similarity (pure Dart)
//   3. Weighted scoring:
//      New users (0 swaps): rating 45% + skillMatch 30% + successRate 20% + availability 5%
//      Experienced users:   skillMatch 40% + rating 25% + successRate 20% + availability 15%
// NOTE: Mentor Compass is ALWAYS available regardless of completed-swap count.

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_swap/models/ai/mentor_recommendation.dart';
import 'package:skill_swap/services/ai/openai_service.dart';

class MentorCompassService {
  static final MentorCompassService _instance = MentorCompassService._internal();
  factory MentorCompassService() => _instance;
  MentorCompassService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OpenAIService _openai = OpenAIService();

  // ── Public API ──────────────────────────────────────────────────────
  /// Computes mentor recommendations for any user, regardless of swap count.
  /// For new users (0 completed swaps), mentor ratings are weighted more heavily
  /// so the best-rated mentors surface at the top.
  Future<List<MentorRecommendation>> computeRecommendations() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      // 1. Fetch current user's data and swap count for weight selection
      final userData = await _fetchUserData(uid);
      final mySkillsLearned = List<String>.from(userData['skillsLearned'] ?? []);
      final mySkillsTeaching = List<String>.from(userData['skillsTeaching'] ?? []);
      final myWantedSkills = List<String>.from(userData['learningGoals'] ?? mySkillsLearned);

      // Determine user maturity to choose scoring weights
      final userDoc = await _db.collection('users').doc(uid).get();
      final completedSwapsField = (userDoc.data()?['completedSwaps'] as num?)?.toInt() ?? 0;
      final swapsSnap = await _db
          .collection('swaps')
          .where('participants', arrayContains: uid)
          .get();
      final completedExchangeCount = swapsSnap.docs.where((doc) {
        final data = doc.data();
        final status = (data['status'] as String? ?? '').toLowerCase();
        final progress = (data['progress'] as num?)?.toDouble() ?? 0.0;
        return status == 'completed' || progress >= 1.0;
      }).length;
      // Use the higher of the two counts to avoid penalising users with stale fields
      final completedSwaps = math.max(completedSwapsField, completedExchangeCount);
      final isNewUser = completedSwaps == 0;

      // 2. Fetch all swap listings (exclude own)
      final listingsSnap = await _db.collection('swapListings').get();
      final listings = listingsSnap.docs
          .where((doc) => doc.data()['userId'] != uid)
          .toList();

      if (listings.isEmpty) return _buildFallbackRecommendations(listings);

      // 3. Build skill description texts for embedding
      final myText = _buildSkillText(mySkillsTeaching, myWantedSkills);
      final mentorTexts = listings.map((doc) {
        final d = doc.data();
        final offering = (d['offering'] as String?) ?? '';
        final wanting = (d['wanting'] as String?) ?? '';
        return _buildSkillText([offering], [wanting]);
      }).toList();

      // 4. Get embeddings from Cloud Function (batched)
      List<List<double>>? allEmbeddings;
      try {
        final allTexts = [myText, ...mentorTexts];
        allEmbeddings = await _openai.getEmbeddings(allTexts);
      } catch (e) {
        debugPrint('MentorCompassService: embedding failed, using text overlap: $e');
        allEmbeddings = null;
      }

      // 5. Score each mentor
      final scores = <_MentorScore>[];
      for (int i = 0; i < listings.length; i++) {
        final doc = listings[i];
        final d = doc.data();

        double skillSimilarity;
        if (allEmbeddings != null && allEmbeddings.length > i + 1) {
          skillSimilarity = _cosineSimilarity(
            allEmbeddings[0],     // my embedding
            allEmbeddings[i + 1], // mentor's embedding
          );
        } else {
          // Fallback: text overlap score
          final offering = (d['offering'] as String?) ?? '';
          final wanting = (d['wanting'] as String?) ?? '';
          skillSimilarity = _textOverlapScore(
            [...mySkillsTeaching, ...myWantedSkills],
            [offering, wanting, ...(d['tags'] as List<dynamic>? ?? []).cast<String>()],
          );
        }

        final rating = (d['Rating'] as num?)?.toDouble() ?? 0.0;
        final reviews = (d['Reviews'] as num?)?.toInt() ?? 0;
        final successRate = (d['successRate'] as num?)?.toDouble() ?? (rating / 5.0);

        // ── Weighted final score (0-100) ────────────────────────────────
        // New users: prioritise rating heavily so the best-rated mentors
        //   surface at the top before any personal swap history exists.
        // Experienced users: rebalance towards skill match and availability.
        final double weightedScore;
        if (isNewUser) {
          // New user weights: rating 45% + skillMatch 30% + successRate 20% + availability 5%
          weightedScore = ((rating / 5.0) * 45) +
              (skillSimilarity * 30) +
              (successRate * 20) +
              (reviews > 0 ? 5 : 0);
        } else {
          // Experienced user weights: skillMatch 40% + rating 25% + successRate 20% + availability 15%
          weightedScore = (skillSimilarity * 40) +
              ((rating / 5.0) * 25) +
              (successRate * 20) +
              (reviews > 0 ? 15 : 5);
        }

        scores.add(_MentorScore(
          doc: doc,
          skillSimilarity: skillSimilarity,
          rating: rating,
          reviews: reviews,
          successRate: successRate,
          weightedScore: weightedScore.clamp(0, 100),
          isNewUserScore: isNewUser,
        ));
      }

      // 6. Sort by weighted score descending
      scores.sort((a, b) => b.weightedScore.compareTo(a.weightedScore));

      // 7. Build recommendation objects (top 5)
      final top = scores.take(5).toList();
      final recommendations = top.asMap().entries.map((entry) {
        final idx = entry.key;
        final s = entry.value;
        final d = s.doc.data();

        final name = (d['name'] as String?) ?? 'Unknown';
        final parts = name.trim().split(' ');
        final initials = parts.length >= 2
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : (parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'M');

        final matchPct = s.weightedScore.round();
        final compatPct = (s.skillSimilarity * 100).round();

        final whyRecs = _generateWhyRecommended(s, mySkillsTeaching, myWantedSkills, d);

        final skillCompat = <String, double>{};
        for (final skill in myWantedSkills.take(3)) {
          skillCompat[skill] = math.min(1.0, s.skillSimilarity + (math.Random().nextDouble() * 0.2));
        }
        final offering = (d['offering'] as String?) ?? '';
        if (offering.isNotEmpty && !skillCompat.containsKey(offering)) {
          skillCompat[offering] = math.min(1.0, s.skillSimilarity + 0.1);
        }

        return MentorRecommendation(
          id: s.doc.id,
          mentorId: (d['userId'] as String?) ?? s.doc.id,
          mentorName: name,
          mentorImageUrl: d['imageUrl'] as String?,
          mentorInitials: initials,
          mentorSkill: offering,
          mentorWantingSkill: (d['wanting'] as String?) ?? '',
          matchScore: matchPct.toDouble(),
          compatibilityScore: compatPct.toDouble(),
          whyRecommended: whyRecs,
          skillCompatibility: skillCompat,
          mentorStats: MentorStats(
            totalSwaps: (d['completedSwaps'] as num?)?.toInt() ?? s.reviews,
            averageRating: s.rating,
            totalReviews: s.reviews,
            successRate: s.successRate,
            yearsExperience: 1 + (s.reviews ~/ 10),
          ),
          isBestSwap: idx == 0,
          createdAt: DateTime.now(),
        );
      }).toList();

      debugPrint('MentorCompassService: scored ${scores.length} mentors '
          '(isNewUser=$isNewUser, completedSwaps=$completedSwaps). '
          'Top match score: ${top.isNotEmpty ? top.first.weightedScore.round() : 0}%');

      // 8. Save to Firestore (append-only)
      await _saveRecommendations(uid, recommendations);

      return recommendations;
    } catch (e, stack) {
      debugPrint('MentorCompassService.computeRecommendations error: $e\n$stack');
      return [];
    }
  }

  // ── Private Helpers ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> _fetchUserData(String uid) async {
    try {
      // Check swapListings for user's posted skill
      final listingSnap = await _db
          .collection('swapListings')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      final userDoc = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      if (listingSnap.docs.isNotEmpty) {
        final listingData = listingSnap.docs.first.data();
        final offering = (listingData['offering'] as String?) ?? '';
        final wanting = (listingData['wanting'] as String?) ?? '';
        if (offering.isNotEmpty) {
          userData['skillsTeaching'] = [offering, ...(userData['skillsTeaching'] as List? ?? [])];
        }
        if (wanting.isNotEmpty) {
          userData['skillsLearned'] = [wanting, ...(userData['skillsLearned'] as List? ?? [])];
        }
      }

      return userData;
    } catch (e) {
      debugPrint('MentorCompassService._fetchUserData error: $e');
      return {};
    }
  }

  String _buildSkillText(List<String> teaching, List<String> learning) {
    return 'Teaching: ${teaching.join(", ")}. Learning: ${learning.join(", ")}';
  }

  // Pure Dart cosine similarity
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;
    double dot = 0;
    double normA = 0;
    double normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = math.sqrt(normA) * math.sqrt(normB);
    if (denom == 0) return 0.0;
    // Clamp to [0, 1] — cosine can be negative for opposite vectors
    return ((dot / denom) + 1) / 2;
  }

  // Fallback: Jaccard-like text overlap
  double _textOverlapScore(List<String> setA, List<String> setB) {
    if (setA.isEmpty || setB.isEmpty) return 0.1;
    final tokensA = setA.expand((s) => s.toLowerCase().split(' ')).toSet();
    final tokensB = setB.expand((s) => s.toLowerCase().split(' ')).toSet();
    final intersection = tokensA.intersection(tokensB).length;
    final union = tokensA.union(tokensB).length;
    if (union == 0) return 0.1;
    return (intersection / union).clamp(0.05, 1.0);
  }

  List<String> _generateWhyRecommended(
    _MentorScore s,
    List<String> myTeaching,
    List<String> myWanted,
    Map<String, dynamic> d,
  ) {
    final reasons = <String>[];
    final offering = (d['offering'] as String?) ?? '';

    // For new users, lead with rating since that is the primary signal
    if (s.isNewUserScore) {
      if (s.rating >= 4.5) {
        reasons.add('Top-rated mentor — ${s.rating.toStringAsFixed(1)}★ rating');
      } else if (s.rating >= 4.0) {
        reasons.add('Highly rated mentor — ${s.rating.toStringAsFixed(1)}★ avg rating');
      } else if (s.rating > 0) {
        reasons.add('Rated ${s.rating.toStringAsFixed(1)}★ by the community');
      }
    }

    if (s.skillSimilarity > 0.7) {
      reasons.add('Strong skill alignment with your learning goals');
    } else if (s.skillSimilarity > 0.4) {
      reasons.add('Good skill match for your current learning path');
    }

    if (!s.isNewUserScore) {
      if (s.rating >= 4.5) {
        reasons.add('Top-rated mentor with ${s.rating.toStringAsFixed(1)} stars');
      } else if (s.rating >= 4.0) {
        reasons.add('Highly rated with ${s.rating.toStringAsFixed(1)} avg rating');
      }
    }

    if (offering.isNotEmpty && myWanted.any(
      (w) => w.toLowerCase().contains(offering.toLowerCase()) ||
          offering.toLowerCase().contains(w.toLowerCase()))) {
      reasons.add('Teaches exactly what you want to learn');
    }

    if (s.reviews >= 10) {
      reasons.add('Experienced mentor with ${s.reviews} completed swaps');
    }

    if (s.successRate > 0.8) {
      reasons.add('${(s.successRate * 100).round()}% swap success rate');
    }

    if (reasons.isEmpty) reasons.add('Curated match based on your skill profile');
    return reasons.take(3).toList();
  }

  Future<void> _saveRecommendations(
    String uid,
    List<MentorRecommendation> recs,
  ) async {
    try {
      final docId = DateTime.now().millisecondsSinceEpoch.toString();
      await _db
          .collection('mentor_recommendations')
          .doc(uid)
          .collection('history')
          .doc(docId)
          .set({
        'recommendations': recs.map((r) => r.toMap()).toList(),
        'userId': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'version': 1,
        'count': recs.length,
      });

      await _db.collection('mentor_recommendations').doc(uid).set({
        'latestId': docId,
        'updatedAt': FieldValue.serverTimestamp(),
        'topMatchScore': recs.isNotEmpty ? recs.first.matchScore : 0,
        'count': recs.length,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('MentorCompassService._saveRecommendations error: $e');
    }
  }

  List<MentorRecommendation> _buildFallbackRecommendations(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> listings) {
    return [];
  }
}

class _MentorScore {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final double skillSimilarity;
  final double rating;
  final int reviews;
  final double successRate;
  final double weightedScore;
  /// True when the score was computed with the new-user (rating-boosted) weights.
  final bool isNewUserScore;

  _MentorScore({
    required this.doc,
    required this.skillSimilarity,
    required this.rating,
    required this.reviews,
    required this.successRate,
    required this.weightedScore,
    this.isNewUserScore = false,
  });
}

import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/services/skill_exchange_service.dart';

class RateFeedbackScreen extends StatefulWidget {
  final String swapId;
  final String revieweeId;
  final String revieweeName;
  final String revieweeRole; // 'mentor' or 'learner'

  const RateFeedbackScreen({
    super.key,
    required this.swapId,
    required this.revieweeId,
    required this.revieweeName,
    required this.revieweeRole,
  });

  @override
  State<RateFeedbackScreen> createState() => _RateFeedbackScreenState();
}

class _RateFeedbackScreenState extends State<RateFeedbackScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  double _partnerRating = 5;
  double _overallRating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  String _getPartnerRatingText(double rating) {
    if (rating >= 5) return widget.revieweeRole == 'mentor' ? 'Excellent mentor!' : 'Amazing learner!';
    if (rating >= 4) return widget.revieweeRole == 'mentor' ? 'Great mentor!' : 'Great learner!';
    if (rating >= 3) return 'Good experience';
    if (rating >= 2) return 'Fair experience';
    return 'Could be better';
  }

  String _getOverallRatingText(double rating) {
    if (rating >= 5) return 'Excellent';
    if (rating >= 4) return 'Very Good';
    if (rating >= 3) return 'Good';
    if (rating >= 2) return 'Fair';
    return 'Poor';
  }

  Future<void> _submitFeedback(String skillName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Fetch current user's name
      String reviewerName = 'Someone';
      final reviewerDoc = await _db.collection('users').doc(uid).get();
      if (reviewerDoc.exists) {
        reviewerName = reviewerDoc.data()?['name'] ?? 'Someone';
      }

      // 2. Save feedback document (revieweeRole enables per-role rating splits)
      final reviewRef = _db.collection('reviews').doc();
      await reviewRef.set({
        'swapId': widget.swapId,
        'reviewerId': uid,
        'reviewerName': reviewerName,
        'revieweeId': widget.revieweeId,
        'revieweeName': widget.revieweeName,
        'revieweeRole': widget.revieweeRole, // 'mentor' or 'learner'
        'rating': _partnerRating,
        'overallExperienceRating': _overallRating,
        'comment': _commentController.text.trim(),
        'skillName': skillName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Recalculate average rating for reviewee
      final reviewsQuery = await _db
          .collection('reviews')
          .where('revieweeId', isEqualTo: widget.revieweeId)
          .get();

      double totalStars = 0.0;
      int reviewsCount = reviewsQuery.docs.length;

      for (var doc in reviewsQuery.docs) {
        final r = doc.data()['rating'];
        if (r is num) {
          totalStars += r.toDouble();
        }
      }

      final double newAverage = reviewsCount > 0 ? (totalStars / reviewsCount) : 0.0;

      // 4. Update reviewee user document
      await _db.collection('users').doc(widget.revieweeId).set({
        'averageRating': newAverage,
        'reviewsCount': reviewsCount,
      }, SetOptions(merge: true));

      // 5. Update listings in swapListings matching reviewee userId
      final listingsQuery = await _db
          .collection('swapListings')
          .where('userId', isEqualTo: widget.revieweeId)
          .get();

      final batch = _db.batch();
      for (var doc in listingsQuery.docs) {
        // Use 'Reviews' (capital R) to match the field initialized in offer_skill.dart
        // and read by SwapListing.fromDoc via d['Reviews'].
        batch.update(doc.reference, {
          'Rating': newAverage,
          'Reviews': reviewsCount,
        });
      }
      await batch.commit();

      // Check if both users have submitted reviews for this swap
      try {
        final swapDoc = await _db.collection('swaps').doc(widget.swapId).get();
        if (swapDoc.exists) {
          final swapData = swapDoc.data()!;
          final mentorId = swapData['mentorId'] ?? '';
          final learnerId = swapData['learnerId'] ?? '';
          final learnerName = swapData['learnerName'] ?? '';
          final skillNameLocal = swapData['skillName'] ?? skillName;

          final allReviewsQuery = await _db
              .collection('reviews')
              .where('swapId', isEqualTo: widget.swapId)
              .get();

          final uniqueReviewerIds = allReviewsQuery.docs
              .map((d) => d.data()['reviewerId']?.toString())
              .where((id) => id != null && id.isNotEmpty)
              .toSet();

          if (uniqueReviewerIds.contains(mentorId) && uniqueReviewerIds.contains(learnerId)) {
            // Both reviews have been submitted! Complete the swap.
            await SkillExchangeService().confirmSwapCompletion(
              swapId: widget.swapId,
              learnerId: learnerId,
              teacherId: mentorId,
              skillName: skillNameLocal,
              learnerName: learnerName,
            );
          }
        }
      } catch (e) {
        debugPrint('Error triggering swap completion in review submission: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('thank_you_feedback'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close the rating screen
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${'feedback_submit_failed'.tr()}: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('swaps').doc(widget.swapId).snapshots(),
      builder: (context, snapshot) {
        String skillName = 'Leave Feedback';
        if (snapshot.hasData && snapshot.data!.exists) {
          final swap = SwapModel.fromDoc(snapshot.data!);
          skillName = swap.skillName;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              skillName,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'leave_feedback'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // PARTNER RATING CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Rate ${widget.revieweeName}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.revieweeRole == 'mentor' ? 'Mentor' : 'Learner',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStarRatingBar(
                        rating: _partnerRating,
                        onRatingChanged: (val) => setState(() => _partnerRating = val),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getPartnerRatingText(_partnerRating),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // COMMENTS FIELD
                Text(
                  'Share your feedback',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  minLines: 3,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText:'feedback_hint'.tr(),
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 14),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),

                // OVERALL EXPERIENCE CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your Experience',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'How was your overall experience?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStarRatingBar(
                        rating: _overallRating,
                        onRatingChanged: (val) => setState(() => _overallRating = val),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getOverallRatingText(_overallRating),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // SUBMIT BUTTON
                if (_isSubmitting)
                  const Center(child: CircularProgressIndicator())
                else
                  GestureDetector(
                    onTap: () => _submitFeedback(skillName),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Theme.of(context).colorScheme.primary, const Color(0xFF008CCB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'submit_feedback'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'maybe_later'.tr(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStarRatingBar({
    required double rating,
    required ValueChanged<double> onRatingChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        final isSelected = starValue <= rating;
        return IconButton(
          onPressed: () => onRatingChanged(starValue),
          iconSize: 36,
          icon: Icon(
            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
            color: isSelected ? Colors.amber : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }
}

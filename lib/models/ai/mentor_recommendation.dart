// lib/models/ai/mentor_recommendation.dart

class MentorRecommendation {
  final String id;
  final String mentorId;
  final String mentorName;
  final String? mentorImageUrl;
  final String mentorInitials;
  final String mentorSkill;
  final String mentorWantingSkill;
  final String portfolioFile;
  final double matchScore;
  final double compatibilityScore;
  final List<String> whyRecommended;
  final Map<String, double> skillCompatibility;
  final MentorStats mentorStats;
  final bool isBestSwap;
  final DateTime createdAt;

  const MentorRecommendation({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    this.mentorImageUrl,
    required this.mentorInitials,
    required this.mentorSkill,
    required this.mentorWantingSkill,
    this.portfolioFile = '',
    required this.matchScore,
    required this.compatibilityScore,
    required this.whyRecommended,
    required this.skillCompatibility,
    required this.mentorStats,
    this.isBestSwap = false,
    required this.createdAt,
  });

  factory MentorRecommendation.fromMap(Map<String, dynamic> map, String id) {
    return MentorRecommendation(
      id: id,
      mentorId: map['mentorId'] as String? ?? '',
      mentorName: map['mentorName'] as String? ?? 'Unknown',
      mentorImageUrl: map['mentorImageUrl'] as String?,
      mentorInitials: map['mentorInitials'] as String? ?? 'M',
      mentorSkill: map['mentorSkill'] as String? ?? '',
      mentorWantingSkill: map['mentorWantingSkill'] as String? ?? '',
      portfolioFile: map['portfolioFile'] as String? ?? '',
      matchScore: (map['matchScore'] as num?)?.toDouble() ?? 0,
      compatibilityScore: (map['compatibilityScore'] as num?)?.toDouble() ?? 0,
      whyRecommended:
          List<String>.from(map['whyRecommended'] as List? ?? const []),
      skillCompatibility: Map<String, double>.from(
        (map['skillCompatibility'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
      mentorStats: MentorStats.fromMap(
          map['mentorStats'] as Map<String, dynamic>? ?? {}),
      isBestSwap: map['isBestSwap'] as bool? ?? false,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mentorId': mentorId,
      'mentorName': mentorName,
      'mentorImageUrl': mentorImageUrl,
      'mentorInitials': mentorInitials,
      'mentorSkill': mentorSkill,
      'mentorWantingSkill': mentorWantingSkill,
      'portfolioFile': portfolioFile,
      'matchScore': matchScore,
      'compatibilityScore': compatibilityScore,
      'whyRecommended': whyRecommended,
      'skillCompatibility': skillCompatibility,
      'mentorStats': mentorStats.toMap(),
      'isBestSwap': isBestSwap,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class MentorStats {
  final int totalSwaps;
  final double averageRating;
  final int totalReviews;
  final double successRate;
  final int yearsExperience;

  const MentorStats({
    required this.totalSwaps,
    required this.averageRating,
    required this.totalReviews,
    required this.successRate,
    required this.yearsExperience,
  });

  factory MentorStats.fromMap(Map<String, dynamic> map) {
    return MentorStats(
      totalSwaps: (map['totalSwaps'] as num?)?.toInt() ?? 0,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0,
      totalReviews: (map['totalReviews'] as num?)?.toInt() ?? 0,
      successRate: (map['successRate'] as num?)?.toDouble() ?? 0,
      yearsExperience: (map['yearsExperience'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'totalSwaps': totalSwaps,
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'successRate': successRate,
        'yearsExperience': yearsExperience,
      };
}

class MentorReview {
  final String reviewerName;
  final String? reviewerImageUrl;
  final double rating;
  final String comment;
  final DateTime date;

  const MentorReview({
    required this.reviewerName,
    this.reviewerImageUrl,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory MentorReview.fromMap(Map<String, dynamic> map) {
    return MentorReview(
      reviewerName: map['reviewerName'] as String? ?? 'Anonymous',
      reviewerImageUrl: map['reviewerImageUrl'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] as String? ?? '',
      date: map['date'] is DateTime
          ? map['date'] as DateTime
          : DateTime.now(),
    );
  }
}

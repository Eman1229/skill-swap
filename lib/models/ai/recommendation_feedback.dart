// lib/models/ai/recommendation_feedback.dart

class RecommendationFeedback {
  final String id;
  final String userId;
  final String recommendationId;
  final String type; // 'mentor', 'career', 'roadmap'
  final int rating; // 1 to 5 stars
  final String comment;
  final DateTime createdAt;

  const RecommendationFeedback({
    required this.id,
    required this.userId,
    required this.recommendationId,
    required this.type,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory RecommendationFeedback.fromMap(Map<String, dynamic> map, String id) {
    return RecommendationFeedback(
      id: id,
      userId: map['userId'] as String? ?? '',
      recommendationId: map['recommendationId'] as String? ?? '',
      type: map['type'] as String? ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] as String? ?? '',
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'recommendationId': recommendationId,
      'type': type,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

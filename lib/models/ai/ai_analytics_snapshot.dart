// lib/models/ai/ai_analytics_snapshot.dart

class AIAnalyticsSnapshot {
  final String userId;
  final double learningHours;
  final int skillsGained;
  final double teachingHours;
  final double sessionSuccessRate;
  final double mentorMatchAccuracy;
  final double roadmapProgress;
  final double careerReadinessScore;
  final int projectsCompleted;
  final bool isLearningConsistent;
  final Map<String, int> weeklyLearningHours; // day -> hours
  final DateTime createdAt;
  final String period; // 'daily', 'weekly', 'monthly', 'yearly'

  const AIAnalyticsSnapshot({
    required this.userId,
    required this.learningHours,
    required this.skillsGained,
    required this.teachingHours,
    required this.sessionSuccessRate,
    required this.mentorMatchAccuracy,
    required this.roadmapProgress,
    required this.careerReadinessScore,
    required this.projectsCompleted,
    required this.isLearningConsistent,
    required this.weeklyLearningHours,
    required this.createdAt,
    required this.period,
  });

  factory AIAnalyticsSnapshot.empty(String userId) => AIAnalyticsSnapshot(
        userId: userId,
        learningHours: 0,
        skillsGained: 0,
        teachingHours: 0,
        sessionSuccessRate: 0,
        mentorMatchAccuracy: 0,
        roadmapProgress: 0,
        careerReadinessScore: 0,
        projectsCompleted: 0,
        isLearningConsistent: false,
        weeklyLearningHours: const {
          'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
        },
        createdAt: DateTime.now(),
        period: 'weekly',
      );

  factory AIAnalyticsSnapshot.fromMap(Map<String, dynamic> map) {
    return AIAnalyticsSnapshot(
      userId: map['userId'] as String? ?? '',
      learningHours: (map['learningHours'] as num?)?.toDouble() ?? 0,
      skillsGained: (map['skillsGained'] as num?)?.toInt() ?? 0,
      teachingHours: (map['teachingHours'] as num?)?.toDouble() ?? 0,
      sessionSuccessRate:
          (map['sessionSuccessRate'] as num?)?.toDouble() ?? 0,
      mentorMatchAccuracy:
          (map['mentorMatchAccuracy'] as num?)?.toDouble() ?? 0,
      roadmapProgress: (map['roadmapProgress'] as num?)?.toDouble() ?? 0,
      careerReadinessScore:
          (map['careerReadinessScore'] as num?)?.toDouble() ?? 0,
      projectsCompleted: (map['projectsCompleted'] as num?)?.toInt() ?? 0,
      isLearningConsistent: map['isLearningConsistent'] as bool? ?? false,
      weeklyLearningHours: Map<String, int>.from(
        (map['weeklyLearningHours'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
      ),
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.now(),
      period: map['period'] as String? ?? 'weekly',
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'learningHours': learningHours,
        'skillsGained': skillsGained,
        'teachingHours': teachingHours,
        'sessionSuccessRate': sessionSuccessRate,
        'mentorMatchAccuracy': mentorMatchAccuracy,
        'roadmapProgress': roadmapProgress,
        'careerReadinessScore': careerReadinessScore,
        'projectsCompleted': projectsCompleted,
        'isLearningConsistent': isLearningConsistent,
        'weeklyLearningHours': weeklyLearningHours,
        'createdAt': createdAt.toIso8601String(),
        'period': period,
      };
}

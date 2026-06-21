// lib/models/ai/career_recommendation.dart

class CareerRecommendation {
  final String id;
  final String careerSummary;
  final List<String> strengthAreas;
  final List<String> growthAreas;
  final List<CareerPath> careers;
  final DateTime createdAt;

  const CareerRecommendation({
    required this.id,
    required this.careerSummary,
    required this.strengthAreas,
    required this.growthAreas,
    required this.careers,
    required this.createdAt,
  });

  factory CareerRecommendation.empty() => CareerRecommendation(
        id: '',
        careerSummary: '',
        strengthAreas: const [],
        growthAreas: const [],
        careers: const [],
        createdAt: DateTime.now(),
      );

  factory CareerRecommendation.fromMap(Map<String, dynamic> map, String id) {
    return CareerRecommendation(
      id: id,
      careerSummary: map['careerSummary'] as String? ?? '',
      strengthAreas:
          List<String>.from(map['strengthAreas'] as List? ?? const []),
      growthAreas:
          List<String>.from(map['growthAreas'] as List? ?? const []),
      careers: (map['careers'] as List? ?? [])
          .map((e) => CareerPath.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'careerSummary': careerSummary,
        'strengthAreas': strengthAreas,
        'growthAreas': growthAreas,
        'careers': careers.map((c) => c.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}

class CareerPath {
  final String title;
  final int fitScore;
  final String demandIndicator; // 'High', 'Medium', 'Low'
  final String salaryRange;
  final List<String> requiredSkills;
  final List<String> missingSkills;
  final int estimatedLearningMonths;
  final String description;

  const CareerPath({
    required this.title,
    required this.fitScore,
    required this.demandIndicator,
    required this.salaryRange,
    required this.requiredSkills,
    required this.missingSkills,
    required this.estimatedLearningMonths,
    required this.description,
  });

  factory CareerPath.fromMap(Map<String, dynamic> map) {
    return CareerPath(
      title: map['title'] as String? ?? 'Career Path',
      fitScore: (map['fitScore'] as num?)?.toInt() ?? 0,
      demandIndicator: map['demandIndicator'] as String? ?? 'Medium',
      salaryRange: map['salaryRange'] as String? ?? 'N/A',
      requiredSkills:
          List<String>.from(map['requiredSkills'] as List? ?? const []),
      missingSkills:
          List<String>.from(map['missingSkills'] as List? ?? const []),
      estimatedLearningMonths:
          (map['estimatedLearningMonths'] as num?)?.toInt() ?? 6,
      description: map['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'fitScore': fitScore,
        'demandIndicator': demandIndicator,
        'salaryRange': salaryRange,
        'requiredSkills': requiredSkills,
        'missingSkills': missingSkills,
        'estimatedLearningMonths': estimatedLearningMonths,
        'description': description,
      };
}

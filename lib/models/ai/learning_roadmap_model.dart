// lib/models/ai/learning_roadmap_model.dart

class LearningRoadmapModel {
  final String id;
  final String targetCareer;
  final int estimatedMonths;
  final String aiInsight;
  final List<RoadmapStage> stages;
  final List<RoadmapMilestone> milestones;
  final DateTime createdAt;

  const LearningRoadmapModel({
    required this.id,
    required this.targetCareer,
    required this.estimatedMonths,
    required this.aiInsight,
    required this.stages,
    required this.milestones,
    required this.createdAt,
  });

  factory LearningRoadmapModel.empty() => LearningRoadmapModel(
        id: '',
        targetCareer: '',
        estimatedMonths: 0,
        aiInsight: '',
        stages: const [],
        milestones: const [],
        createdAt: DateTime.now(),
      );

  bool get isEmpty => id.isEmpty;

  factory LearningRoadmapModel.fromMap(Map<String, dynamic> map, String id) {
    return LearningRoadmapModel(
      id: id,
      targetCareer: map['targetCareer'] as String? ?? '',
      estimatedMonths: (map['estimatedMonths'] as num?)?.toInt() ?? 6,
      aiInsight: map['aiInsight'] as String? ?? '',
      stages: (map['stages'] as List? ?? [])
          .map((e) => RoadmapStage.fromMap(e as Map<String, dynamic>))
          .toList(),
      milestones: (map['milestones'] as List? ?? [])
          .map((e) => RoadmapMilestone.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'targetCareer': targetCareer,
        'estimatedMonths': estimatedMonths,
        'aiInsight': aiInsight,
        'stages': stages.map((s) => s.toMap()).toList(),
        'milestones': milestones.map((m) => m.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  LearningRoadmapModel copyWith({
    List<RoadmapStage>? stages,
    List<RoadmapMilestone>? milestones,
  }) {
    return LearningRoadmapModel(
      id: id,
      targetCareer: targetCareer,
      estimatedMonths: estimatedMonths,
      aiInsight: aiInsight,
      stages: stages ?? this.stages,
      milestones: milestones ?? this.milestones,
      createdAt: createdAt,
    );
  }
}

class RoadmapStage {
  final int stageNumber;
  final String stageName;
  final String description;
  final int estimatedWeeks;
  final double completionPercent;
  final List<RoadmapTask> tasks;
  final List<RoadmapResource> resources;

  const RoadmapStage({
    required this.stageNumber,
    required this.stageName,
    required this.description,
    required this.estimatedWeeks,
    required this.completionPercent,
    required this.tasks,
    required this.resources,
  });

  String get status {
    if (completionPercent >= 1.0) return 'Completed';
    if (completionPercent > 0) return 'In Progress';
    return 'Pending';
  }

  factory RoadmapStage.fromMap(Map<String, dynamic> map) {
    return RoadmapStage(
      stageNumber: (map['stageNumber'] as num?)?.toInt() ?? 1,
      stageName: map['stageName'] as String? ?? 'Stage',
      description: map['description'] as String? ?? '',
      estimatedWeeks: (map['estimatedWeeks'] as num?)?.toInt() ?? 4,
      completionPercent:
          (map['completionPercent'] as num?)?.toDouble() ?? 0.0,
      tasks: (map['tasks'] as List? ?? [])
          .map((e) => RoadmapTask.fromMap(e as Map<String, dynamic>))
          .toList(),
      resources: (map['resources'] as List? ?? [])
          .map((e) => RoadmapResource.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'stageNumber': stageNumber,
        'stageName': stageName,
        'description': description,
        'estimatedWeeks': estimatedWeeks,
        'completionPercent': completionPercent,
        'tasks': tasks.map((t) => t.toMap()).toList(),
        'resources': resources.map((r) => r.toMap()).toList(),
      };

  RoadmapStage copyWith({
    List<RoadmapTask>? tasks,
    double? completionPercent,
  }) {
    return RoadmapStage(
      stageNumber: stageNumber,
      stageName: stageName,
      description: description,
      estimatedWeeks: estimatedWeeks,
      completionPercent: completionPercent ?? this.completionPercent,
      tasks: tasks ?? this.tasks,
      resources: resources,
    );
  }
}

class RoadmapTask {
  final String id;
  final String title;
  final String description;
  final int estimatedHours;
  final bool isCompleted;

  const RoadmapTask({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedHours,
    required this.isCompleted,
  });

  factory RoadmapTask.fromMap(Map<String, dynamic> map) {
    return RoadmapTask(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      estimatedHours: (map['estimatedHours'] as num?)?.toInt() ?? 1,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'estimatedHours': estimatedHours,
        'isCompleted': isCompleted,
      };

  RoadmapTask copyWith({bool? isCompleted}) => RoadmapTask(
        id: id,
        title: title,
        description: description,
        estimatedHours: estimatedHours,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

class RoadmapResource {
  final String id;
  final String title;
  final String platform;
  final String url;
  final String type; // 'Course', 'Article', 'Video', 'Book'
  final int learnersCount;

  const RoadmapResource({
    required this.id,
    required this.title,
    required this.platform,
    required this.url,
    required this.type,
    required this.learnersCount,
  });

  factory RoadmapResource.fromMap(Map<String, dynamic> map) {
    return RoadmapResource(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      platform: map['platform'] as String? ?? '',
      url: map['url'] as String? ?? '',
      type: map['type'] as String? ?? 'Course',
      learnersCount: (map['learnersCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'platform': platform,
        'url': url,
        'type': type,
        'learnersCount': learnersCount,
      };
}

class RoadmapMilestone {
  final String id;
  final String title;
  final String description;
  final int stageNumber;
  final String icon;
  final bool isCompleted;

  const RoadmapMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.stageNumber,
    required this.icon,
    required this.isCompleted,
  });

  factory RoadmapMilestone.fromMap(Map<String, dynamic> map) {
    return RoadmapMilestone(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      stageNumber: (map['stageNumber'] as num?)?.toInt() ?? 1,
      icon: map['icon'] as String? ?? 'school',
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'stageNumber': stageNumber,
        'icon': icon,
        'isCompleted': isCompleted,
      };

  RoadmapMilestone copyWith({bool? isCompleted}) => RoadmapMilestone(
        id: id,
        title: title,
        description: description,
        stageNumber: stageNumber,
        icon: icon,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

class RoadmapProgress {
  final int currentStage;
  final String currentRoadmapId;
  final List<String> completedTaskIds;
  final List<String> completedMilestoneIds;
  final double overallPercent;
  final DateTime updatedAt;

  const RoadmapProgress({
    required this.currentStage,
    required this.currentRoadmapId,
    required this.completedTaskIds,
    required this.completedMilestoneIds,
    required this.overallPercent,
    required this.updatedAt,
  });

  factory RoadmapProgress.empty() => RoadmapProgress(
        currentStage: 1,
        currentRoadmapId: '',
        completedTaskIds: const [],
        completedMilestoneIds: const [],
        overallPercent: 0,
        updatedAt: DateTime.now(),
      );

  factory RoadmapProgress.fromMap(Map<String, dynamic> map) {
    return RoadmapProgress(
      currentStage: (map['currentStage'] as num?)?.toInt() ?? 1,
      currentRoadmapId: map['currentRoadmapId'] as String? ?? '',
      completedTaskIds:
          List<String>.from(map['completedTaskIds'] as List? ?? const []),
      completedMilestoneIds: List<String>.from(
          map['completedMilestoneIds'] as List? ?? const []),
      overallPercent: (map['overallPercent'] as num?)?.toDouble() ?? 0.0,
      updatedAt: map['updatedAt'] is DateTime
          ? map['updatedAt'] as DateTime
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'currentStage': currentStage,
        'currentRoadmapId': currentRoadmapId,
        'completedTaskIds': completedTaskIds,
        'completedMilestoneIds': completedMilestoneIds,
        'overallPercent': overallPercent,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

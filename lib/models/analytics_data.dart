class AnalyticsData {
  final String uid;
  final String name;
  final String username;
  final String initials;
  final String? imageUrl;
  final int totalXp;
  final double learningHours;
  final double teachingHours;
  final int skillsLearnedCount;
  final int skillsTeachingCount;
  final int activeTeachingSwapsCount;
  final int activeLearningSwapsCount;
  final double averageRating;
  final double learningRating;
  final double teachingRating;
  final int reviewsCount;
  final double weeklyGrowthPercentage;
  final double monthlyGrowthPercentage;
  final int completedSessions;
  final int completedLearningSessions;
  final int completedTeachingSessions;
  final double attendanceRate;
  final double successRate;
  final int currentXp;
  final int currentLevel;
  final int xpRequiredForNextLevel;
  final double levelProgressPercentage;
  final int completedSwaps;
  final int learningStreak;
  final int teachingStreak;
  final int totalAchievements;
  final List<String> skillsLearned;
  final List<String> skillsTeaching;
  final Map<String, int> weeklyActivity;
  final Map<String, int> monthlyActivity;
  final Map<String, double> skillGrowth;
  final int unlockedBadges;
  final int totalBadges;
  final DateTime? firstActivityAt;
  final DateTime? firstCompletedSwapAt;

  const AnalyticsData({
    required this.uid,
    required this.name,
    required this.username,
    required this.initials,
    required this.imageUrl,
    required this.totalXp,
    required this.learningHours,
    required this.teachingHours,
    required this.skillsLearnedCount,
    required this.skillsTeachingCount,
    required this.activeTeachingSwapsCount,
    required this.activeLearningSwapsCount,
    required this.averageRating,
    this.learningRating = 0.0,
    this.teachingRating = 0.0,
    this.reviewsCount = 0,
    required this.weeklyGrowthPercentage,
    required this.monthlyGrowthPercentage,
    required this.completedSessions,
    this.completedLearningSessions = 0,
    this.completedTeachingSessions = 0,
    required this.attendanceRate,
    required this.successRate,
    required this.currentXp,
    required this.currentLevel,
    required this.xpRequiredForNextLevel,
    required this.levelProgressPercentage,
    required this.completedSwaps,
    required this.learningStreak,
    required this.teachingStreak,
    required this.totalAchievements,
    required this.skillsLearned,
    required this.skillsTeaching,
    required this.weeklyActivity,
    required this.monthlyActivity,
    required this.skillGrowth,
    required this.unlockedBadges,
    required this.totalBadges,
    this.firstActivityAt,
    this.firstCompletedSwapAt,
  });

  int get xp => totalXp;
  int get level => currentLevel;
  double get levelProgress => levelProgressPercentage;
  double get rating => averageRating;

  factory AnalyticsData.empty(String uid) {
    return AnalyticsData(
      uid: uid,
      name: 'User',
      username: '@user',
      initials: 'U',
      imageUrl: null,
      totalXp: 0,
      learningHours: 0.0,
      teachingHours: 0.0,
      skillsLearnedCount: 0,
      skillsTeachingCount: 0,
      activeTeachingSwapsCount: 0,
      activeLearningSwapsCount: 0,
      averageRating: 0.0,
      learningRating: 0.0,
      teachingRating: 0.0,
      reviewsCount: 0,
      weeklyGrowthPercentage: 0.0,
      monthlyGrowthPercentage: 0.0,
      completedSessions: 0,
      completedLearningSessions: 0,
      completedTeachingSessions: 0,
      attendanceRate: 0.0,
      successRate: 0.0,
      currentXp: 0,
      currentLevel: 1,
      xpRequiredForNextLevel: 1000,
      levelProgressPercentage: 0.0,
      completedSwaps: 0,
      learningStreak: 0,
      teachingStreak: 0,
      totalAchievements: 0,
      skillsLearned: const [],
      skillsTeaching: const [],
      weeklyActivity: const {'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0},
      monthlyActivity: const {},
      skillGrowth: const {},
      unlockedBadges: 0,
      totalBadges: 6,
      firstActivityAt: null,
      firstCompletedSwapAt: null,
    );
  }
}

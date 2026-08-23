import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap/models/ai/career_recommendation.dart';
import 'package:skill_swap/models/ai/learning_roadmap_model.dart';
import 'package:skill_swap/models/ai/mentor_recommendation.dart';
import 'package:skill_swap/models/analytics_data.dart';
import 'package:skill_swap/models/message.dart';
import 'package:skill_swap/models/session_model.dart';

class GuestSwapListing {
  final String id;
  final String name;
  final String initials;
  final Color avatarColor;
  final String offering;
  final String wanting;
  final double rating;
  final int reviews;
  final String category;
  final bool isLive;
  final String skillLevel;
  final String userId;
  final String description;
  final String experience;
  final String? imageUrl;
  final bool isFeatured;

  GuestSwapListing({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.offering,
    required this.wanting,
    required this.rating,
    required this.reviews,
    required this.category,
    this.isLive = true,
    this.skillLevel = 'Expert',
    required this.userId,
    required this.description,
    required this.experience,
    this.imageUrl,
    this.isFeatured = true,
  });
}

class GuestModeService extends ChangeNotifier {
  static final GuestModeService _instance = GuestModeService._internal();
  factory GuestModeService() => _instance;
  GuestModeService._internal();

  bool _isGuestMode = false;
  bool get isGuestMode => _isGuestMode;

  void enableGuestMode() {
    _isGuestMode = true;
    notifyListeners();
  }

  void disableGuestMode() {
    _isGuestMode = false;
    notifyListeners();
  }

  // Mock User Info
  String get guestUserId => 'guest_demo_user_101';
  String get guestUserName => 'Alex Rivers (Guest)';
  String get guestUserInitials => 'AR';
  String get guestUserOffering => 'UI/UX Design & Figma Prototyping';
  String get guestUserWanting => 'Flutter App Development & Dart';
  int get guestUserCredits => 150;

  // Mock Listings
  final List<GuestSwapListing> _mockListings = [
    GuestSwapListing(
      id: 'demo_listing_1',
      userId: 'user_sarah_1',
      name: 'Sarah Jenkins',
      initials: 'SJ',
      avatarColor: const Color(0xFF0284C7),
      offering: 'Flutter & Dart Mobile Architecture',
      wanting: 'UI/UX System Design & Figma',
      rating: 4.9,
      reviews: 28,
      category: 'Coding',
      isLive: true,
      skillLevel: 'Advanced',
      description:
          'Senior Mobile Architect with 5+ years of Flutter experience. I can help you build cross-platform apps, manage state with Provider/Riverpod, and master clean architecture.',
      experience: '5+ years in Flutter, Lead Dev at TechStudio',
      isFeatured: true,
    ),
    GuestSwapListing(
      id: 'demo_listing_2',
      userId: 'user_david_2',
      name: 'David Chen',
      initials: 'DC',
      avatarColor: const Color(0xFF8B5CF6),
      offering: 'UI/UX System Design & Prototyping',
      wanting: 'Python & AI Model Integration',
      rating: 4.8,
      reviews: 19,
      category: 'Design',
      isLive: true,
      skillLevel: 'Expert',
      description:
          'Lead Product Designer specializing in design systems, high-fidelity micro-interactions, and accessible web/mobile UIs.',
      experience: '6 years UX Designer at Studio Craft',
      isFeatured: true,
    ),
    GuestSwapListing(
      id: 'demo_listing_3',
      userId: 'user_elena_3',
      name: 'Elena Rostova',
      initials: 'ER',
      avatarColor: const Color(0xFF10B981),
      offering: 'Python & Machine Learning Fundamentals',
      wanting: 'Digital Marketing & Growth Hacking',
      rating: 5.0,
      reviews: 34,
      category: 'AI',
      isLive: false,
      skillLevel: 'Expert',
      description:
          'Data Scientist & ML engineer teaching Python data analytics, OpenAI API integrations, and practical prompt engineering.',
      experience: 'Senior AI Specialist at DataPulse',
      isFeatured: true,
    ),
    GuestSwapListing(
      id: 'demo_listing_4',
      userId: 'user_marcus_4',
      name: 'Marcus Vance',
      initials: 'MV',
      avatarColor: const Color(0xFFF59E0B),
      offering: 'Cybersecurity & Cloud DevOps (AWS/GCP)',
      wanting: 'React & Web Frontend Development',
      rating: 4.7,
      reviews: 14,
      category: 'Coding',
      isLive: true,
      skillLevel: 'Intermediate',
      description:
          'Cloud infrastructure engineer providing hands-on tutorials for secure container deployment, Docker, and CI/CD pipelines.',
      experience: '4 years Cloud Security Consultant',
      isFeatured: false,
    ),
  ];

  List<GuestSwapListing> get mockListings => List.unmodifiable(_mockListings);

  // Mock Conversations & Messages
  final List<ChatMessage> _mockMessages = [
    ChatMessage(
      id: 'msg_1',
      senderId: 'user_sarah_1',
      text:
          'Hi Alex! I saw your UI/UX Design offer. I would love to teach you Flutter in exchange for Figma design system tips!',
      timestamp: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3))),
      status: MessageStatus.read,
      type: 'text',
    ),
    ChatMessage(
      id: 'msg_2',
      senderId: 'guest_demo_user_101',
      text:
          'Hey Sarah! That sounds fantastic! I am preparing a SkillswapX Web Expo demo right now.',
      timestamp: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
      status: MessageStatus.read,
      type: 'text',
    ),
    ChatMessage(
      id: 'msg_3',
      senderId: 'user_sarah_1',
      text:
          'Awesome! I checked out your portfolio. Let us schedule our first 1-on-1 swap session soon!',
      timestamp: Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 30))),
      status: MessageStatus.read,
      type: 'text',
    ),
  ];

  final StreamController<List<ChatMessage>> _messagesStreamController =
      StreamController<List<ChatMessage>>.broadcast();

  Stream<List<ChatMessage>> get mockMessagesStream {
    Future.microtask(() {
      if (!_messagesStreamController.isClosed) {
        _messagesStreamController.add(List.unmodifiable(_mockMessages));
      }
    });
    return _messagesStreamController.stream;
  }

  List<ChatMessage> get mockMessages => List.unmodifiable(_mockMessages);

  void addMockMessage(String text) {
    final newMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: guestUserId,
      text: text,
      timestamp: Timestamp.now(),
      status: MessageStatus.sent,
      type: 'text',
    );
    _mockMessages.add(newMsg);
    _messagesStreamController.add(List.unmodifiable(_mockMessages));
    notifyListeners();

    // Auto reply simulation after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      _mockMessages.add(
        ChatMessage(
          id: 'msg_reply_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'user_sarah_1',
          text:
              'Thanks for your message! Looking forward to our next skill swap session on Flutter Web.',
          timestamp: Timestamp.now(),
          status: MessageStatus.read,
          type: 'text',
        ),
      );
      _messagesStreamController.add(List.unmodifiable(_mockMessages));
      notifyListeners();
    });
  }

  // Mock Active Swaps & Sessions
  final List<SessionModel> _mockSessions = [
    SessionModel(
      id: 'session_demo_101',
      swapId: 'swap_sarah_alex_1',
      title: 'Flutter App Architecture & State Management',
      date: DateTime.now().add(const Duration(days: 1, hours: 2)),
      duration: '45 mins',
      meetingLink: 'https://meet.google.com/demo-skill-swap',
      mentorId: 'user_sarah_1',
      learnerId: 'guest_demo_user_101',
      mentorName: 'Sarah Jenkins',
      learnerName: 'Alex Rivers (Guest)',
      participantIds: ['user_sarah_1', 'guest_demo_user_101'],
      status: 'accepted',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SessionModel(
      id: 'session_demo_102',
      swapId: 'swap_sarah_alex_1',
      title: 'Figma Auto-Layout & Design Tokens',
      date: DateTime.now().subtract(const Duration(days: 2)),
      duration: '60 mins',
      meetingLink: 'https://meet.google.com/demo-skill-swap-completed',
      mentorId: 'guest_demo_user_101',
      learnerId: 'user_sarah_1',
      mentorName: 'Alex Rivers (Guest)',
      learnerName: 'Sarah Jenkins',
      participantIds: ['user_sarah_1', 'guest_demo_user_101'],
      status: 'completed',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  List<SessionModel> get mockSessions => List.unmodifiable(_mockSessions);

  AnalyticsData get mockAnalyticsData => AnalyticsData(
        uid: guestUserId,
        name: guestUserName,
        username: '@alex_rivers',
        initials: guestUserInitials,
        imageUrl: null,
        totalXp: 1250,
        learningHours: 14.5,
        teachingHours: 12.0,
        skillsLearnedCount: 3,
        skillsTeachingCount: 2,
        activeTeachingSwapsCount: 1,
        activeLearningSwapsCount: 2,
        averageRating: 4.9,
        learningRating: 4.9,
        teachingRating: 5.0,
        reviewsCount: 18,
        weeklyGrowthPercentage: 24.5,
        monthlyGrowthPercentage: 45.0,
        completedSessions: 8,
        completedLearningSessions: 5,
        completedTeachingSessions: 3,
        attendanceRate: 0.98,
        successRate: 0.96,
        currentXp: 250,
        currentLevel: 2,
        xpRequiredForNextLevel: 1000,
        levelProgressPercentage: 0.25,
        completedSwaps: 4,
        learningStreak: 5,
        teachingStreak: 3,
        totalAchievements: 6,
        skillsLearned: const ['Flutter Web', 'Dart Concurrency', 'State Management'],
        skillsTeaching: const ['UI/UX System Design', 'Figma Prototyping'],
        weeklyActivity: const {
          'Mon': 2,
          'Tue': 3,
          'Wed': 1,
          'Thu': 4,
          'Fri': 2,
          'Sat': 5,
          'Sun': 1,
        },
        monthlyActivity: const {},
        skillGrowth: const {'Flutter': 0.85, 'Figma': 0.95},
        unlockedBadges: 4,
        totalBadges: 6,
        firstActivityAt: DateTime.now().subtract(const Duration(days: 30)),
        firstCompletedSwapAt: DateTime.now().subtract(const Duration(days: 20)),
      );

  // Mock AI Recommendations
  MentorRecommendation get mockAIMentorRecommendation => MentorRecommendation(
        id: 'mentor_rec_sarah',
        mentorId: 'user_sarah_1',
        mentorName: 'Sarah Jenkins',
        mentorInitials: 'SJ',
        mentorSkill: 'Flutter Architecture & Web',
        mentorWantingSkill: 'UI/UX System Design',
        matchScore: 98.0,
        compatibilityScore: 95.0,
        whyRecommended: [
          '98% Skill Complementarity — Perfect match to accelerate your mobile & web frontend career goal.',
          'Experienced Lead Dev with 5+ years of Flutter experience.'
        ],
        skillCompatibility: const {
          'Flutter': 0.98,
          'UI/UX Design': 0.95,
          'Dart': 0.96,
        },
        mentorStats: const MentorStats(
          totalSwaps: 28,
          averageRating: 4.9,
          totalReviews: 24,
          successRate: 0.98,
          yearsExperience: 5,
        ),
        isBestSwap: true,
        createdAt: DateTime.now(),
      );

  CareerRecommendation get mockAICareerRecommendation => CareerRecommendation(
        id: 'career_rec_guest',
        careerSummary:
            'Based on your skill swaps and mobile development interest, mastering Flutter Web, Riverpod state management, and Clean Architecture positions you for high-impact Tech Lead roles.',
        strengthAreas: const ['Dart & Flutter UI', 'Figma Design Systems', 'Prototyping'],
        growthAreas: const ['Flutter Web Expo', 'State Management (Riverpod)', 'CI/CD Pipelines'],
        careers: const [
          CareerPath(
            title: 'Lead Flutter & Web Architect',
            fitScore: 94,
            demandIndicator: 'High',
            salaryRange: '\$130k - \$165k',
            requiredSkills: ['Flutter Web', 'Riverpod', 'Clean Architecture'],
            missingSkills: ['CI/CD Deployment'],
            estimatedLearningMonths: 4,
            description: 'Strong background in design systems coupled with hands-on Dart implementation.',
          ),
          CareerPath(
            title: 'Senior Mobile UX Engineer',
            fitScore: 88,
            demandIndicator: 'High',
            salaryRange: '\$115k - \$145k',
            requiredSkills: ['UI Design Tokens', 'Flutter Widgets', 'User Testing'],
            missingSkills: ['WASM Optimization'],
            estimatedLearningMonths: 3,
            description: 'Combines high-fidelity Figma designs with cross-platform Dart implementation.',
          ),
        ],
        createdAt: DateTime.now(),
      );

  LearningRoadmapModel get mockAILearningRoadmap => LearningRoadmapModel(
        id: 'roadmap_demo_1',
        targetCareer: 'Flutter Web Expo Master',
        estimatedMonths: 4,
        aiInsight:
            'Focus on responsive layout math, web platform safety, and Firebase Hosting deployment to complete your Expo demo mastery.',
        stages: [
          RoadmapStage(
            stageNumber: 1,
            stageName: 'Advanced Dart Concurrency & Async Programming',
            description:
                'Master Futures, Streams, and Isolates for high-performance mobile and web apps.',
            estimatedWeeks: 3,
            completionPercent: 1.0,
            tasks: const [
              RoadmapTask(
                id: 'task_1',
                title: 'Dart Streams & Broadcast Controllers',
                description: 'Understand stream transformations and async generators.',
                estimatedHours: 8,
                isCompleted: true,
              ),
            ],
            resources: const [
              RoadmapResource(
                id: 'res_1',
                title: 'Official Dart Asynchronous Programming Guide',
                platform: 'Dart.dev',
                url: 'https://dart.dev/guides/language/async',
                type: 'Documentation',
                learnersCount: 1420,
              ),
            ],
          ),
          RoadmapStage(
            stageNumber: 2,
            stageName: 'Flutter Web Expo & Mobile Responsiveness',
            description:
                'Optimize viewports, responsive widgets, and Web compilation safety.',
            estimatedWeeks: 4,
            completionPercent: 1.0,
            tasks: const [
              RoadmapTask(
                id: 'task_2',
                title: 'Web Viewports & Plugin Guarding',
                description: 'Safely guard native plugins using kIsWeb.',
                estimatedHours: 6,
                isCompleted: true,
              ),
            ],
            resources: const [
              RoadmapResource(
                id: 'res_2',
                title: 'Building Responsive Web Apps with Flutter',
                platform: 'Flutter.dev',
                url: 'https://flutter.dev/to/web',
                type: 'Course',
                learnersCount: 2890,
              ),
            ],
          ),
        ],
        milestones: const [
          RoadmapMilestone(
            id: 'ms_1',
            title: 'Deploy First Flutter Web Demo to Firebase Hosting',
            description: 'Publish full interactive demo with QR code access.',
            stageNumber: 2,
            icon: 'rocket_launch',
            isCompleted: true,
          ),
        ],
        createdAt: DateTime.now(),
      );
}

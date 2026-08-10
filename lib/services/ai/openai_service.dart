// lib/services/ai/openai_service.dart
// Thin client for the three Firebase Cloud Functions that proxy OpenAI.
// Fallback: If _directApiKey is set, calls OpenAI directly using client-side HTTP
// and writes results directly to Firestore to bypass the need for Blaze plan.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();
  static const String _directApiKey = 'YOUR_OPENAI_API_KEY_HERE';
  // ── Client-side Direct Config ───────────────────────────────────────


  String get _getApiKey {
    if (_directApiKey.isNotEmpty && _directApiKey != 'YOUR_OPENAI_API_KEY_HERE') {
      return _directApiKey;
    }
    return const String.fromEnvironment('OPENAI_API_KEY');
  }

  bool get _useDirectOpenAI => _getApiKey.isNotEmpty;

  static const String _region = 'us-central1';
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: _region);

  Future<Map<String, dynamic>> _callFunction(
    String functionName,
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final callable = _functions.httpsCallable(
        functionName,
        options: HttpsCallableOptions(timeout: timeout),
      );
      final result = await callable.call(payload);
      return Map<String, dynamic>.from(_normalize(result.data) as Map);
    } catch (e) {
      debugPrint('OpenAIService.$functionName error: $e');
      rethrow;
    }
  }

  // ── Embeddings ──────────────────────────────────────────────────────
  /// Returns a list of embedding vectors for the given texts.
  Future<List<List<double>>> getEmbeddings(List<String> texts) async {
    if (_useDirectOpenAI) {
      try {
        final apiKey = _getApiKey;
        debugPrint('[Direct OpenAI] Fetching embeddings for ${texts.length} items...');
        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/embeddings'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'text-embedding-3-small',
            'input': texts,
          }),
        );
        if (response.statusCode != 200) {
          throw Exception('OpenAI Embeddings error: ${response.body}');
        }
        final json = jsonDecode(response.body);
        final embeddings = json['data'] as List;
        return embeddings
            .map(
              (e) => List<double>.from(
                (e['embedding'] as List).map((v) => (v as num).toDouble()),
              ),
            )
            .toList();
      } catch (e, stack) {
        debugPrint('[Direct OpenAI] getEmbeddings error: $e\n$stack');
        rethrow;
      }
    }

    final data = await _callFunction('getEmbedding', {'texts': texts});
    final embeddings = data['embeddings'] as List;
    return embeddings
        .map(
          (e) => List<double>.from(
            (e as List).map((v) => (v as num).toDouble()),
          ),
        )
        .toList();
  }

  dynamic _normalize(dynamic value) {
    if (value is Map) {
      return value.map((key, nestedValue) {
        return MapEntry(key.toString(), _normalize(nestedValue));
      });
    }
    if (value is List) {
      return value.map(_normalize).toList();
    }
    return value;
  }

  // ── Career Compass ──────────────────────────────────────────────────
  /// Calls the "generateCareerRecommendation" Cloud Function or OpenAI directly.
  Future<Map<String, dynamic>> generateCareerRecommendation({
    required List<String> skillsLearned,
    required List<String> skillsTeaching,
    required int completedSwaps,
    required double averageRating,
    required double learningHours,
    required double teachingHours,
    required int learningStreak,
    required int totalAchievements,
    required double successRate,
    String? careerGoal,
    List<String> interests = const [],
    String profileSummary = '',
    List<String> recentSwapHistory = const [],
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    if (interests.isEmpty || profileSummary.isEmpty) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      if (interests.isEmpty) {
        interests = List<String>.from(userData['interests'] ?? []);
      }
      if (profileSummary.isEmpty) {
        profileSummary = userData['profileSummary']?.toString() ?? '';
      }
    }

    final swapHistoryText = recentSwapHistory.isNotEmpty
        ? recentSwapHistory.join(' | ')
        : 'None yet';

    if (_useDirectOpenAI) {
      final apiKey = _getApiKey;

      final systemPrompt = "You are a career guidance AI specializing in skill-based career matching.\n"
          "Analyze the user's learning profile and generate personalized career path recommendations.\n"
          "Always respond with valid JSON only — no markdown, no code blocks.";

      final userPrompt = "Analyze this learner profile and recommend career paths:\n\n"
          "Skills Learned: ${skillsLearned.join(', ').isNotEmpty ? skillsLearned.join(', ') : 'None yet'}\n"
          "Skills Teaching: ${skillsTeaching.join(', ').isNotEmpty ? skillsTeaching.join(', ') : 'None yet'}\n"
          "Interests: ${interests.join(', ').isNotEmpty ? interests.join(', ') : 'Not specified'}\n"
          "Profile Summary: ${profileSummary.isNotEmpty ? profileSummary : 'Not specified'}\n"
          "Completed Swaps: $completedSwaps\n"
          "Average Rating: ${averageRating.toStringAsFixed(1)}/5.0\n"
          "Learning Hours: ${learningHours.toStringAsFixed(1)}\n"
          "Teaching Hours: ${teachingHours.toStringAsFixed(1)}\n"
          "Learning Streak: $learningStreak days\n"
          "Total Achievements: $totalAchievements\n"
          "Success Rate: ${(successRate * 100).toStringAsFixed(0)}%\n"
          "Career Goal: ${careerGoal ?? 'Not specified'}\n"
          "Recent Swap History: $swapHistoryText\n\n"
          "Return ONLY this JSON structure (no other text):\n"
          "{\n"
          "  \"careerSummary\": \"2-3 sentence personalized career summary\",\n"
          "  \"strengthAreas\": [\"area1\", \"area2\", \"area3\"],\n"
          "  \"growthAreas\": [\"area1\", \"area2\", \"area3\"],\n"
          "  \"careers\": [\n"
          "    {\n"
          "      \"title\": \"Career Title\",\n"
          "      \"fitScore\": 92,\n"
          "      \"demandIndicator\": \"High\",\n"
          "      \"salaryRange\": \"\$60k - \$90k\",\n"
          "      \"requiredSkills\": [\"skill1\", \"skill2\", \"skill3\"],\n"
          "      \"missingSkills\": [\"skill1\", \"skill2\"],\n"
          "      \"estimatedLearningMonths\": 6,\n"
          "      \"description\": \"Brief role description\"\n"
          "    }\n"
          "  ]\n"
          "}\n\n"
          "Generate 4-5 career paths. fitScore 0-100. demandIndicator: \"High\", \"Medium\", or \"Low\".";

      Map<String, dynamic> parsed;
      try {
        debugPrint('[Direct OpenAI] Calling GPT-4o-mini for Career Suggestion...');
        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'temperature': 0.7,
            'max_tokens': 1500,
            'response_format': {'type': 'json_object'},
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          throw Exception('OpenAI API error: ${response.body}');
        }

        final jsonResult = jsonDecode(response.body);
        final content = jsonResult['choices'][0]['message']['content'] as String;
        parsed = jsonDecode(content) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('[Direct OpenAI] API call failed ($e). Falling back to local offline recommendation generator...');
        parsed = _generateLocalCareerRecommendation(
          skillsLearned: skillsLearned,
          skillsTeaching: skillsTeaching,
          interests: interests,
          profileSummary: profileSummary,
          completedSwaps: completedSwaps,
          averageRating: averageRating,
          careerGoal: careerGoal,
          recentSwapHistory: recentSwapHistory,
        );
      }

      return await _saveCareerRecommendation(
        uid,
        parsed,
        skillsLearned,
        skillsTeaching,
        interests,
        completedSwaps,
        averageRating,
        recentSwapHistory,
      );
    }

    try {
      final result = await _callFunction(
        'generateCareerRecommendation',
        {
          'skillsLearned': skillsLearned,
          'skillsTeaching': skillsTeaching,
          'completedSwaps': completedSwaps,
          'averageRating': averageRating,
          'learningHours': learningHours,
          'teachingHours': teachingHours,
          'learningStreak': learningStreak,
          'totalAchievements': totalAchievements,
          'successRate': successRate,
          'careerGoal': careerGoal,
          'interests': interests,
          'profileSummary': profileSummary,
          'recentSwapHistory': recentSwapHistory,
        },
        timeout: const Duration(seconds: 30),
      );
      return result;
    } catch (e) {
      debugPrint('[Cloud Function] Call failed ($e). Falling back to local offline recommendation generator...');
      final parsed = _generateLocalCareerRecommendation(
        skillsLearned: skillsLearned,
        skillsTeaching: skillsTeaching,
        interests: interests,
        profileSummary: profileSummary,
        completedSwaps: completedSwaps,
        averageRating: averageRating,
        careerGoal: careerGoal,
        recentSwapHistory: recentSwapHistory,
      );
      return await _saveCareerRecommendation(
        uid,
        parsed,
        skillsLearned,
        skillsTeaching,
        interests,
        completedSwaps,
        averageRating,
        recentSwapHistory,
      );
    }
  }

  Future<Map<String, dynamic>> _saveCareerRecommendation(
    String uid,
    Map<String, dynamic> parsed,
    List<String> skillsLearned,
    List<String> skillsTeaching,
    List<String> interests,
    int completedSwaps,
    double averageRating,
    List<String> recentSwapHistory,
  ) async {
    final docId = DateTime.now().millisecondsSinceEpoch.toString();
    final resultData = {
      ...parsed,
      'id': docId,
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'version': 1,
      'trigger': 'manual',
      'triggerData': {
        'skillsLearned': skillsLearned,
        'skillsTeaching': skillsTeaching,
        'interests': interests,
        'completedSwaps': completedSwaps,
        'averageRating': averageRating,
        'recentSwapHistory': recentSwapHistory,
      },
    };

    await FirebaseFirestore.instance
        .collection('career_recommendations')
        .doc(uid)
        .collection('history')
        .doc(docId)
        .set(resultData);

    await FirebaseFirestore.instance
        .collection('career_recommendations')
        .doc(uid)
        .set({
      'latestId': docId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return resultData;
  }

  // ── Learning Roadmap ────────────────────────────────────────────────
  /// Calls the "generateLearningRoadmap" Cloud Function or OpenAI directly.
  Future<Map<String, dynamic>> generateLearningRoadmap({
    required String targetCareer,
    required List<String> currentSkills,
    required List<String> missingSkills,
    required double learningHours,
    required int completedSwaps,
    required double averageRating,
    List<String> interests = const [],
    List<String> recentSwapHistory = const [],
    String profileSummary = '',
    List<String> skillsTeaching = const [],
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    if (interests.isEmpty) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      interests = List<String>.from(userData['interests'] ?? []);
    }

    final swapHistoryText = recentSwapHistory.isNotEmpty
        ? recentSwapHistory.join(' | ')
        : 'None yet';

    if (_useDirectOpenAI) {
      final apiKey = _getApiKey;

      final systemPrompt = "You are a personalized learning roadmap AI.\n"
          "Create structured, actionable learning roadmaps for skill-based learners.\n"
          "Always respond with valid JSON only — no markdown, no code blocks.";

      final userPrompt = "Create a personalized learning roadmap for:\n\n"
          "Target Career: $targetCareer\n"
          "Current Skills: ${currentSkills.join(', ').isNotEmpty ? currentSkills.join(', ') : 'Beginner'}\n"
          "Skills to Learn: ${missingSkills.join(', ')}\n"
          "Interests: ${interests.join(', ').isNotEmpty ? interests.join(', ') : 'Not specified'}\n"
          "Skills Teaching: ${skillsTeaching.join(', ').isNotEmpty ? skillsTeaching.join(', ') : 'None yet'}\n"
          "Profile Summary: ${profileSummary.isNotEmpty ? profileSummary : 'Not specified'}\n"
          "Recent Swap History: $swapHistoryText\n"
          "Learning Hours So Far: ${learningHours.toStringAsFixed(0)}\n"
          "Completed Swaps: $completedSwaps\n"
          "Average Rating: ${averageRating.toStringAsFixed(1)}/5.0\n\n"
          "Return ONLY this JSON structure:\n"
          "{\n"
          "  \"targetCareer\": \"$targetCareer\",\n"
          "  \"estimatedMonths\": 8,\n"
          "  \"aiInsight\": \"1 sentence motivational insight about their progress\",\n"
          "  \"stages\": [\n"
          "    {\n"
          "      \"stageNumber\": 1,\n"
          "      \"stageName\": \"Foundation\",\n"
          "      \"description\": \"Short stage description\",\n"
          "      \"estimatedWeeks\": 4,\n"
          "      \"completionPercent\": 0,\n"
          "      \"tasks\": [\n"
          "        {\n"
          "          \"id\": \"t1_1\",\n"
          "          \"title\": \"Task title\",\n"
          "          \"description\": \"Short task description\",\n"
          "          \"estimatedHours\": 3,\n"
          "          \"isCompleted\": false\n"
          "        }\n"
          "      ],\n"
          "      \"resources\": [\n"
          "        {\n"
          "          \"id\": \"r1_1\",\n"
          "          \"title\": \"Resource title\",\n"
          "          \"platform\": \"Platform name\",\n"
          "          \"url\": \"https://example.com\",\n"
          "          \"type\": \"Course\",\n"
          "          \"learnersCount\": 12500\n"
          "        }\n"
          "      ]\n"
          "    }\n"
          "  ],\n"
          "  \"milestones\": [\n"
          "    {\n"
          "      \"id\": \"m1\",\n"
          "      \"title\": \"Milestone title\",\n"
          "      \"description\": \"Short description\",\n"
          "      \"stageNumber\": 1,\n"
          "      \"icon\": \"school\",\n"
          "      \"isCompleted\": false\n"
          "    }\n"
          "  ]\n"
          "}";

      Map<String, dynamic> parsed;
      try {
        debugPrint('[Direct OpenAI] Calling GPT-4o-mini for Learning Roadmap...');
        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'temperature': 0.7,
            'max_tokens': 1500,
            'response_format': {'type': 'json_object'},
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          throw Exception('OpenAI API error: ${response.body}');
        }

        final jsonResult = jsonDecode(response.body);
        final content = jsonResult['choices'][0]['message']['content'] as String;
        parsed = jsonDecode(content) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('[Direct OpenAI] API call failed ($e). Falling back to local offline roadmap generator...');
        parsed = _generateLocalLearningRoadmap(
          targetCareer: targetCareer,
          currentSkills: currentSkills,
          missingSkills: missingSkills,
          interests: interests,
          learningHours: learningHours,
          completedSwaps: completedSwaps,
          averageRating: averageRating,
          skillsTeaching: skillsTeaching,
          recentSwapHistory: recentSwapHistory,
        );
      }

      return await _saveLearningRoadmap(
        uid,
        parsed,
        targetCareer,
        currentSkills,
        missingSkills,
        interests,
        completedSwaps,
        averageRating,
        recentSwapHistory,
      );
    }

    try {
      final result = await _callFunction(
        'generateLearningRoadmap',
        {
          'targetCareer': targetCareer,
          'currentSkills': currentSkills,
          'missingSkills': missingSkills,
          'learningHours': learningHours,
          'completedSwaps': completedSwaps,
          'averageRating': averageRating,
          'interests': interests,
          'recentSwapHistory': recentSwapHistory,
          'profileSummary': profileSummary,
          'skillsTeaching': skillsTeaching,
        },
        timeout: const Duration(seconds: 30),
      );
      return result;
    } catch (e) {
      debugPrint('[Cloud Function] Call failed ($e). Falling back to local offline roadmap generator...');
      final parsed = _generateLocalLearningRoadmap(
        targetCareer: targetCareer,
        currentSkills: currentSkills,
        missingSkills: missingSkills,
        interests: interests,
        learningHours: learningHours,
        completedSwaps: completedSwaps,
        averageRating: averageRating,
        skillsTeaching: skillsTeaching,
        recentSwapHistory: recentSwapHistory,
      );
      return await _saveLearningRoadmap(
        uid,
        parsed,
        targetCareer,
        currentSkills,
        missingSkills,
        interests,
        completedSwaps,
        averageRating,
        recentSwapHistory,
      );
    }
  }

  Future<Map<String, dynamic>> _saveLearningRoadmap(
    String uid,
    Map<String, dynamic> parsed,
    String targetCareer,
    List<String> currentSkills,
    List<String> missingSkills,
    List<String> interests,
    int completedSwaps,
    double averageRating,
    List<String> recentSwapHistory,
  ) async {
    final docId = DateTime.now().millisecondsSinceEpoch.toString();
    final resultData = {
      ...parsed,
      'id': docId,
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'version': 1,
      'trigger': 'manual',
      'triggerData': {
        'currentSkills': currentSkills,
        'missingSkills': missingSkills,
        'interests': interests,
        'completedSwaps': completedSwaps,
        'averageRating': averageRating,
        'recentSwapHistory': recentSwapHistory,
      },
    };

    await FirebaseFirestore.instance
        .collection('learning_roadmaps')
        .doc(uid)
        .collection('history')
        .doc(docId)
        .set(resultData);

    await FirebaseFirestore.instance
        .collection('learning_roadmaps')
        .doc(uid)
        .set({
      'latestId': docId,
      'targetCareer': targetCareer,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('roadmap_progress')
        .doc(uid)
        .set({
      'currentRoadmapId': docId,
      'completedTaskIds': [],
      'completedMilestoneIds': [],
      'overallPercent': 0.0,
      'currentStage': 1,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return resultData;
  }

  Map<String, dynamic> _generateLocalCareerRecommendation({
    required List<String> skillsLearned,
    required List<String> skillsTeaching,
    required List<String> interests,
    required String profileSummary,
    required int completedSwaps,
    required double averageRating,
    String? careerGoal,
    List<String> recentSwapHistory = const [],
  }) {
    final String learnText = skillsLearned.isNotEmpty ? skillsLearned.first : 'new technologies';
    final String teachText = skillsTeaching.isNotEmpty ? skillsTeaching.first : 'programming';
    
    return {
      'careerSummary': 'Based on your profile with a strong focus on teaching $teachText and learning $learnText, you are well-positioned for career paths in cross-platform development, technical leadership, and engineering consulting.',
      'strengthAreas': [
        'Expertise and mentoring in ${skillsTeaching.isNotEmpty ? skillsTeaching.join(", ") : "core development skills"}',
        'Demonstrated commitment to peer learning and skill sharing',
        'Strong problem solving and communication capacity'
      ],
      'growthAreas': [
        'Gaining deeper practical experience in ${skillsLearned.isNotEmpty ? skillsLearned.join(", ") : "advanced technologies"}',
        'Understanding enterprise architecture patterns',
        'Project lifecycle management and client collaboration'
      ],
      'careers': [
        {
          'title': 'Cross-Platform App Developer',
          'fitScore': 94,
          'demandIndicator': 'High',
          'salaryRange': '\$95k - \$130k',
          'requiredSkills': ['Flutter', 'Dart', 'State Management', 'Firebase', 'API Integration'],
          'missingSkills': skillsLearned.isNotEmpty ? skillsLearned : ['State Management', 'Testing'],
          'estimatedLearningMonths': 4,
          'description': 'Design, build, and deploy high-performance cross-platform mobile and web applications.'
        },
        {
          'title': 'Frontend Engineer',
          'fitScore': 88,
          'demandIndicator': 'High',
          'salaryRange': '\$90k - \$125k',
          'requiredSkills': ['HTML/CSS', 'JavaScript', 'React/Vue', 'Responsive Design', 'Git'],
          'missingSkills': ['React/Vue', 'Webpack'],
          'estimatedLearningMonths': 5,
          'description': 'Develop modern, highly interactive user interfaces and web applications using advanced frontend frameworks.'
        },
        {
          'title': 'Technical Solutions Consultant',
          'fitScore': 85,
          'demandIndicator': 'Medium',
          'salaryRange': '\$100k - \$140k',
          'requiredSkills': ['System Design', 'Communication', 'Cloud Architecture', 'APIs'],
          'missingSkills': ['Cloud Architecture', 'Enterprise Patterns'],
          'estimatedLearningMonths': 6,
          'description': 'Bridge the gap between business requirements and technical implementation, advising clients on optimal software stack and architecture.'
        },
        {
          'title': 'Full-Stack Developer',
          'fitScore': 82,
          'demandIndicator': 'High',
          'salaryRange': '\$105k - \$150k',
          'requiredSkills': ['Node.js', 'Databases', 'APIs', 'Frontend Frameworks', 'DevOps'],
          'missingSkills': ['Database Administration', 'DevOps'],
          'estimatedLearningMonths': 8,
          'description': 'Build and maintain both the frontend user interfaces and the backend database/server infrastructure of web applications.'
        }
      ]
    };
  }

  Map<String, dynamic> _generateLocalLearningRoadmap({
    required String targetCareer,
    required List<String> currentSkills,
    required List<String> missingSkills,
    required List<String> interests,
    required double learningHours,
    required int completedSwaps,
    required double averageRating,
    List<String> skillsTeaching = const [],
    List<String> recentSwapHistory = const [],
  }) {
    final cleanMissing = missingSkills.isNotEmpty ? missingSkills : ['Advanced architecture', 'Testing and CI/CD'];
    
    return {
      'targetCareer': targetCareer,
      'estimatedMonths': 6,
      'aiInsight': 'You have already built a solid foundation. Focus on mastering ${cleanMissing.join(", ")} to be fully job-ready.',
      'stages': [
        {
          'stageNumber': 1,
          'stageName': 'Foundations & Core Setup',
          'description': 'Establish your environment and master the essential syntax and concepts.',
          'estimatedWeeks': 4,
          'completionPercent': 0,
          'tasks': [
            {
              'id': 't1_1',
              'title': 'Set up development environment',
              'description': 'Install IDEs, SDKs, and configure simulators/devices.',
              'estimatedHours': 4,
              'isCompleted': false
            },
            {
              'id': 't1_2',
              'title': 'Complete basic tutorials',
              'description': 'Build 3 simple apps/projects to understand components and lifecycle.',
              'estimatedHours': 12,
              'isCompleted': false
            }
          ],
          'resources': [
            {
              'id': 'r1_1',
              'title': 'Official Getting Started Documentation',
              'platform': 'Official Docs',
              'url': 'https://docs.flutter.dev',
              'type': 'Documentation',
              'learnersCount': 100000
            }
          ]
        },
        {
          'stageNumber': 2,
          'stageName': 'Practical Project Building',
          'description': 'Deepen your knowledge by working on real-world projects and peer swaps.',
          'estimatedWeeks': 6,
          'completionPercent': 0,
          'tasks': [
            {
              'id': 't2_1',
              'title': 'Implement state management',
              'description': 'Master Provider, BLoC, or Riverpod in a multi-screen application.',
              'estimatedHours': 15,
              'isCompleted': false
            },
            {
              'id': 't2_2',
              'title': 'Integrate backend services',
              'description': 'Connect your application to Firestore and Firebase Auth.',
              'estimatedHours': 10,
              'isCompleted': false
            }
          ],
          'resources': [
            {
              'id': 'r2_1',
              'title': 'Practical App Development Course',
              'platform': 'YouTube',
              'url': 'https://youtube.com',
              'type': 'Video',
              'learnersCount': 45000
            }
          ]
        },
        {
          'stageNumber': 3,
          'stageName': 'Advanced Architecture & Deployment',
          'description': 'Learn testing, clean architecture, and deploy your work.',
          'estimatedWeeks': 4,
          'completionPercent': 0,
          'tasks': [
            {
              'id': 't3_1',
              'title': 'Write unit and integration tests',
              'description': 'Ensure code reliability and setup automated test suites.',
              'estimatedHours': 8,
              'isCompleted': false
            },
            {
              'id': 't3_2',
              'title': 'Deploy to App Store / Play Store',
              'description': 'Configure release builds, sign bundle, and upload to console.',
              'estimatedHours': 6,
              'isCompleted': false
            }
          ],
          'resources': [
            {
              'id': 'r3_1',
              'title': 'Clean Architecture & Testing Guide',
              'platform': 'Medium',
              'url': 'https://medium.com',
              'type': 'Article',
              'learnersCount': 18000
            }
          ]
        }
      ],
      'milestones': [
        {
          'id': 'm1',
          'title': 'Development Environment Ready',
          'description': 'SDK configured and test build running on physical device.',
          'stageNumber': 1,
          'icon': 'school',
          'isCompleted': false
        },
        {
          'id': 'm2',
          'title': 'Core Application Complete',
          'description': 'Functional multi-screen app with state management and database sync.',
          'stageNumber': 2,
          'icon': 'star',
          'isCompleted': false
        },
        {
          'id': 'm3',
          'title': 'App Published / Verified',
          'description': 'Built for production and code signed successfully.',
          'stageNumber': 3,
          'icon': 'verified',
          'isCompleted': false
        }
      ]
    };
  }
}

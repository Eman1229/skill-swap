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
    final cleanLearned = skillsLearned.where((s) => s.isNotEmpty).toList();
    final cleanTeaching = skillsTeaching.where((s) => s.isNotEmpty).toList();
    final cleanInterests = interests.where((s) => s.isNotEmpty).toList();

    final allUserSkills = <String>{
      ...cleanLearned,
      ...cleanTeaching,
      ...cleanInterests,
    }.map((s) => s.toLowerCase()).toSet();

    final primarySkill = cleanLearned.isNotEmpty
        ? cleanLearned.first
        : (cleanTeaching.isNotEmpty
            ? cleanTeaching.first
            : (cleanInterests.isNotEmpty ? cleanInterests.first : 'Technology'));

    // ── Pre-defined Domain Skill Matrices ──────────────────────────────────
    final domains = [
      {
        'title': 'AI & Data Science Specialist',
        'keywords': ['python', 'data', 'ai', 'machine learning', 'sql', 'statistics', 'pandas', 'analytics', 'tensorflow', 'r', 'deep learning'],
        'required': ['Python', 'SQL & Data Wrangling', 'Machine Learning', 'Data Visualization', 'Model Deployment'],
        'salary': '\$105k - \$150k',
        'demand': 'High',
        'desc': 'Analyze data structures, build predictive machine learning models, and derive actionable insights for automated systems.'
      },
      {
        'title': 'UI/UX & Product Designer',
        'keywords': ['design', 'ui', 'ux', 'figma', 'user research', 'prototyping', 'adobe', 'graphic', 'wireframing', 'illustrator'],
        'required': ['Figma & Prototyping', 'User Research', 'Design Systems', 'Usability Testing', 'UI Architecture'],
        'salary': '\$85k - \$125k',
        'demand': 'High',
        'desc': 'Create intuitive, user-centered digital interfaces, prototype seamless visual flows, and conduct usability research.'
      },
      {
        'title': 'Cross-Platform Mobile Engineer',
        'keywords': ['flutter', 'dart', 'mobile', 'android', 'ios', 'react native', 'swift', 'kotlin', 'app'],
        'required': ['Flutter & Dart', 'State Management', 'REST APIs', 'Firebase Services', 'Mobile UI/UX'],
        'salary': '\$95k - \$135k',
        'demand': 'High',
        'desc': 'Architect, build, and publish high-performance cross-platform mobile and web applications.'
      },
      {
        'title': 'Frontend Web Architect',
        'keywords': ['javascript', 'react', 'vue', 'html', 'css', 'web', 'frontend', 'typescript', 'tailwind'],
        'required': ['JavaScript / TypeScript', 'React / Modern Frameworks', 'Responsive CSS', 'Web Performance', 'State Management'],
        'salary': '\$90k - \$130k',
        'demand': 'High',
        'desc': 'Design and engineer interactive, highly responsive web interfaces using modern component architecture.'
      },
      {
        'title': 'Backend & Cloud Systems Engineer',
        'keywords': ['node', 'java', 'backend', 'cloud', 'aws', 'api', 'database', 'sql', 'docker', 'go', 'microservices'],
        'required': ['API Design & REST/gRPC', 'Database Systems', 'Node.js / Cloud Runtime', 'Microservices', 'CI/CD Pipelines'],
        'salary': '\$100k - \$145k',
        'demand': 'High',
        'desc': 'Construct scalable server architectures, secure database pipelines, and cloud microservices.'
      },
      {
        'title': 'Digital Growth & Product Manager',
        'keywords': ['marketing', 'product', 'agile', 'scrum', 'seo', 'strategy', 'management', 'growth', 'analytics'],
        'required': ['Product Strategy', 'Agile & Scrum', 'User Analytics', 'Market Research', 'Roadmap Planning'],
        'salary': '\$95k - \$140k',
        'demand': 'Medium',
        'desc': 'Lead cross-functional teams, formulate product visions, and drive metrics-driven growth strategies.'
      },
      {
        'title': 'DevOps & Cyber Security Specialist',
        'keywords': ['security', 'devops', 'linux', 'networking', 'cyber', 'kubernetes', 'docker', 'cloud security'],
        'required': ['Linux Administration', 'Containerization & Docker', 'Cloud Security', 'Automated Testing', 'Network Security'],
        'salary': '\$110k - \$155k',
        'demand': 'High',
        'desc': 'Protect digital infrastructure, automate deployment pipelines, and enforce rigorous cloud security protocols.'
      },
    ];

    // ── Generate Customized Career Paths ─────────────────────────────────
    final generatedCareers = <Map<String, dynamic>>[];

    // 1. If explicit career goal is provided, insert as Top Match
    if (careerGoal != null && careerGoal.trim().isNotEmpty) {
      final goalTitle = careerGoal.trim();
      final goalReq = [
        primarySkill,
        'Advanced $primarySkill',
        'System Architecture',
        'Testing & Optimization',
        'Peer Collaboration'
      ];
      final missing = goalReq.where((r) => !allUserSkills.contains(r.toLowerCase())).toList();

      generatedCareers.add({
        'title': goalTitle,
        'fitScore': 95,
        'demandIndicator': 'High',
        'salaryRange': '\$95k - \$140k',
        'requiredSkills': goalReq,
        'missingSkills': missing.isEmpty ? ['Advanced Optimization', 'Enterprise Testing'] : missing,
        'estimatedLearningMonths': 4,
        'description': 'Directly aligned with your explicit goal of becoming a $goalTitle. Capitalizes on your skills in ${cleanLearned.take(2).join(", ")}.'
      });
    }

    // 2. Score pre-defined domains against user's specific skills
    for (final dom in domains) {
      final title = dom['title'] as String;
      if (generatedCareers.any((c) => (c['title'] as String).toLowerCase() == title.toLowerCase())) {
        continue;
      }

      final keywords = dom['keywords'] as List<String>;
      final required = dom['required'] as List<String>;

      int matchCount = 0;
      for (final kw in keywords) {
        if (allUserSkills.any((sk) => sk.contains(kw) || kw.contains(sk))) {
          matchCount++;
        }
      }

      final baseScore = 70 + (matchCount * 7).clamp(0, 25);
      final missing = required.where((r) => !allUserSkills.contains(r.toLowerCase())).toList();

      generatedCareers.add({
        'title': title,
        'fitScore': baseScore,
        'demandIndicator': dom['demand'],
        'salaryRange': dom['salary'],
        'requiredSkills': required,
        'missingSkills': missing.isEmpty ? [required.last] : missing,
        'estimatedLearningMonths': (3 + missing.length).clamp(3, 9),
        'description': dom['desc'],
      });
    }

    // Sort by fitScore descending and pick top 4
    generatedCareers.sort((a, b) => (b['fitScore'] as int).compareTo(a['fitScore'] as int));
    final finalCareers = generatedCareers.take(4).toList();

    // ── Build Personalized Summary, Strengths, Growth ────────────────────
    final summaryText = cleanLearned.isNotEmpty || cleanTeaching.isNotEmpty
        ? 'Based on your experience in teaching ${cleanTeaching.isNotEmpty ? cleanTeaching.join(", ") : "peer skills"} and learning ${cleanLearned.isNotEmpty ? cleanLearned.join(", ") : "new domains"}, you are uniquely positioned for roles matching ${finalCareers.first['title']}.'
        : 'Based on your profile and swap activity, you show strong potential in ${finalCareers.first['title']} and related modern technical domains.';

    final strengths = <String>[
      if (cleanTeaching.isNotEmpty) 'Proven mentorship & teaching experience in ${cleanTeaching.join(", ")}',
      if (cleanLearned.isNotEmpty) 'Active skill acquisition in ${cleanLearned.join(", ")}',
      if (completedSwaps > 0) 'Demonstrated commitment with $completedSwaps completed peer swaps',
      if (averageRating > 0) 'Strong community rating of ${averageRating.toStringAsFixed(1)}/5.0',
      if (cleanInterests.isNotEmpty) 'Passionate interest in ${cleanInterests.take(2).join(" & ")}',
    ];
    if (strengths.isEmpty) {
      strengths.add('High motivation for peer learning and skill sharing');
      strengths.add('Strong problem solving and communication capacity');
    }

    final topMissing = finalCareers.expand((c) => c['missingSkills'] as List<String>).toSet().take(3).toList();
    final growth = topMissing.isNotEmpty
        ? topMissing.map((m) => 'Building practical competency in $m').toList()
        : ['Deepening practical project experience', 'Mastering enterprise architecture patterns', 'Building production portfolio apps'];

    return {
      'careerSummary': summaryText,
      'strengthAreas': strengths.take(3).toList(),
      'growthAreas': growth.take(3).toList(),
      'careers': finalCareers,
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
    final cleanMissing = missingSkills.where((s) => s.isNotEmpty).toList();
    final effectiveMissing = cleanMissing.isNotEmpty
        ? cleanMissing
        : ['Core Fundamentals of $targetCareer', 'Practical Project Implementation', 'Advanced Optimization'];

    final primaryMissing = effectiveMissing.first;
    final secondaryMissing = effectiveMissing.length > 1 ? effectiveMissing[1] : 'Advanced Architecture';

    final cleanCurrent = currentSkills.where((s) => s.isNotEmpty).toList();
    final currentSkillText = cleanCurrent.isNotEmpty ? cleanCurrent.join(', ') : 'Fundamentals';

    return {
      'targetCareer': targetCareer,
      'estimatedMonths': (effectiveMissing.length + 3).clamp(4, 9),
      'aiInsight': 'You have completed $completedSwaps peer swaps with a rating of ${averageRating > 0 ? averageRating.toStringAsFixed(1) : "5.0"}. Focus on mastering $primaryMissing to become fully job-ready for $targetCareer!',
      'stages': [
        {
          'stageNumber': 1,
          'stageName': 'Foundations & Core Setup for $targetCareer',
          'description': 'Establish your environment, master syntax, and build initial baseline projects.',
          'estimatedWeeks': 4,
          'completionPercent': 0,
          'tasks': [
            {
              'id': 't1_1',
              'title': 'Set up development workspace for $targetCareer',
              'description': 'Install essential tools, SDKs, and configure key developer extensions.',
              'estimatedHours': 4,
              'isCompleted': false
            },
            {
              'id': 't1_2',
              'title': 'Master fundamental syntax & principles',
              'description': 'Complete foundational exercises incorporating $currentSkillText.',
              'estimatedHours': 10,
              'isCompleted': false
            },
            {
              'id': 't1_3',
              'title': 'Build starter $targetCareer prototype',
              'description': 'Create a basic standalone project demonstrating core mechanics.',
              'estimatedHours': 8,
              'isCompleted': false
            }
          ],
          'resources': [
            {
              'id': 'r1_1',
              'title': 'Official $targetCareer Documentation & Guides',
              'platform': 'Official Site',
              'url': 'https://google.com/search?q=${Uri.encodeComponent("$targetCareer documentation")}',
              'type': 'Documentation',
              'learnersCount': 45000
            },
            {
              'id': 'r1_2',
              'title': '$targetCareer Beginner Fundamentals Course',
              'platform': 'YouTube / Coursera',
              'url': 'https://youtube.com/results?search_query=${Uri.encodeComponent("$targetCareer tutorial")}',
              'type': 'Video',
              'learnersCount': 28000
            }
          ]
        },
        {
          'stageNumber': 2,
          'stageName': 'Core Competency: $primaryMissing',
          'description': 'Deep dive into $primaryMissing and apply concepts through hands-on practice.',
          'estimatedWeeks': 5,
          'completionPercent': 0,
          'tasks': [
            {
              'id': 't2_1',
              'title': 'Learn key patterns for $primaryMissing',
              'description': 'Study industry best practices and core architectural patterns.',
              'estimatedHours': 12,
              'isCompleted': false
            },
            {
              'id': 't2_2',
              'title': 'Integrate $primaryMissing into real application',
              'description': 'Connect backend or data services to demonstrate end-to-end functionality.',
              'estimatedHours': 14,
              'isCompleted': false
            },
            {
              'id': 't2_3',
              'title': 'Log peer learning sessions',
              'description': 'Schedule a SkillSwap session to practice or receive feedback on $primaryMissing.',
              'estimatedHours': 5,
              'isCompleted': false
            }
          ],
          'resources': [
            {
              'id': 'r2_1',
              'title': 'Mastering $primaryMissing Deep Dive',
              'platform': 'Udemy / Medium',
              'url': 'https://google.com/search?q=${Uri.encodeComponent("$primaryMissing tutorial")}',
              'type': 'Course',
              'learnersCount': 32000
            }
          ]
        },
        {
          'stageNumber': 3,
          'stageName': 'Practical Project & Peer Swaps',
          'description': 'Expand skills into $secondaryMissing and build a portfolio-worthy project.',
          'estimatedWeeks': 6,
          'completionPercent': 0,
          'tasks': [
            {
              'id': 't3_1',
              'title': 'Implement $secondaryMissing module',
              'description': 'Add advanced features, data persistence, or state management.',
              'estimatedHours': 15,
              'isCompleted': false
            },
            {
              'id': 't3_2',
              'title': 'Conduct peer code / design review',
              'description': 'Share repository or project deliverables with a SkillSwap peer for feedback.',
              'estimatedHours': 6,
              'isCompleted': false
            },
            {
              'id': 't3_3',
              'title': 'Publish project repository / case study',
              'description': 'Document code, architecture, and live demo link on GitHub or portfolio.',
              'estimatedHours': 8,
              'isCompleted': false
            }
          ],
          'resources': [
            {
              'id': 'r3_1',
              'title': 'Building Production-Ready $targetCareer Projects',
              'platform': 'GitHub / FreeCodeCamp',
              'url': 'https://google.com/search?q=${Uri.encodeComponent("$targetCareer github project guide")}',
              'type': 'Guide',
              'learnersCount': 50000
            }
          ]
        },
        {
          'stageNumber': 4,
          'stageName': 'Advanced Architecture & Optimization',
          'description': 'Refine code quality, automated testing, security, and performance.',
          'estimatedWeeks': 4,
          'completionPercent': 0,
          'tasks': [
            {
              'id': 't4_1',
              'title': 'Implement unit and integration testing',
              'description': 'Automate test suites to ensure zero regression and high code coverage.',
              'estimatedHours': 10,
              'isCompleted': false
            },
            {
              'id': 't4_2',
              'title': 'Optimize performance & memory footprint',
              'description': 'Profile application metrics, optimize latency, and harden security.',
              'estimatedHours': 8,
              'isCompleted': false
            }
          ],
          'resources': [
            {
              'id': 'r4_1',
              'title': 'Advanced $targetCareer System Architecture',
              'platform': 'Tech Blog',
              'url': 'https://google.com/search?q=${Uri.encodeComponent("$targetCareer architecture best practices")}',
              'type': 'Article',
              'learnersCount': 19000
            }
          ]
        },
        {
          'stageNumber': 5,
          'stageName': 'Mastery & Peer Mentorship',
          'description': 'Transition from learner to mentor and lead skill swaps in $targetCareer.',
          'estimatedWeeks': 4,
          'completionPercent': 0,
          'tasks': [
            {
              'id': 't5_1',
              'title': 'Create teaching listing for $targetCareer',
              'description': 'Post an offering on SkillSwap to mentor peers in basic $targetCareer concepts.',
              'estimatedHours': 4,
              'isCompleted': false
            },
            {
              'id': 't5_2',
              'title': 'Complete mock interview & portfolio review',
              'description': 'Review technical questions and prepare portfolio presentation for target roles.',
              'estimatedHours': 8,
              'isCompleted': false
            }
          ],
          'resources': [
            {
              'id': 'r5_1',
              'title': '$targetCareer Interview & Career Handbook',
              'platform': 'LeetCode / Interviewing.io',
              'url': 'https://google.com/search?q=${Uri.encodeComponent("$targetCareer interview prep")}',
              'type': 'Book',
              'learnersCount': 62000
            }
          ]
        }
      ],
      'milestones': [
        {
          'id': 'm1',
          'title': 'Workspace & Fundamentals Ready',
          'description': 'Environment configured and initial $targetCareer starter project running.',
          'stageNumber': 1,
          'icon': 'school',
          'isCompleted': false
        },
        {
          'id': 'm2',
          'title': '$primaryMissing Competency Verified',
          'description': 'Successfully implemented $primaryMissing in a functional project.',
          'stageNumber': 2,
          'icon': 'star',
          'isCompleted': false
        },
        {
          'id': 'm3',
          'title': 'Portfolio Project Published',
          'description': 'Complete application with $secondaryMissing published and reviewed.',
          'stageNumber': 3,
          'icon': 'verified',
          'isCompleted': false
        },
        {
          'id': 'm4',
          'title': 'Production Optimization Complete',
          'description': 'Automated test suite passing and architecture optimized.',
          'stageNumber': 4,
          'icon': 'speed',
          'isCompleted': false
        },
        {
          'id': 'm5',
          'title': 'Community Mentor Status',
          'description': 'Hosting skill swaps and mentoring peers in $targetCareer.',
          'stageNumber': 5,
          'icon': 'military_tech',
          'isCompleted': false
        }
      ]
    };
  }
}

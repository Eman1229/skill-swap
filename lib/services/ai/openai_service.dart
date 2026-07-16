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
  // Paste your OpenAI API Key here if you don't have the Firebase Blaze plan:

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
  }) async {
    if (_useDirectOpenAI) {
      final apiKey = _getApiKey;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      // Fetch user specific data like interests & profileSummary
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      final List<String> interests = List<String>.from(userData['interests'] ?? []);
      final String profileSummary = userData['profileSummary']?.toString() ?? '';

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
          "Recent Swap History: None yet\n\n"
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
      );

      if (response.statusCode != 200) {
        throw Exception('OpenAI API error: ${response.body}');
      }

      final jsonResult = jsonDecode(response.body);
      final content = jsonResult['choices'][0]['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;

      // Save directly to Firestore collection matching backend schema
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

      debugPrint('[Direct OpenAI] Career recommendation successfully generated and saved to Firestore.');
      return resultData;
    }

    return _callFunction(
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
      },
      timeout: const Duration(seconds: 90),
    );
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
  }) async {
    if (_useDirectOpenAI) {
      final apiKey = _getApiKey;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      final List<String> interests = List<String>.from(userData['interests'] ?? []);

      final systemPrompt = "You are a personalized learning roadmap AI.\n"
          "Create structured, actionable learning roadmaps for skill-based learners.\n"
          "Always respond with valid JSON only — no markdown, no code blocks.";

      final userPrompt = "Create a personalized learning roadmap for:\n\n"
          "Target Career: $targetCareer\n"
          "Current Skills: ${currentSkills.join(', ').isNotEmpty ? currentSkills.join(', ') : 'Beginner'}\n"
          "Skills to Learn: ${missingSkills.join(', ')}\n"
          "Interests: ${interests.join(', ').isNotEmpty ? interests.join(', ') : 'Not specified'}\n"
          "Recent Swap History: None yet\n"
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
      );

      if (response.statusCode != 200) {
        throw Exception('OpenAI API error: ${response.body}');
      }

      final jsonResult = jsonDecode(response.body);
      final content = jsonResult['choices'][0]['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;

      // Save directly to Firestore collection matching backend schema
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

      debugPrint('[Direct OpenAI] Learning roadmap successfully generated and saved to Firestore.');
      return resultData;
    }

    return _callFunction(
      'generateLearningRoadmap',
      {
        'targetCareer': targetCareer,
        'currentSkills': currentSkills,
        'missingSkills': missingSkills,
        'learningHours': learningHours,
        'completedSwaps': completedSwaps,
        'averageRating': averageRating,
      },
      timeout: const Duration(seconds: 90),
    );
  }
}

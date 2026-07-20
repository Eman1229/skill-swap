// functions/career_compass.js
// Cloud Function: Career Compass — GPT-4o-mini Career Guidance
//
// Deployed as: generateCareerRecommendation (HTTPS Callable)

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');

const secretClient = new SecretManagerServiceClient();
let _cachedKey = null;

async function getOpenAiKey() {
  if (_cachedKey) return _cachedKey;
  if (process.env.OPENAI_API_KEY) {
    _cachedKey = process.env.OPENAI_API_KEY.trim();
    return _cachedKey;
  }
  const [version] = await secretClient.accessSecretVersion({
    name: 'projects/' + process.env.GCLOUD_PROJECT + '/secrets/openai-api-key/versions/latest',
  });
  _cachedKey = version.payload.data.toString('utf8').trim();
  return _cachedKey;
}

/**
 * Callable: generateCareerRecommendation
 * Request: {
 *   userId: string,
 *   skillsLearned: string[],
 *   skillsTeaching: string[],
 *   completedSwaps: number,
 *   averageRating: number,
 *   learningHours: number,
 *   teachingHours: number,
 *   learningStreak: number,
 *   totalAchievements: number,
 *   successRate: number,
 *   careerGoal: string | null
 * }
 * Response: { careers: CareerPath[], strengthAreas: string[], growthAreas: string[], careerSummary: string }
 */
async function generateCareerRecommendationForUser(userId, input = {}, options = {}) {
  const db = admin.firestore();
  const today = new Date().toISOString().slice(0, 10);

  if (!options.skipRateLimit) {
    const usageRef = db.collection('ai_usage_logs').where('userId', '==', userId)
      .where('type', '==', 'career_generation').where('date', '==', today);
    const usageSnap = await usageRef.get();
    if (usageSnap.size >= 5) {
      throw new functions.https.HttpsError('resource-exhausted', 'Daily career generation limit reached.');
    }
  }

  const {
    skillsLearned = [],
    skillsTeaching = [],
    interests = [],
    profileSummary = '',
    completedSwaps = 0,
    averageRating = 0,
    learningHours = 0,
    teachingHours = 0,
    learningStreak = 0,
    totalAchievements = 0,
    successRate = 0,
    careerGoal = null,
    recentSwapHistory = [],
    trigger = 'manual',
    triggerId = null,
  } = input;

    const systemPrompt = `You are a career guidance AI specializing in skill-based career matching.
Analyze the user's learning profile and generate personalized career path recommendations.
Always respond with valid JSON only — no markdown, no code blocks.`;

    const userPrompt = `Analyze this learner profile and recommend career paths:

Skills Learned: ${skillsLearned.join(', ') || 'None yet'}
Skills Teaching: ${skillsTeaching.join(', ') || 'None yet'}
Interests: ${interests.join(', ') || 'Not specified'}
Profile Summary: ${profileSummary || 'Not specified'}
Completed Swaps: ${completedSwaps}
Average Rating: ${averageRating.toFixed(1)}/5.0
Learning Hours: ${learningHours.toFixed(1)}
Teaching Hours: ${teachingHours.toFixed(1)}
Learning Streak: ${learningStreak} days
Total Achievements: ${totalAchievements}
Success Rate: ${(successRate * 100).toFixed(0)}%
Career Goal: ${careerGoal || 'Not specified'}
Recent Swap History: ${recentSwapHistory.length ? recentSwapHistory.join(' | ') : 'None yet'}

Return ONLY this JSON structure (no other text):
{
  "careerSummary": "2-3 sentence personalized career summary",
  "strengthAreas": ["area1", "area2", "area3"],
  "growthAreas": ["area1", "area2", "area3"],
  "careers": [
    {
      "title": "Career Title",
      "fitScore": 92,
      "demandIndicator": "High",
      "salaryRange": "$60k - $90k",
      "requiredSkills": ["skill1", "skill2", "skill3"],
      "missingSkills": ["skill1", "skill2"],
      "estimatedLearningMonths": 6,
      "description": "Brief role description"
    }
  ]
}

Generate 4-5 career paths. fitScore 0-100. demandIndicator: "High", "Medium", or "Low".`;

  const apiKey = await getOpenAiKey();
  const fetchFn = typeof globalThis.fetch === 'function' ? globalThis.fetch : (...args) => import('node-fetch').then(({ default: f }) => f(...args));

  const response = await fetchFn('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      temperature: 0.7,
      max_tokens: 1500,
      response_format: { type: 'json_object' },
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    console.error('OpenAI career error:', err);
    throw new functions.https.HttpsError('internal', 'OpenAI API error.');
  }

  const json = await response.json();
  const content = json.choices?.[0]?.message?.content;
  if (!content) throw new functions.https.HttpsError('internal', 'Empty response from AI.');

  let parsed;
  try {
    parsed = JSON.parse(content);
  } catch (e) {
    throw new functions.https.HttpsError('internal', 'Invalid JSON from AI.');
  }

  const timestamp = admin.firestore.FieldValue.serverTimestamp();
  const docId = Date.now().toString();
  await db.collection('career_recommendations').doc(userId).collection('history').doc(docId).set({
    ...parsed,
    userId,
    createdAt: timestamp,
    version: 1,
    trigger,
    triggerId,
    triggerData: {
      skillsLearned,
      skillsTeaching,
      interests,
      completedSwaps,
      averageRating,
      recentSwapHistory,
    },
  });

  await db.collection('career_recommendations').doc(userId).set({
    latestId: docId,
    updatedAt: timestamp,
  }, { merge: true });

  await db.collection('ai_usage_logs').add({
    type: 'career_generation',
    userId,
    date: today,
    tokenCount: json.usage?.total_tokens ?? 0,
    trigger,
    triggerId,
    createdAt: timestamp,
  });

  return { ...parsed, id: docId };
}

exports.generateCareerRecommendationForUser = generateCareerRecommendationForUser;

exports.generateCareerRecommendation = functions
  .runWith({ timeoutSeconds: 120, memory: '256MB' })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    }

    return generateCareerRecommendationForUser(context.auth.uid, data);
  });

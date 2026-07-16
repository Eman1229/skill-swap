// functions/learning_roadmap.js
// Cloud Function: Learning Roadmap — GPT-4o-mini Personalized Roadmap Generation
//
// Deployed as: generateLearningRoadmap (HTTPS Callable)

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
 * Callable: generateLearningRoadmap
 * Request: {
 *   targetCareer: string,
 *   currentSkills: string[],
 *   missingSkills: string[],
 *   learningHours: number,
 *   completedSwaps: number,
 *   averageRating: number
 * }
 */
async function generateLearningRoadmapForUser(userId, input = {}) {
  const db = admin.firestore();

  const {
    targetCareer = 'Software Developer',
    currentSkills = [],
    missingSkills = [],
    interests = [],
    recentSwapHistory = [],
    learningHours = 0,
    completedSwaps = 0,
    averageRating = 0,
    trigger = 'manual',
    triggerId = null,
  } = input;

    const systemPrompt = `You are a personalized learning roadmap AI.
Create structured, actionable learning roadmaps for skill-based learners.
Always respond with valid JSON only — no markdown, no code blocks.`;

    const userPrompt = `Create a personalized learning roadmap for:

Target Career: ${targetCareer}
Current Skills: ${currentSkills.join(', ') || 'Beginner'}
Skills to Learn: ${missingSkills.join(', ')}
Interests: ${interests.join(', ') || 'Not specified'}
Recent Swap History: ${recentSwapHistory.length ? recentSwapHistory.join(' | ') : 'None yet'}
Learning Hours So Far: ${learningHours.toFixed(0)}
Completed Swaps: ${completedSwaps}
Average Rating: ${averageRating.toFixed(1)}/5.0

Return ONLY this JSON structure:
{
  "targetCareer": "${targetCareer}",
  "estimatedMonths": 8,
  "aiInsight": "1 sentence motivational insight about their progress",
  "stages": [
    {
      "stageNumber": 1,
      "stageName": "Foundation",
      "description": "Short stage description",
      "estimatedWeeks": 4,
      "completionPercent": 0,
      "tasks": [
        {
          "id": "t1_1",
          "title": "Task title",
          "description": "Short task description",
          "estimatedHours": 3,
          "isCompleted": false
        }
      ],
      "resources": [
        {
          "id": "r1_1",
          "title": "Resource title",
          "platform": "Platform name",
          "url": "https://example.com",
          "type": "Course",
          "learnersCount": 12500
        }
      ]
    }
  ],
  "milestones": [
    {
      "id": "m1",
      "title": "Milestone title",
      "description": "Short description",
      "stageNumber": 1,
      "icon": "school",
      "isCompleted": false
    }
  ]
}

Create exactly 5 stages: Foundation, Skill Building, Real World Practice, Grow & Lead, Become Mentor.
Each stage: 3-5 tasks, 2-3 resources, 1 milestone.`;

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
      max_tokens: 3000,
      response_format: { type: 'json_object' },
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    console.error('OpenAI roadmap error:', err);
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

  await db.collection('learning_roadmaps').doc(userId).collection('history').doc(docId).set({
    ...parsed,
    userId,
    createdAt: timestamp,
    version: 1,
    trigger,
    triggerId,
    triggerData: {
      currentSkills,
      missingSkills,
      interests,
      completedSwaps,
      averageRating,
      recentSwapHistory,
    },
  });

  const batch = db.batch();
  (parsed.stages || []).forEach((stage) => {
    const stepRef = db.collection('roadmap_steps').doc(userId).collection('steps').doc(`stage_${stage.stageNumber}`);
    batch.set(stepRef, {
      ...stage,
      userId,
      roadmapId: docId,
      createdAt: timestamp,
    }, { merge: false });
  });
  await batch.commit();

  await db.collection('roadmap_progress').doc(userId).set({
    currentStage: 1,
    currentRoadmapId: docId,
    completedTaskIds: [],
    completedMilestoneIds: [],
    overallPercent: 0,
    updatedAt: timestamp,
  }, { merge: true });

  await db.collection('learning_roadmaps').doc(userId).set({
    latestId: docId,
    targetCareer,
    updatedAt: timestamp,
  }, { merge: true });

  const today = new Date().toISOString().slice(0, 10);
  await db.collection('ai_usage_logs').add({
    type: 'roadmap_generation',
    userId,
    date: today,
    tokenCount: json.usage?.total_tokens ?? 0,
    trigger,
    triggerId,
    createdAt: timestamp,
  });

  return { ...parsed, id: docId };
}

exports.generateLearningRoadmapForUser = generateLearningRoadmapForUser;

exports.generateLearningRoadmap = functions
  .runWith({ timeoutSeconds: 120, memory: '256MB' })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    }

    return generateLearningRoadmapForUser(context.auth.uid, data);
  });

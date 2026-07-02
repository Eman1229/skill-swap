// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
if (!admin.apps.length) {
  admin.initializeApp();
}
const { sendSwapProposalNotification } = require('./sendSwapProposalNotification');
const { sendDirectMessageNotification } = require('./sendDirectMessageNotification');
const { sendWeeklyTips } = require('./sendWeeklyTips');

// ── AI Recommendation Ecosystem ────────────────────────────────────────
const { getEmbedding } = require('./ai_proxy');
const {
  generateCareerRecommendation,
  generateCareerRecommendationForUser,
} = require('./career_compass');
const {
  generateLearningRoadmap,
  generateLearningRoadmapForUser,
} = require('./learning_roadmap');
exports.getEmbedding = getEmbedding;
exports.generateCareerRecommendation = generateCareerRecommendation;
exports.generateLearningRoadmap = generateLearningRoadmap;
// ──────────────────────────────────────────────────────────────────────

const db = admin.firestore();
const fieldValue = admin.firestore.FieldValue;
const DEFAULT_TOTAL_SESSIONS = 8;

function text(value) {
  return (value || '').toString().trim();
}

function exchangeIdFor(requestId, data) {
  return text(data.exchangeId) || text(data.requestId) || requestId;
}

function swapKey(data) {
  const mentorId = text(data.mentorId);
  const learnerId = text(data.learnerId);
  const skillName = text(data.skillName).toLowerCase();
  if (!mentorId || !learnerId || !skillName) return '';
  return `${mentorId}|${learnerId}|${skillName}`;
}

function completed(data) {
  return text(data.status).toLowerCase() === 'completed' || Number(data.progress || 0) >= 1;
}

function number(data, field, fallback = 0) {
  const value = Number(data[field]);
  return Number.isFinite(value) ? value : fallback;
}

function list(value) {
  if (Array.isArray(value)) return value.map(text).filter(Boolean);
  if (typeof value === 'string') {
    return value.split(',').map(text).filter(Boolean);
  }
  return [];
}

function unique(values) {
  return Array.from(new Set(values.map(text).filter(Boolean)));
}

async function createMissingSwapPair(requestId, request) {
  const senderId = text(request.senderId);
  const receiverId = text(request.receiverId);
  const offeredSkill = text(request.offeredSkill);
  const requestedSkill = text(request.requestedSkill);
  if (!senderId || !receiverId || !offeredSkill || !requestedSkill || senderId === receiverId) {
    return;
  }

  const existing = await db.collection('swaps').where('requestId', '==', requestId).get();
  const existingKeys = new Set(existing.docs.map((doc) => swapKey(doc.data())).filter(Boolean));
  const participants = [senderId, receiverId];
  const batch = db.batch();
  let writes = 0;

  const senderSwap = {
    mentorId: senderId,
    learnerId: receiverId,
    mentorName: text(request.senderName),
    learnerName: text(request.receiverName),
    skillName: offeredSkill,
    status: 'ongoing',
    progress: 0,
    conversationId: text(request.conversationId),
    completedSessions: 0,
    totalSessions: DEFAULT_TOTAL_SESSIONS,
    participants,
    createdAt: fieldValue.serverTimestamp(),
    requestId,
    exchangeId: requestId,
    exchangeRole: 'sender_teaches',
  };
  if (!existingKeys.has(swapKey(senderSwap))) {
    batch.set(db.collection('swaps').doc(`${requestId}_${senderId}_teaches`), senderSwap, { merge: true });
    writes++;
  }

  const receiverSwap = {
    mentorId: receiverId,
    learnerId: senderId,
    mentorName: text(request.receiverName),
    learnerName: text(request.senderName),
    skillName: requestedSkill,
    status: 'ongoing',
    progress: 0,
    conversationId: text(request.conversationId),
    completedSessions: 0,
    totalSessions: DEFAULT_TOTAL_SESSIONS,
    participants,
    createdAt: fieldValue.serverTimestamp(),
    requestId,
    exchangeId: requestId,
    exchangeRole: 'receiver_teaches',
  };
  if (!existingKeys.has(swapKey(receiverSwap))) {
    batch.set(db.collection('swaps').doc(`${requestId}_${receiverId}_teaches`), receiverSwap, { merge: true });
    writes++;
  }

  if (writes > 0) await batch.commit();
  await Promise.all(participants.map(syncUserProfileSkills));
}

async function syncUserProfileSkills(uid) {
  if (!uid) return;
  const snap = await db.collection('swaps').where('participants', 'array-contains', uid).get();
  const pairs = new Map();

  snap.docs.forEach((doc) => {
    const data = { id: doc.id, ...doc.data() };
    if (!text(data.mentorId) || !text(data.learnerId) || !text(data.skillName)) return;
    if (text(data.status).toLowerCase() === 'cancelled' || text(data.status).toLowerCase() === 'rejected') return;
    if (!completed(data)) return;
    const exchangeId = exchangeIdFor(doc.id, data);
    if (!pairs.has(exchangeId)) pairs.set(exchangeId, []);
    pairs.get(exchangeId).push(data);
  });

  const learning = new Set();
  const teaching = new Set();
  const completedExchangeIds = new Set();

  pairs.forEach((pair, exchangeId) => {
    const learned = pair
      .filter((swap) => text(swap.learnerId) === uid)
      .map((swap) => text(swap.skillName))
      .filter(Boolean);
    const taught = pair
      .filter((swap) => text(swap.mentorId) === uid)
      .map((swap) => text(swap.skillName))
      .filter(Boolean);
    if (learned.length && taught.length) {
      learning.add(learned[0]);
      teaching.add(taught[0]);
      completedExchangeIds.add(exchangeId);
    }
  });

  const learningList = Array.from(learning).sort();
  const teachingList = Array.from(teaching).sort();
  const balancedCount = Math.min(learningList.length, teachingList.length);

  await db.collection('users').doc(uid).set({
    learningSkills: learningList.slice(0, balancedCount),
    teachingSkills: teachingList.slice(0, balancedCount),
    skillsLearnedCount: balancedCount,
    skillsTeachingCount: balancedCount,
    completedSwaps: completedExchangeIds.size,
    skillExchangeCount: balancedCount,
    skillStatsSyncedAt: fieldValue.serverTimestamp(),
  }, { merge: true });

  return {
    learningSkills: learningList.slice(0, balancedCount),
    teachingSkills: teachingList.slice(0, balancedCount),
    completedSwaps: completedExchangeIds.size,
  };
}

async function buildAIProfile(uid, seed = {}) {
  const [userDoc, listingsSnap, swapsSnap] = await Promise.all([
    db.collection('users').doc(uid).get(),
    db.collection('swapListings').where('userId', '==', uid).get(),
    db.collection('swaps').where('participants', 'array-contains', uid).get(),
  ]);

  const userData = userDoc.exists ? userDoc.data() : {};
  const learned = new Set(list(userData.learningSkills));
  const teaching = new Set(list(userData.teachingSkills));
  const interests = new Set([
    ...list(userData.interests),
    ...list(userData.interest),
    ...list(userData.skillsInterested),
    ...list(userData.careerInterests),
  ]);
  const recentSwapHistory = [];
  const completedExchangeIds = new Set();

  listingsSnap.docs.forEach((doc) => {
    const data = doc.data();
    list(data.wanting || data.wantedSkill || data.learningSkill || data.skillsWanted)
      .forEach((skill) => learned.add(skill));
    list(data.offering || data.offeredSkill || data.teachingSkill || data.skillsOffered)
      .forEach((skill) => teaching.add(skill));
    list(data.interests || data.tags || data.categories).forEach((item) => interests.add(item));
  });

  swapsSnap.docs.forEach((doc) => {
    const data = { id: doc.id, ...doc.data() };
    if (!completed(data)) return;

    const skill = text(data.skillName);
    if (!skill) return;

    const exchangeId = exchangeIdFor(doc.id, data);
    completedExchangeIds.add(exchangeId);

    if (text(data.learnerId) === uid) learned.add(skill);
    if (text(data.mentorId) === uid) teaching.add(skill);

    const role = text(data.learnerId) === uid ? 'learned' : 'taught';
    recentSwapHistory.push(`${role} ${skill}`);
  });

  const skillsLearned = unique([...(seed.learningSkills || []), ...learned]);
  const skillsTeaching = unique([...(seed.teachingSkills || []), ...teaching]);
  const profileSummary = [
    text(userData.name),
    text(userData.bio),
    text(userData.headline),
    text(userData.about),
    text(userData.location),
  ].filter(Boolean).join(' | ');

  const completedSwaps = Math.max(
    Number(seed.completedSwaps || 0),
    number(userData, 'completedSwaps'),
    completedExchangeIds.size,
  );
  const totalSessions = Math.max(number(userData, 'totalSessions', 1), completedSwaps, 1);

  return {
    skillsLearned,
    skillsTeaching,
    interests: unique([...interests]),
    profileSummary,
    completedSwaps,
    averageRating: number(userData, 'averageRating', number(userData, 'rating', 0)),
    learningHours: number(userData, 'learningHours'),
    teachingHours: number(userData, 'teachingHours'),
    learningStreak: number(userData, 'learningStreak'),
    totalAchievements: number(userData, 'totalAchievements', number(userData, 'unlockedBadges')),
    successRate: number(userData, 'successRate', completedSwaps / totalSessions),
    careerGoal: text(userData.careerGoal || userData.targetCareer || userData.goal) || null,
    recentSwapHistory: unique(recentSwapHistory).slice(0, 12),
  };
}

async function claimAICompletionGeneration(uid, exchangeId) {
  const lockRef = db.collection('ai_completion_generation_locks').doc(`${exchangeId}_${uid}`);
  return db.runTransaction(async (transaction) => {
    const snap = await transaction.get(lockRef);
    if (snap.exists) return false;
    transaction.set(lockRef, {
      uid,
      exchangeId,
      status: 'running',
      createdAt: fieldValue.serverTimestamp(),
    });
    return true;
  });
}

async function updateAICompletionGenerationLock(uid, exchangeId, data) {
  await db.collection('ai_completion_generation_locks').doc(`${exchangeId}_${uid}`).set({
    ...data,
    updatedAt: fieldValue.serverTimestamp(),
  }, { merge: true });
}

async function generateAIForCompletedSwap(uid, exchangeId, seed = {}) {
  if (!uid || !exchangeId) return;
  const claimed = await claimAICompletionGeneration(uid, exchangeId);
  if (!claimed) return;

  try {
    const profile = await buildAIProfile(uid, seed);
    if (!profile.skillsLearned.length && !profile.skillsTeaching.length && !profile.interests.length) {
      await updateAICompletionGenerationLock(uid, exchangeId, {
        status: 'skipped',
        reason: 'No profile skills or interests available.',
      });
      return;
    }

    const career = await generateCareerRecommendationForUser(uid, {
      ...profile,
      trigger: 'swap_completed',
      triggerId: exchangeId,
    }, { skipRateLimit: true });

    const topCareer = Array.isArray(career.careers) ? career.careers[0] : null;
    if (topCareer && text(topCareer.title)) {
      await generateLearningRoadmapForUser(uid, {
        targetCareer: topCareer.title,
        currentSkills: unique([...profile.skillsLearned, ...profile.skillsTeaching]),
        missingSkills: list(topCareer.missingSkills),
        interests: profile.interests,
        recentSwapHistory: profile.recentSwapHistory,
        learningHours: profile.learningHours,
        completedSwaps: profile.completedSwaps,
        averageRating: profile.averageRating,
        trigger: 'swap_completed',
        triggerId: exchangeId,
      });
    }

    await updateAICompletionGenerationLock(uid, exchangeId, {
      status: 'completed',
      careerRecommendationId: career.id || null,
      roadmapTargetCareer: topCareer?.title || null,
    });
  } catch (err) {
    console.error('AI completion generation failed:', uid, exchangeId, err);
    await updateAICompletionGenerationLock(uid, exchangeId, {
      status: 'failed',
      error: err.message || String(err),
    });
  }
}

// Trigger on swap request creation/updates
exports.swapProposalNotifier = functions.firestore
  .document('swap_requests/{requestId}')
  .onWrite(sendSwapProposalNotification);

// Trigger on new chat message
exports.directMessageNotifier = functions.firestore
  .document('chats/{chatId}/messages/{msgId}')
  .onCreate(sendDirectMessageNotification);

// Weekly tip scheduled function (triggered by Cloud Scheduler)
exports.weeklyTipNotifier = functions.pubsub.schedule('every Monday 09:00').timeZone('UTC').onRun(sendWeeklyTips);

exports.skillExchangeRequestGuard = functions
  .runWith({ timeoutSeconds: 540, memory: '512MB' })
  .firestore
  .document('swap_requests/{requestId}')
  .onWrite(async (change, context) => {
    if (!change.after.exists) return null;
    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.data();
    const status = text(after.status).toLowerCase();

    if (status === 'accepted' && (!before || text(before.status).toLowerCase() !== 'accepted')) {
      if (!text(after.senderId) ||
          !text(after.receiverId) ||
          !text(after.offeredSkill) ||
          !text(after.requestedSkill) ||
          text(after.senderId) === text(after.receiverId)) {
        await change.after.ref.update({
          status: 'rejected',
          syncError: 'A skill swap requires two users and two skills.',
          updatedAt: fieldValue.serverTimestamp(),
        });
        return null;
      }
      await createMissingSwapPair(context.params.requestId, after);
      return null;
    }

    if (['rejected', 'cancelled', 'completed'].includes(status)) {
      const participants = [text(after.senderId), text(after.receiverId)].filter(Boolean);
      const syncResults = await Promise.all(participants.map(syncUserProfileSkills));
      if (status === 'completed' && (!before || text(before.status).toLowerCase() !== 'completed')) {
        await Promise.all(participants.map((uid, index) => generateAIForCompletedSwap(
          uid,
          exchangeIdFor(context.params.requestId, after),
          syncResults[index] || {},
        )));
      }
    }
    return null;
  });

exports.skillExchangeProfileSync = functions
  .runWith({ timeoutSeconds: 540, memory: '512MB' })
  .firestore
  .document('swaps/{swapId}')
  .onWrite(async (change, context) => {
    const data = change.after.exists ? change.after.data() : change.before.data();
    const participants = Array.isArray(data.participants)
      ? data.participants
      : [text(data.mentorId), text(data.learnerId)];
    const participantIds = participants.filter(Boolean);
    const syncResults = await Promise.all(participantIds.map(syncUserProfileSkills));

    const beforeData = change.before.exists ? change.before.data() : null;
    const becameCompleted = change.after.exists &&
      completed(data) &&
      (!beforeData || !completed(beforeData));
    if (becameCompleted) {
      const exchangeId = exchangeIdFor(context.params.swapId, data);
      await Promise.all(participantIds.map((uid, index) => generateAIForCompletedSwap(
        uid,
        exchangeId,
        syncResults[index] || {},
      )));
    }
    return null;
  });

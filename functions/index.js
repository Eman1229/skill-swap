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
const { generateCareerRecommendation } = require('./career_compass');
const { generateLearningRoadmap } = require('./learning_roadmap');
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

exports.skillExchangeRequestGuard = functions.firestore
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
      await Promise.all([text(after.senderId), text(after.receiverId)].filter(Boolean).map(syncUserProfileSkills));
    }
    return null;
  });

exports.skillExchangeProfileSync = functions.firestore
  .document('swaps/{swapId}')
  .onWrite(async (change, context) => {
    const data = change.after.exists ? change.after.data() : change.before.data();
    const participants = Array.isArray(data.participants)
      ? data.participants
      : [text(data.mentorId), text(data.learnerId)];
    await Promise.all(participants.filter(Boolean).map(syncUserProfileSkills));
    return null;
  });

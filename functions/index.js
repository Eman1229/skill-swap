// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const { sendSwapProposalNotification } = require('./sendSwapProposalNotification');
const { sendDirectMessageNotification } = require('./sendDirectMessageNotification');
const { sendWeeklyTips } = require('./sendWeeklyTips');

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

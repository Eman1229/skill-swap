// sendSwapProposalNotification.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { getUserSettings, buildFcmPayload, log } = require('./utils');
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Triggered on write to swap_requests/{requestId}
 * Sends push notifications for various swap events (sent, accepted, rejected, completed).
 */
exports.sendSwapProposalNotification = async (change, context) => {
  const requestId = context.params.requestId;
  const after = change.after.exists ? change.after.data() : null;
  const before = change.before.exists ? change.before.data() : null;

  if (!after) {
    // Deleted request – nothing to do
    return null;
  }

  // Determine event type
  let eventType = null;
  if (!before) {
    eventType = 'sent';
  } else if (before.status !== after.status) {
    // status changed
    switch (after.status) {
      case 'accepted':
        eventType = 'accepted';
        break;
      case 'rejected':
        eventType = 'rejected';
        break;
      case 'completed':
        eventType = 'completed';
        break;
    }
  }

  if (!eventType) {
    // No relevant change
    return null;
  }

  const receiverId = after.receiverId; // the user who should be notified
  const senderId = after.senderId;

  // Fetch receiver's notification settings
  const settings = await getUserSettings(receiverId);
  if (!settings) {
    log(`No notification settings for user ${receiverId}`);
    return null;
  }

  if (!settings.pushEnabled || !settings.swapProposalEnabled) {
    log(`User ${receiverId} disabled swap proposal notifications`);
    return null;
  }

  // Build notification content
  const titles = {
    sent: 'New Swap Proposal',
    accepted: 'Swap Accepted',
    rejected: 'Swap Rejected',
    completed: 'Swap Completed',
  };
  const bodies = {
    sent: `${after.senderName} sent you a swap proposal`,
    accepted: `Your swap request was accepted`,
    rejected: `Your swap request was rejected`,
    completed: `Swap request completed`,
  };

  const payload = {
    title: titles[eventType],
    body: bodies[eventType],
    actionRoute: '/swap/${requestId}',
    relatedId: requestId,
    type: 'swap_proposal',
    channelId: 'high_importance',
  };

  // Retrieve receiver's device token(s)
  const tokenSnap = await admin.firestore()
      .collection('users')
      .doc(receiverId)
      .collection('deviceTokens')
      .where('platform', '==', 'android')
      .get();

  const promises = [];
  tokenSnap.forEach(doc => {
    const token = doc.id; // token stored as document ID
    const fcmPayload = buildFcmPayload({
      fcmToken: token,
      title: payload.title,
      body: payload.body,
      actionRoute: payload.actionRoute,
      relatedId: payload.relatedId,
      type: payload.type,
      channelId: payload.channelId,
    });
    promises.push(admin.messaging().send(fcmPayload));
  });

  // Store a copy in the global notifications collection for in‑app display
  const notificationDoc = {
    senderId: senderId,
    receiverId: receiverId,
    type: 'swap_proposal',
    title: payload.title,
    body: payload.body,
    data: {
      requestId: requestId,
    },
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    actionRoute: payload.actionRoute,
    relatedId: payload.relatedId,
  };
  const notificationRef = admin.firestore().collection('notifications').doc();
  promises.push(notificationRef.set(notificationDoc));

  await Promise.all(promises);
  log(`Sent ${eventType} notification to user ${receiverId}`);
  return null;
};

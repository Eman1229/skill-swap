// sendSwapProposalNotification.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { log } = require('./utils');
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

  let notifyUserId = after.receiverId;
  let actionUserId = after.senderId;
  let actionUserName = after.senderName;
  if (eventType === 'accepted' || eventType === 'rejected' || eventType === 'completed') {
    // If accepted/rejected/completed, notify the original sender
    notifyUserId = after.senderId;
    actionUserId = after.receiverId;
    actionUserName = after.receiverName;
  }

  // Fetch receiver's notification settings from the user document
  const userDoc = await admin.firestore().collection('users').doc(notifyUserId).get();
  const flutterSettings = userDoc.exists ? (userDoc.data().notificationSettings || {}) : {};

  // Check if swap proposal notifications are enabled
  if (flutterSettings.swapRequests === false || flutterSettings.swapUpdates === false || flutterSettings.general === false) {
    log(`User ${notifyUserId} disabled swap proposal notifications in notificationSettings`);
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
    sent: `${actionUserName} sent you a swap proposal`,
    accepted: `${actionUserName} accepted your swap request`,
    rejected: `${actionUserName} rejected your swap request`,
    completed: `Swap request completed`,
  };

  const payload = {
    title: titles[eventType],
    body: bodies[eventType],
    actionRoute: `/swap/${requestId}`,
    relatedId: requestId,
    type: 'swap_request', // use swap_request so generalNotifier uses 'swap_requests' channel
  };

  // Store a copy in the global notifications collection for in‑app display
  // generalNotifier will pick this up and send the FCM payload
  const notificationDoc = {
    senderId: actionUserId,
    receiverId: notifyUserId,
    type: payload.type,
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
  
  await admin.firestore().collection('notifications').doc().set(notificationDoc);
  log(`Sent ${eventType} notification to user ${notifyUserId} via notifications collection`);
  return null;
};

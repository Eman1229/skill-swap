// utils.js
const admin = require('firebase-admin');
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Retrieves a user's notification settings document.
 * Returns null if document does not exist.
 */
async function getUserSettings(userId) {
  const doc = await admin.firestore().doc(`users/${userId}/settings/notifications`).get();
  return doc.exists ? doc.data() : null;
}

/**
 * Builds an FCM payload based on notification data.
 */
function buildFcmPayload(notification) {
  return {
    token: notification.fcmToken,
    data: {
      title: notification.title,
      body: notification.body,
      actionRoute: notification.actionRoute,
      relatedId: notification.relatedId,
      type: notification.type,
    },
    android: {
      priority: 'high',
      notification: {
        channelId: notification.channelId,
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        sound: 'default',
      },
    },
  };
}

/** Simple logger */
function log(message) {
  console.log(`[${new Date().toISOString()}] ${message}`);
}

module.exports = { getUserSettings, buildFcmPayload, log };

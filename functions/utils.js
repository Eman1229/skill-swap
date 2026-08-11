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
    notification: {
      title: notification.title ? String(notification.title) : '',
      body: notification.body ? String(notification.body) : '',
    },
    data: {
      title: notification.title ? String(notification.title) : '',
      body: notification.body ? String(notification.body) : '',
      actionRoute: notification.actionRoute ? String(notification.actionRoute) : '',
      relatedId: notification.relatedId ? String(notification.relatedId) : '',
      type: notification.type ? String(notification.type) : '',
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

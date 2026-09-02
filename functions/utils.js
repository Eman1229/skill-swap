const admin = require('firebase-admin');
if (!admin.apps.length) admin.initializeApp();

async function getUserSettings(userId) {
  const doc = await admin.firestore().doc(`users/${userId}/settings/notifications`).get();
  return doc.exists ? doc.data() : null;
}

function stringData(values = {}) {
  return Object.entries(values).reduce((result, [key, value]) => {
    if (value !== undefined && value !== null) result[key] = String(value);
    return result;
  }, {});
}

// Android displays this notification payload in background/terminated states.
// The Flutter client displays the same message locally only while foregrounded.
function buildFcmPayload(notification) {
  const channelId = notification.channelId || 'system';
  return {
    notification: { title: String(notification.title || 'SkillSwapX'), body: String(notification.body || '') },
    data: stringData({
      title: notification.title,
      body: notification.body,
      actionRoute: notification.actionRoute,
      relatedId: notification.relatedId,
      type: notification.type,
      channelId,
      ...notification.data,
    }),
    android: {
      priority: 'high',
      notification: {
        channelId,
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        sound: 'default',
        notificationPriority: 'PRIORITY_HIGH',
        visibility: 'PUBLIC',
      },
    },
  };
}

async function sendToUserDevices(userId, payload) {
  const userRef = admin.firestore().collection('users').doc(userId);
  const [userDoc, tokenDocs] = await Promise.all([userRef.get(), userRef.collection('deviceTokens').get()]);
  const tokens = new Set(tokenDocs.docs.map((doc) => doc.id));
  const fallback = userDoc.data()?.fcmToken;
  if (fallback) tokens.add(fallback);

  let sent = 0;
  await Promise.all([...tokens].map(async (token) => {
    try {
      await admin.messaging().send({ ...payload, token });
      sent++;
    } catch (error) {
      log(`FCM delivery failed for ${userId}: ${error.code || error.message}`);
      if (['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(error.code)) {
        await Promise.all([
          userRef.update({ fcmToken: admin.firestore.FieldValue.delete() }).catch(() => null),
          userRef.collection('deviceTokens').doc(token).delete().catch(() => null),
        ]);
      }
    }
  }));
  return { sent, tokens: tokens.size };
}

function log(message) { console.log(`[${new Date().toISOString()}] ${message}`); }

module.exports = { getUserSettings, buildFcmPayload, sendToUserDevices, log };

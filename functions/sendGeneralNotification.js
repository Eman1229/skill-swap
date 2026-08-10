const admin = require('firebase-admin');
const { getUserSettings, buildFcmPayload, log } = require('./utils');

if (!admin.apps.length) {
  admin.initializeApp();
}

function getChannelId(type) {
  switch (type) {
    case 'chat_message': return 'chat_messages';
    case 'swap_request': return 'swap_requests';
    case 'session': return 'sessions';
    case 'asset_upload': return 'sessions';
    case 'system': return 'system';
    case 'assignment': return 'sessions';
    default: return 'system';
  }
}

exports.sendGeneralNotification = async (snapshot, context) => {
  const notification = snapshot.data() || {};
  const receiverId = (notification.receiverId || '').toString();

  if (!receiverId) {
    log(`Could not resolve a valid receiverId for notification ${context.params.notificationId}`);
    return null;
  }

  // Retrieve receiver's settings
  const settings = await getUserSettings(receiverId);
  if (settings) {
    const pushEnabled = settings.pushEnabled !== false;
    if (!pushEnabled) {
      log(`User ${receiverId} disabled push notifications`);
      return null;
    }
  }

  const tokenSnap = await admin.firestore()
    .collection('users')
    .doc(receiverId)
    .collection('deviceTokens')
    .get();

  const title = (notification.title || 'Skill Swap').toString();
  const body = (notification.body || '').toString();
  
  const userDoc = await admin.firestore().collection('users').doc(receiverId).get();
  let fallbackToken = null;
  if (userDoc.exists) {
      fallbackToken = userDoc.data().fcmToken;
  }

  const sends = [];
  const tokensSent = new Set();

  tokenSnap.forEach((doc) => {
    const token = doc.id;
    if (!tokensSent.has(token)) {
      tokensSent.add(token);
      sends.push(admin.messaging().send(buildFcmPayload({
        fcmToken: token,
        title,
        body,
        actionRoute: notification.actionRoute || '',
        relatedId: notification.actionId || notification.referenceId || '',
        type: notification.type || 'system',
        channelId: getChannelId(notification.type),
      })));
    }
  });

  if (fallbackToken && !tokensSent.has(fallbackToken)) {
      sends.push(admin.messaging().send(buildFcmPayload({
        fcmToken: fallbackToken,
        title,
        body,
        actionRoute: notification.actionRoute || '',
        relatedId: notification.actionId || notification.referenceId || '',
        type: notification.type || 'system',
        channelId: getChannelId(notification.type),
      })));
  }

  await Promise.all(sends);
  return null;
};

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
  const notificationId = context.params.notificationId;
  const notification = snapshot.data() || {};
  const receiverId = (notification.receiverId || '').toString();

  log(`[generalNotifier] Triggered for notification ${notificationId}, receiver: ${receiverId}, type: ${notification.type}`);

  if (!receiverId) {
    log(`[generalNotifier] Error: Could not resolve a valid receiverId for notification ${notificationId}`);
    return null;
  }

  // Retrieve receiver's settings
  const settings = await getUserSettings(receiverId);
  if (settings) {
    const pushEnabled = settings.pushEnabled !== false;
    if (!pushEnabled) {
      log(`[generalNotifier] User ${receiverId} disabled push notifications`);
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
      if (fallbackToken) log(`[generalNotifier] Found fallback FCM token for user ${receiverId}`);
  } else {
      log(`[generalNotifier] Error: User document not found for receiver ${receiverId}`);
  }

  const sends = [];
  const tokensSent = new Set();

  tokenSnap.forEach((doc) => {
    const token = doc.id;
    if (!tokensSent.has(token)) {
      tokensSent.add(token);
      log(`[generalNotifier] Queuing push notification for deviceTokens token: ${token.substring(0, 15)}...`);
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
      tokensSent.add(fallbackToken);
      log(`[generalNotifier] Queuing push notification for fallback FCM token: ${fallbackToken.substring(0, 15)}...`);
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

  if (sends.length === 0) {
    log(`[generalNotifier] No FCM tokens found for user ${receiverId}`);
    return null;
  }

  try {
    const responses = await Promise.allSettled(sends);
    let successCount = 0;
    responses.forEach((res, idx) => {
      if (res.status === 'fulfilled') {
        successCount++;
      } else {
        log(`[generalNotifier] Failed to send push notification: ${res.reason}`);
      }
    });
    log(`[generalNotifier] Successfully sent ${successCount} out of ${sends.length} push notifications for ${notificationId}`);
  } catch (error) {
    log(`[generalNotifier] Critical error during Promise.allSettled: ${error}`);
  }
  
  return null;
};

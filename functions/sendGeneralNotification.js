const admin = require('firebase-admin');
const { getUserSettings, buildFcmPayload, log, sendToUserDevices } = require('./utils');

if (!admin.apps.length) {
  admin.initializeApp();
}

function getChannelId(type) {
  switch (type) {
    case 'chat_message': return 'chat_message';
    case 'swap_request': return 'swap_request';
    case 'session': return 'sessions';
    case 'asset_upload': return 'asset_upload';
    case 'system': return 'system';
    case 'assignment': return 'assignment';
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

  // ChatRepository creates the Firestore record for the in-app inbox and the
  // message trigger sends its push. Sending from both triggers duplicates the
  // Android notification.
  if (notification.type === 'chat_message') {
    log(`[generalNotifier] Skipping chat push for ${notificationId}; directMessageNotifier owns it.`);
    return null;
  }

  // Retrieve receiver's settings from the user document (Flutter app's format)
  const userDoc = await admin.firestore().collection('users').doc(receiverId).get();
  const flutterSettings = userDoc.exists ? (userDoc.data().notificationSettings || {}) : {};
  
  // Also check legacy settings for backwards compatibility
  const legacySettings = await getUserSettings(receiverId);
  
  let pushEnabled = true;
  if (legacySettings && legacySettings.pushEnabled === false) {
    pushEnabled = false;
  }
  if (flutterSettings.general === false) {
    pushEnabled = false; // Note: Flutter client usually filters prior to creating the notification, but this acts as a final safeguard
  }

  if (!pushEnabled) {
    log(`[generalNotifier] User ${receiverId} disabled push notifications`);
    return null;
  }

  const title = (notification.title || 'Skill Swap').toString();
  const body = (notification.body || '').toString();
  const result = await sendToUserDevices(receiverId, buildFcmPayload({
    title,
    body,
    actionRoute: notification.actionRoute || '',
    relatedId: notification.actionId || notification.referenceId || '',
    type: notification.type || 'system',
    channelId: getChannelId(notification.type),
    data: { notificationId, ...(notification.data || {}) },
  }));
  log(`[generalNotifier] Sent ${result.sent} of ${result.tokens} push notification(s) for ${notificationId}`);
  
  return null;
};

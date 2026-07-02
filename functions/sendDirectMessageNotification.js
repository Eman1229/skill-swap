const admin = require('firebase-admin');
const { getUserSettings, buildFcmPayload, log } = require('./utils');

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.sendDirectMessageNotification = async (snapshot, context) => {
  const message = snapshot.data() || {};
  const chatId = context.params.chatId;
  const senderId = (message.senderId || '').toString();
  const receiverId = (message.receiverId || message.recipientId || '').toString();

  if (!receiverId || senderId === receiverId) return null;

  const settings = await getUserSettings(receiverId);
  if (settings && (settings.pushEnabled === false || settings.messagesEnabled === false)) {
    log(`User ${receiverId} disabled message notifications`);
    return null;
  }

  const senderName = (message.senderName || 'Someone').toString();
  const body = (message.text || message.body || 'Sent you a message').toString();
  const tokenSnap = await admin.firestore()
    .collection('users')
    .doc(receiverId)
    .collection('deviceTokens')
    .get();

  const sends = [];
  tokenSnap.forEach((doc) => {
    sends.push(admin.messaging().send(buildFcmPayload({
      fcmToken: doc.id,
      title: `New message from ${senderName}`,
      body,
      actionRoute: '/chat',
      relatedId: chatId,
      type: 'message',
      channelId: 'high_importance',
    })));
  });

  await Promise.all(sends);
  return null;
};

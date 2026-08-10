const admin = require('firebase-admin');
const { getUserSettings, buildFcmPayload, log } = require('./utils');

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.sendDirectMessageNotification = async (snapshot, context) => {
  const message = snapshot.data() || {};
  
  // Skip session invites to avoid duplicate push notifications 
  // since they are handled by sendGeneralNotification via the notifications collection.
  if (message.type === 'session_invite') {
    return null;
  }

  const chatId = context.params.chatId;
  const senderId = (message.senderId || '').toString();

  // 1. Resolve receiver ID from parent conversation document if missing in message
  let receiverId = (message.receiverId || message.recipientId || '').toString();
  let conversationMuted = false;

  const convoDoc = await admin.firestore().collection('conversations').doc(chatId).get();
  if (convoDoc.exists) {
    const convoData = convoDoc.data() || {};
    if (!receiverId) {
      const participants = convoData.participants || [];
      receiverId = (participants.find(p => p !== senderId) || '').toString();
    }
    // Check if the specific conversation is muted for the receiver
    if (receiverId && convoData.muted && convoData.muted[receiverId] === true) {
      conversationMuted = true;
    }
  }

  if (!receiverId || senderId === receiverId) {
    log(`Could not resolve a valid receiverId or sender is receiver for chatId ${chatId}`);
    return null;
  }

  if (conversationMuted) {
    log(`Conversation ${chatId} is muted for user ${receiverId}`);
    return null;
  }

  // 2. Retrieve receiver's settings
  const settings = await getUserSettings(receiverId);
  if (settings) {
    const pushEnabled = settings.pushEnabled !== false;
    const directMessagesEnabled = settings.directMessagesEnabled !== false;
    const chatMessagesEnabled = settings.chatMessagesEnabled !== false;
    const messagesEnabled = settings.messagesEnabled !== false;
    const chatNotificationsMuted = settings.chatNotificationsMuted === true;

    if (!pushEnabled || !directMessagesEnabled || !chatMessagesEnabled || !messagesEnabled || chatNotificationsMuted) {
      log(`User ${receiverId} disabled or muted chat notifications`);
      return null;
    }
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

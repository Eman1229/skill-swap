const admin = require('firebase-admin');
const { getUserSettings, buildFcmPayload, log, sendToUserDevices } = require('./utils');

if (!admin.apps.length) admin.initializeApp();

// A chat message is the only source of chat push. Session invites are sent by
// generalNotifier when their notification document is created.
exports.sendDirectMessageNotification = async (snapshot, context) => {
  const message = snapshot.data() || {};
  if (message.type === 'session_invite') return null;

  const chatId = context.params.chatId;
  const senderId = String(message.senderId || '');
  let receiverId = String(message.receiverId || message.recipientId || '');
  const conversation = await admin.firestore().collection('conversations').doc(chatId).get();
  const conversationData = conversation.exists ? (conversation.data() || {}) : {};

  if (!receiverId) {
    receiverId = String((conversationData.participants || []).find((id) => id !== senderId) || '');
  }
  if (!receiverId || receiverId === senderId || conversationData.muted?.[receiverId] === true) return null;

  const settings = await getUserSettings(receiverId);
  if (settings && (settings.pushEnabled === false || settings.directMessagesEnabled === false ||
      settings.chatMessagesEnabled === false || settings.messagesEnabled === false ||
      settings.chatNotificationsMuted === true)) return null;

  const senderName = String(message.senderName || 'Someone');
  const body = String(message.text || message.body || 'Sent you a message');
  const result = await sendToUserDevices(receiverId, buildFcmPayload({
    title: `New message from ${senderName}`,
    body,
    actionRoute: '/chat',
    relatedId: chatId,
    type: 'chat_message',
    channelId: 'chat_message',
    data: { conversationId: chatId, senderId, senderName },
  }));
  log(`[directMessageNotifier] Sent chat push to ${result.sent} device(s) for ${chatId}`);
  return null;
};

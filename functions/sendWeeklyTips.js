const admin = require('firebase-admin');
const { buildFcmPayload, log } = require('./utils');

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.sendWeeklyTips = async () => {
  const usersSnap = await admin.firestore().collection('users').limit(500).get();
  const sends = [];

  usersSnap.forEach((userDoc) => {
    const uid = userDoc.id;
    sends.push((async () => {
      const settingsDoc = await admin.firestore()
        .doc(`users/${uid}/settings/notifications`)
        .get();
      const settings = settingsDoc.exists ? settingsDoc.data() : {};
      if (settings.pushEnabled === false || settings.weeklyTipsEnabled === false) return;

      const tokenSnap = await admin.firestore()
        .collection('users')
        .doc(uid)
        .collection('deviceTokens')
        .get();

      const userSends = [];
      tokenSnap.forEach((tokenDoc) => {
        userSends.push(admin.messaging().send(buildFcmPayload({
          fcmToken: tokenDoc.id,
          title: 'Weekly SkillSwapX Tip',
          body: 'Complete a swap this week to refresh your Career Compass and Learning Roadmap.',
          actionRoute: '/ai_recommendations',
          relatedId: uid,
          type: 'weekly_tip',
          channelId: 'high_importance',
        })));
      });
      await Promise.all(userSends);
    })());
  });

  await Promise.all(sends);
  log('Weekly tips job completed');
  return null;
};

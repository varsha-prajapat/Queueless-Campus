const sendNotification = async ({ title, message, userId, roles = [] }) => {
  // Get all FCM tokens for this user
  const userTokens = await FcmTokenModel.find({ userId }).lean();
  const tokens = userTokens.map((t) => t.fcmToken);

  if (tokens.length > 0) {
    await admin.messaging().sendMulticast({
      tokens,
      notification: { title, body: message },
    });
  }

  // Socket.IO notification (optional, for live app)
  io.to(userId.toString()).emit("notifications:new", { title, message });
};

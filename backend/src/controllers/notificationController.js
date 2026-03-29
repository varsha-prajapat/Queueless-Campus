import * as notificationService from "../services/notificationService.js";

/**
 * 📥 Get My Notifications + Unread Count
 */
export const getMyNotifications = async (req, res, next) => {
  try {
    const { notifications, unreadCount } =
      await notificationService.getUserNotifications(req.user);

    res.status(200).json({
      success: true,
      data: notifications,
      unreadCount,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * 🔢 Get Unread Notification Count ✅ NEW
 */
export const getUnreadNotificationCount = async (req, res, next) => {
  try {
    const count = await notificationService.getUnreadCount(
      req.user?._id,
      req.user.role,
    );

    console.log("count", count);
    res.status(200).json({
      success: true,
      unreadCount: count,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * 👁️ Mark as Read
 */
export const markAllNotificationsRead = async (req, res, next) => {
  try {
    // ✅ get userId from auth (JWT)
    const userId = req.user?._id?.toString();

    // ❌ validation
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "User ID missing",
      });
    }

    // ✅ call service
    await notificationService.markAllAsRead(req.io, userId);

    // ✅ success response
    return res.status(200).json({
      success: true,
      message: "All notifications marked as read",
    });
  } catch (err) {
    console.error("❌ Controller Error:", err.message);
    next(err);
  }
};
/**
 * ❌ Delete One
 */
export const deleteNotification = async (req, res, next) => {
  try {
    const userId = req.user._id.toString();
    const notificationId = req.params.id;
    const type = req.query.type;

    const result = await notificationService.deleteNotification(
      req.io,
      userId,
      notificationId,
      type,
    );

    res.status(200).json({
      success: true,
      message: "Notification deleted",
      data: {
        notificationId,
        type: result?.type || null,
      },
    });
  } catch (err) {
    next(err);
  }
};

/**
 * ❌ Delete All
 */
export const deleteAllNotifications = async (req, res, next) => {
  try {
    const userId = req.user._id.toString();

    await notificationService.deleteAllNotifications(req.io, userId);

    res.status(200).json({
      success: true,
      message: "All notifications deleted",
    });
  } catch (err) {
    next(err);
  }
};

// controllers/notificationController.js
import Notification from "../models/NotificationModel.js";

/**
 * Emit notification via Socket.IO to the right audience
 */
const emitNotification = (io, notification) => {
  if (!io || !notification) return;

  try {
    const notif = notification.toObject
      ? notification.toObject()
      : notification;

    // GLOBAL
    if (notif.isGlobal) {
      io.emit("notifications:update", [notif]);
    }

    // ROLE BASED
    if (Array.isArray(notif.roles) && notif.roles.length > 0) {
      // ⭐ Handle ALL role
      if (notif.roles.includes("ALL")) {
        ["ADMIN", "STAFF", "STUDENT"].forEach((role) => {
          io.to(`role_${role}`).emit("notifications:update", [notif]);
        });
      } else {
        notif.roles.forEach((role) => {
          io.to(`role_${role}`).emit("notifications:update", [notif]);
        });
      }
    }

    // USER SPECIFIC
    if (notif.userId) {
      io.to(notif.userId.toString()).emit("notifications:update", [notif]);
    }

    console.log("📡 Notification emitted:", notif.title);
  } catch (err) {
    console.error("Socket.IO emit error:", err);
  }
};
/**
 * Get all notifications for the logged-in user
 */
export const getMyNotifications = async (req, res, next) => {
  try {
    const userId = req.user._id.toString();
    const userRole = req.user.role;
    const now = new Date();
    const notifications = await Notification.find({
      $and: [
        {
          $or: [
            { userId },
            { roles: { $in: [userRole, "ALL"] } },
            { isGlobal: true },
          ],
        },
        { hiddenFor: { $ne: userId } },
      ],
    }).sort({ createdAt: -1 });

    const mappedNotifications = notifications
      .map((notif) => {
        const expiresAt =
          (notif.expiresFor && notif.expiresFor[userId]) ||
          notif.expiresAt ||
          null;
        const isRead = notif.readBy?.some((id) => id.toString() === userId);
        return {
          _id: notif._id,
          title: notif.title,
          message: notif.message,
          userId: notif.userId,
          roles: notif.roles,
          isGlobal: notif.isGlobal,
          hiddenFor: notif.hiddenFor,
          expiresAt,
          isRead: !!isRead,
          createdAt: notif.createdAt,
        };
      })
      .filter((notif) => !notif.expiresAt || notif.expiresAt > now);

    res.status(200).json({ success: true, data: mappedNotifications });
  } catch (error) {
    next(error);
  }
};

/**
 * Create a new notification and emit real-time
 */
export const createNotification = async (req, res, next) => {
  try {
    const {
      title,
      message,
      roles = [],
      userId = null,
      isGlobal = false,
    } = req.body;

    if (!title || !message) throw new Error("Title and message are required");
    if (!isGlobal && roles.length === 0 && !userId)
      throw new Error("Notification must have userId, roles, or be global");

    const notification = await Notification.create({
      title,
      message,
      roles,
      userId,
      isGlobal,
      readBy: [],
      hiddenFor: [],
      expiresFor: new Map(),
    });

    // Emit real-time
    emitNotification(req.io, notification);

    res.status(201).json({ success: true, data: notification });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete a single notification for current user
 */
export const deleteNotification = async (req, res, next) => {
  try {
    const userId = req.user._id.toString();
    const { id } = req.params;

    const notification = await Notification.findById(id);
    if (!notification)
      return res
        .status(404)
        .json({ success: false, message: "Notification not found" });

    // Soft delete for current user
    if (!notification.hiddenFor.includes(userId)) {
      notification.hiddenFor.push(userId);
      await notification.save();
    }

    // Emit updated notification to user
    emitNotification(req.io, notification);

    res.status(200).json({ success: true, message: "Notification deleted" });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete all notifications for current user
 */
export const deleteAllNotifications = async (req, res, next) => {
  try {
    const userId = req.user._id.toString();
    const notifications = await Notification.updateMany(
      {
        hiddenFor: { $ne: userId },
        $or: [{ userId }, { roles: req.user.role }, { isGlobal: true }],
      },
      { $push: { hiddenFor: userId } },
    );

    // Emit updates for all affected notifications
    const updatedNotifications = await Notification.find({ hiddenFor: userId });
    updatedNotifications.forEach((notif) => emitNotification(req.io, notif));

    res
      .status(200)
      .json({ success: true, message: "All notifications deleted" });
  } catch (error) {
    next(error);
  }
};

/**
 * Set expiry for a notification for current user
 */
export const setNotificationExpiry = async (req, res, next) => {
  try {
    const userId = req.user._id.toString();
    const { id } = req.params;
    const { expiresAt } = req.body;

    const notification = await Notification.findById(id);
    if (!notification)
      return res
        .status(404)
        .json({ success: false, message: "Notification not found" });

    // Set per-user expiry
    const expiresMap = notification.expiresFor || new Map();
    expiresMap.set(userId, new Date(expiresAt));
    notification.expiresFor = expiresMap;
    await notification.save();

    emitNotification(req.io, notification);

    res
      .status(200)
      .json({ success: true, message: "Notification expiry updated" });
  } catch (error) {
    next(error);
  }
};

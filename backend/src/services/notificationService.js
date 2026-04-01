import Notification from "../models/NotificationModel.js";
import Counter from "../models/counterModel.js";
import mongoose from "mongoose";

/**
 * 🔔 Create Notification + Emit
 */
export const createNotification = async (io, data) => {
  try {
    // ---------------- VALIDATION ----------------
    if (!data.title || !data.message) {
      throw new Error("Title & message required");
    }

    if (
      !data.userId &&
      !data.isGlobal &&
      (!data.roles || data.roles.length === 0) &&
      !data.departmentId &&
      !data.counterId
    ) {
      throw new Error("Target required");
    }

    // ---------------- SAVE ----------------
    const notification = await Notification.create(data);
    const notif = notification.toObject();

    if (!io) return notif;

    const payload = {
      type: "NEW",
      data: notif,
    };

    // ---------------- GLOBAL ----------------
    if (notif.isGlobal) {
      io.emit("notification:new", payload);
      return notif;
    }

    // ---------------- PERSONAL ----------------
    if (notif.userId) {
      io.to(notif.userId.toString()).emit("notification:new", payload);
    }

    // ---------------- ROLE ----------------
    if (notif.roles?.length) {
      notif.roles.forEach((role) => {
        const safeRole = role.toUpperCase(); // 🔥 FIX
        io.to(`role_${safeRole}`).emit("notification:new", payload);
      });
    }

    // ---------------- DEPARTMENT ----------------
    if (notif.departmentId) {
      io.to(`dept_${notif.departmentId}`).emit("notification:new", payload);
    }

    // ---------------- COUNTER ----------------
    if (notif.counterId) {
      // 🔥 IMPORTANT FIX (MATCH SOCKET JOIN)
      io.to(`role_COUNTER_${notif.counterId}`).emit(
        "notification:new",
        payload,
      );
    }

    return notif;
  } catch (err) {
    console.error("❌ Create Notification Error:", err.message);
    throw err;
  }
};

/**
 * 📥 Get Notifications + Unread Count
 */
export const getUserNotifications = async (user) => {
  try {
    const userId = user._id;
    const role = user.role?.toUpperCase();
    const deptId = user.departmentId;

    const now = new Date();

    let counterIds = [];

    if (role === "STAFF") {
      const counters = await Counter.find({
        staffIds: userId,
        isActive: true,
      }).select("_id");

      counterIds = counters.map((c) => c._id);
    }

    const query = {
      $and: [
        {
          $or: [
            { userId },
            { roles: { $in: [role] } },
            { departmentId: deptId },
            ...(counterIds.length ? [{ counterId: { $in: counterIds } }] : []),
            { isGlobal: true },
          ],
        },
        { hiddenFor: { $nin: [userId] } },
      ],
    };

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .lean();

    let unreadCount = 0;

    const formattedNotifications = notifications
      .map((n) => {
        const expiresAt =
          n.expiresFor?.[userId.toString()] || n.expiresAt || null;

        const isRead = n.readBy?.some(
          (id) => id.toString() === userId.toString(),
        );

        if (!isRead && (!expiresAt || expiresAt > now)) {
          unreadCount++;
        }

        return {
          _id: n._id,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead,
          expiresAt,
          createdAt: n.createdAt,
        };
      })
      .filter((n) => !n.expiresAt || n.expiresAt > now);

    return {
      notifications: formattedNotifications,
      unreadCount,
    };
  } catch (err) {
    console.error("❌ Get Notifications Error:", err.message);
    throw err;
  }
};

/**
 * 👁️ Mark All Read
 */
export const markAllAsRead = async (io, userId) => {
  try {
    await Notification.updateMany(
      { readBy: { $ne: userId } },
      { $addToSet: { readBy: userId } },
    );

    if (io) {
      io.to(userId.toString()).emit("notification:read_all", {
        type: "READ_ALL",
      });
    }

    return true;
  } catch (err) {
    console.error("❌ Mark All Read Error:", err.message);
    throw err;
  }
};

/**
 * ❌ Delete One
 */
export const deleteNotification = async (io, userId, notificationId) => {
  try {
    const notification = await Notification.findById(notificationId);
    if (!notification) throw new Error("Notification not found");

    if (!notification.hiddenFor.includes(userId)) {
      notification.hiddenFor.push(userId);
      await notification.save();
    }

    if (io) {
      io.to(userId.toString()).emit("notification:delete_one", {
        type: "DELETE_ONE",
        data: { notificationId },
      });
    }

    return { success: true };
  } catch (err) {
    console.error("❌ Delete Notification Error:", err.message);
    throw err;
  }
};

/**
 * ❌ Delete All
 */
export const deleteAllNotifications = async (io, userId) => {
  try {
    await Notification.updateMany(
      { hiddenFor: { $nin: [userId] } },
      { $addToSet: { hiddenFor: userId } },
    );

    if (io) {
      io.to(userId.toString()).emit("notification:delete_all", {
        type: "DELETE_ALL",
      });
    }

    return true;
  } catch (err) {
    console.error("❌ Delete All Error:", err.message);
    throw err;
  }
};

/**
 * 📊 Unread Count
 */
export const getUnreadCount = async (userId, role) => {
  try {
    if (!userId) {
      throw new Error("User ID is required");
    }

    const userObjectId = new mongoose.Types.ObjectId(userId);
    let counterIds = [];

    if (role?.toUpperCase() === "STAFF") {
      const counters = await Counter.find({
        staffIds: userObjectId,
        isActive: true,
      }).select("_id");

      counterIds = counters.map((c) => c._id);
    }

    const query = {
      $and: [
        {
          $or: [
            { userId: userObjectId },
            { roles: { $in: [role] } }, // 🔥 ADD THIS LINE
            { isGlobal: true },
            ...(counterIds.length ? [{ counterId: { $in: counterIds } }] : []),
          ],
        },
        { hiddenFor: { $ne: userObjectId } },
        { readBy: { $ne: userObjectId } },
      ],
    };

    const count = await Notification.countDocuments(query);

    return count;
  } catch (error) {
    console.error("❌ getUnreadCount Error:", error.message);
    throw error;
  }
};

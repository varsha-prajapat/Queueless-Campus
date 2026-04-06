import Notification from "../models/NotificationModel.js";
import Counter from "../models/counterModel.js";
import mongoose from "mongoose";

/* =========================================================
   🔧 HELPERS
========================================================= */

const toObjectId = (id) => new mongoose.Types.ObjectId(id);

/**
 * 🔥 FIX: counterId null-safe condition
 */
const counterIdNotExistsCondition = {
  $or: [{ counterId: null }, { counterId: { $exists: false } }],
};

/**
 * 📦 Build common OR conditions (REUSABLE)
 */
const buildOrConditions = ({ userId, roles, counterIds }) => {
  const orConditions = [];

  // 👤 Personal
  orConditions.push({ userId });

  // 🌍 Global
  orConditions.push({ isGlobal: true });

  // 🎭 Role-based (ONLY generic, no counter notifications)
  if (roles.length) {
    orConditions.push({
      roles: { $in: roles },
      ...counterIdNotExistsCondition,
    });
  }

  // 🧑‍💼 Counter-based
  if (counterIds.length > 0) {
    orConditions.push({
      counterId: { $in: counterIds },
    });
  }

  return orConditions;
};

/* =========================================================
   🔔 CREATE NOTIFICATION
========================================================= */

export const createNotification = async (io, data) => {
  try {
    /* ================= VALIDATION ================= */

    if (!data.title || !data.message) {
      throw new Error("Title & message required");
    }

    if (
      !data.userId &&
      !data.isGlobal &&
      (!data.roles || data.roles.length === 0) &&
      !data.counterId
    ) {
      throw new Error("Target required");
    }

    /* ================= SAVE ================= */

    const notification = await Notification.create(data);
    const notif = notification.toObject();

    if (!io) return notif;

    const payload = {
      type: "NEW",
      data: notif,
    };

    const getCounterRoom = (id) => `role_COUNTER_${id.toString()}`;

    /* ================= GLOBAL ================= */

    if (notif.isGlobal) {
      io.emit("notification:new", payload);
      return notif;
    }

    /* ================= USER ================= */

    if (notif.userId) {
      io.to(notif.userId.toString()).emit("notification:new", payload);
    }

    /* ================= COUNTER (HIGHEST PRIORITY) ================= */

    if (notif.counterId) {
      io.to(getCounterRoom(notif.counterId)).emit("notification:new", payload);
      return notif;
    }

    /* ================= ROLE ================= */

    if (notif.roles?.length) {
      notif.roles.forEach((role) => {
        io.to(`role_${role.toUpperCase()}`).emit("notification:new", payload);
      });
    }

    return notif;
  } catch (err) {
    console.error("❌ Create Notification Error:", err.message);
    throw err;
  }
};

/* =========================================================
   📥 GET USER NOTIFICATIONS
========================================================= */

export const getUserNotifications = async (user) => {
  try {
    const userId = toObjectId(user._id);
    const userIdStr = userId.toString();

    const roles = Array.isArray(user.roles)
      ? user.roles.map((r) => r.toUpperCase())
      : user.role
        ? [user.role.toUpperCase()]
        : [];

    let counterIds = [];

    // 🧑‍💼 STAFF COUNTERS
    if (roles.includes("STAFF")) {
      const counters = await Counter.find({
        staffIds: userId,
      })
        .select("_id")
        .lean();

      counterIds = counters.map((c) => c._id);
    }

    const orConditions = buildOrConditions({
      userId,
      roles,
      counterIds,
    });

    const query = {
      $and: [{ $or: orConditions }, { hiddenFor: { $nin: [userId] } }],
    };

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .lean();

    let unreadCount = 0;

    const formatted = notifications.map((n) => {
      const isRead = n.readBy?.some((id) => id.toString() === userIdStr);

      if (!isRead) unreadCount++;

      return {
        _id: n._id,
        title: n.title,
        message: n.message,
        type: n.type,
        isRead,
        createdAt: n.createdAt,
      };
    });

    return {
      notifications: formatted,
      unreadCount,
    };
  } catch (err) {
    console.error("❌ Get Notifications Error:", err.message);
    throw err;
  }
};

/* =========================================================
   👁️ MARK ALL AS READ
========================================================= */

export const markAllAsRead = async (io, userId) => {
  try {
    const uid = toObjectId(userId);

    await Notification.updateMany(
      { readBy: { $ne: uid } },
      { $addToSet: { readBy: uid } },
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

/* =========================================================
   ❌ DELETE ONE
========================================================= */

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

/* =========================================================
   ❌ DELETE ALL
========================================================= */

export const deleteAllNotifications = async (io, userId) => {
  try {
    const uid = toObjectId(userId);

    await Notification.updateMany(
      { hiddenFor: { $nin: [uid] } },
      { $addToSet: { hiddenFor: uid } },
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

/* =========================================================
   📊 UNREAD COUNT
========================================================= */

export const getUnreadCount = async (userId, role) => {
  try {
    if (!userId) throw new Error("User ID required");

    const uid = toObjectId(userId);
    const roleUpper = role?.toUpperCase();

    let counterIds = [];

    if (roleUpper === "STAFF") {
      const counters = await Counter.find({
        staffIds: uid,
      })
        .select("_id")
        .lean();

      counterIds = counters.map((c) => c._id);
    }

    const orConditions = buildOrConditions({
      userId: uid,
      roles: roleUpper ? [roleUpper] : [],
      counterIds,
    });

    const query = {
      $and: [
        { $or: orConditions },
        { hiddenFor: { $nin: [uid] } },
        { readBy: { $nin: [uid] } },
      ],
    };

    return await Notification.countDocuments(query);
  } catch (err) {
    console.error("❌ getUnreadCount Error:", err.message);
    throw err;
  }
};

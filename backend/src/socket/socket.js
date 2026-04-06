import Notification from "../models/NotificationModel.js";
import Counter from "../models/counterModel.js";
import mongoose from "mongoose";

/**
 * 🔌 Queue Socket Setup (FIXED + SAFE)
 */
export const queueSocket = (io) => {
  io.on("connection", async (socket) => {
    try {
      console.log("👤 User connected:", socket.id);

      const userId = socket.handshake.query?.userId?.toString();

      // 🔥 FIX 1: safe role parsing + normalization
      let roles = socket.handshake.query?.roles
        ? socket.handshake.query.roles.split(",")
        : [];

      roles = roles
        .map((r) => r?.toString().trim().toUpperCase())
        .filter(Boolean);

      console.log("🔐 Roles received:", roles);
      console.log("🆔 User ID:", userId);

      /* ================= 👤 PERSONAL ROOM ================= */
      if (userId) {
        socket.join(userId);
      }

      /* ================= 🎭 ROLE ROOMS ================= */
      roles.forEach((role) => {
        socket.join(`role_${role}`);
        console.log(`📡 Joined role room: role_${role}`);
      });

      /* ================= 🧑‍💼 STAFF COUNTER ROOMS ================= */
      if (roles.includes("STAFF") && userId) {
        if (!mongoose.Types.ObjectId.isValid(userId)) {
          console.warn("⚠️ Invalid userId for STAFF:", userId);
        } else {
          const counters = await Counter.find({
            staffIds: new mongoose.Types.ObjectId(userId),
            isActive: true,
          }).select("_id");

          for (const c of counters) {
            const room = `role_COUNTER_${c._id.toString()}`;
            socket.join(room);

            console.log(`✅ Staff joined counter room: ${room}`);
          }
        }
      }

      /* ================= 🔔 SEND EXISTING NOTIFICATIONS ================= */
      if (userId) {
        let counterIds = [];

        if (
          roles.includes("STAFF") &&
          mongoose.Types.ObjectId.isValid(userId)
        ) {
          const counters = await Counter.find({
            staffIds: new mongoose.Types.ObjectId(userId),
            isActive: true,
          }).select("_id");

          counterIds = counters.map((c) => c._id);
        }

        const notifications = await Notification.find({
          $and: [
            {
              $or: [
                { userId },
                { roles: { $in: roles } },
                ...(counterIds.length
                  ? [{ counterId: { $in: counterIds } }]
                  : []),
                { isGlobal: true },
              ],
            },
            { hiddenFor: { $nin: [userId] } },
          ],
        })
          .sort({ createdAt: -1 })
          .limit(50)
          .lean();

        socket.emit("notifications:update", notifications);
      }

      /* ================= DISCONNECT ================= */
      socket.on("disconnect", () => {
        console.log("❌ User disconnected:", socket.id);
      });
    } catch (err) {
      console.error("⚠️ Socket error:", err.message);
    }
  });
};

/**
 * 🚀 GLOBAL TOKEN EVENT EMITTER (FIXED + SAFE)
 */
export const emitTokenEvent = (token, eventName = "token:update", io) => {
  if (!io || !token) return;

  const studentId =
    token.studentId?._id?.toString() || token.studentId?.toString();

  const counterId =
    token.counterId?._id?.toString() || token.counterId?.toString();

  console.log("📡 EMIT EVENT:", eventName);

  /* 👤 STUDENT */
  if (studentId) {
    io.to(studentId).emit(eventName, token);
  }

  /* 🏢 COUNTER */
  if (counterId) {
    io.to(`role_COUNTER_${counterId}`).emit(eventName, token);
  }

  /* 🛡️ ADMIN */
  io.to("role_ADMIN").emit(eventName, token);
};

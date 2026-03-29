import Notification from "../models/NotificationModel.js";
import Counter from "../models/counterModel.js";
import mongoose from "mongoose";

/**
 * 🔌 Queue Socket Setup (FIXED)
 */
export const queueSocket = (io) => {
  io.on("connection", async (socket) => {
    try {
      console.log("👤 User connected:", socket.id);

      const userId = socket.handshake.query?.userId?.toString();

      let roles = socket.handshake.query?.roles
        ? socket.handshake.query.roles.split(",")
        : [];

      roles = roles.map((r) => r.toUpperCase());

      /* ================= 👤 PERSONAL ROOM ================= */
      if (userId) {
        socket.join(userId);
      }

      /* ================= 🎭 ROLE ROOMS ================= */
      roles.forEach((role) => {
        socket.join(`role_${role}`);
      });

      /* ================= 🧑‍💼 STAFF COUNTER ROOMS ================= */
      if (roles.includes("STAFF") && userId) {
        if (!mongoose.Types.ObjectId.isValid(userId)) return;

        // ✅ FIX: find ALL counters (not just one)
        const counters = await Counter.find({
          staffIds: new mongoose.Types.ObjectId(userId),
          isActive: true,
        }).select("_id");

        for (const c of counters) {
          const room = `role_COUNTER_${c._id.toString()}`;
          socket.join(room);

          console.log(`✅ Staff ${userId} joined counter room: ${room}`);
        }
      }

      /* ================= 🔔 SEND EXISTING NOTIFICATIONS ================= */
      if (userId) {
        let counterIds = [];

        // 👉 get staff counters for filtering notifications
        if (roles.includes("STAFF")) {
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
            { hiddenFor: { $nin: [userId] } }, // ✅ FIX
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
 * 🚀 GLOBAL TOKEN EVENT EMITTER
 */
export const emitTokenEvent = (io, token, eventName = "token:update") => {
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
};

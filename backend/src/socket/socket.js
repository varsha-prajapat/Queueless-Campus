import Notification from "../models/NotificationModel.js";
import Counter from "../models/counterModel.js";
import mongoose from "mongoose";

/**
 * 🔌 Queue Socket Setup
 */
export const queueSocket = (io) => {
  io.on("connection", async (socket) => {
    try {
      console.log("👤 User connected:", socket.id);

      const userId = socket.handshake.query?.userId;
      let roles = socket.handshake.query?.roles
        ? socket.handshake.query.roles.split(",")
        : [];

      // Normalize roles to uppercase for consistency
      roles = roles.map((r) => r.toUpperCase());

      // ---------------- PERSONAL ROOM ----------------
      if (userId) socket.join(userId.toString());

      // ---------------- ROLE ROOMS ----------------
      roles.forEach((role) => socket.join(`role_${role}`));

      // ---------------- STAFF COUNTER ROOM ----------------
      if (roles.includes("STAFF") && userId) {
        const counter = await Counter.findOne({
          staffIds: new mongoose.Types.ObjectId(userId),
          isActive: true,
        });

        if (counter) {
          socket.join(`role_COUNTER_${counter._id.toString()}`);
          console.log(
            `✅ Staff ${userId} joined counter room: role_COUNTER_${counter._id.toString()}`,
          );
        }
      }

      // ---------------- SEND EXISTING NOTIFICATIONS ----------------
      if (userId) {
        const notifications = await Notification.find({
          $and: [
            {
              $or: [{ userId }, { roles: { $in: roles } }, { isGlobal: true }],
            },
            { hiddenFor: { $ne: userId } },
          ],
        })
          .sort({ createdAt: -1 })
          .limit(50);

        socket.emit("notifications:update", notifications);
      }

      // ---------------- TOKEN EVENTS LISTENERS ----------------
      const tokenEvents = [
        "token:created",
        "token:paymentConfirmed",
        "token:cancelled",
        "token:called",
        "token:completed",
        "token:skipped",
      ];

      tokenEvents.forEach((event) => {
        socket.on(event, (data) => {
          console.log(`📡 ${event} received:`, data?._id || data);
        });
      });

      // ---------------- DISCONNECT ----------------
      socket.on("disconnect", () => {
        console.log("❌ User disconnected:", socket.id);
      });
    } catch (err) {
      console.error("⚠️ Socket error:", err);
    }
  });
};

import Notification from "../models/NotificationModel.js";
import { createNotification } from "./notificationService.js";
import { getTokenStatsService } from "./tokenService.js";

const safeEmit = (io, room, event, data) => {
  try {
    if (!io || typeof io.to !== "function") return;
    io.to(room).emit(event, data);
  } catch (err) {
    console.error("Emit Error:", err.message);
  }
};
const queueSocket = (io) => {
  io.on("connection", async (socket) => {
    try {
      const userId = socket.handshake.query?.userId?.toString();

      const roles =
        socket.handshake.query?.roles?.split(",").map((r) => r.toUpperCase()) ||
        [];

      console.log("👤 Connected:", socket.id, userId, roles);

      if (userId) socket.join(userId);
      roles.forEach((r) => socket.join(`role_${r}`));

      /* STAFF JOIN COUNTERS */
      if (roles.includes("STAFF") && userId) {
        if (!mongoose.Types.ObjectId.isValid(userId)) return;

        const counters = await Counter.find({
          staffIds: new mongoose.Types.ObjectId(userId),
          isActive: true,
        });

        for (const c of counters) {
          socket.join(`role_COUNTER_${c._id}`);
          const queue = await getStaffQueue(c._id);
          socket.emit("queue:update", queue);
        }
      }

      /* NOTIFICATIONS */
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
          .limit(50)
          .lean();

        socket.emit("notifications:update", notifications);
      }

      socket.on("disconnect", () => {
        console.log("❌ Disconnected:", socket.id);
      });
    } catch (err) {
      console.error("Socket Error:", err);
    }
  });
};

/* ================= NOTIFICATION ================= */
export const sendNotification = async ({
  title,
  message,
  userId,
  counterId = null,
  roles = [],
  isGlobal = false,
  type = "INFO",
  io,
  tokenId = null,
  tokenNumber = null,
}) => {
  if (!title || !message) return null;

  try {
    const notification = await createNotification(io, {
      title,
      message,
      userId,
      counterId,
      roles,
      isGlobal,
      type,
      tokenId,
      tokenNumber,
    });

    const payload = notification;

    // 👇 1. USER ROOM
    if (userId) {
      safeEmit(io, userId.toString(), "notifications:new", payload);
    }

    // 👇 2. ROLE ROOMS
    roles.forEach((r) => {
      safeEmit(io, `role_${r}`, "notifications:new", payload);
    });

    // 👇 3. COUNTER ROOM (FIXED)
    if (counterId) {
      safeEmit(io, `role_COUNTER_${counterId}`, "notifications:new", payload);
    }

    return notification;
  } catch (err) {
    console.error("Notification Error:", err.message);
  }
};

/* ================= STUDENT STATS EMIT ================= */
export const emitStudentStats = async (studentId, io) => {
  if (!studentId) return;

  try {
    const stats = await getTokenStatsService(studentId);
    safeEmit(io, studentId.toString(), "token:update", stats);
  } catch (err) {
    console.error("Stats Error:", err.message);
  }
};

/* ================= TOKEN EVENT EMITTER ================= */
export const emitTokenEvent = (token, event, io) => {
  if (!token) return;

  const studentRoom =
    token.studentId?._id?.toString() || token.studentId?.toString();

  const counterRoom = token.counterId?.toString();

  if (studentRoom) safeEmit(io, studentRoom, event, token);
  if (counterRoom) safeEmit(io, `role_COUNTER_${counterRoom}`, event, token);
};

import Counter from "../models/counterModel.js";
import Token from "../models/tokenModel.js";

/* ================= ADMIN QUEUE SERVICE ================= */
export const getAdminQueueDetailsService = async (io = null) => {
  try {
    const counters = await Counter.find({ isActive: true }).lean();

    const result = [];

    // 🔥 GLOBAL STATS
    let totalWaiting = 0;
    let totalServing = 0;
    let totalCompleted = 0;
    let totalCancelled = 0;
    let totalSkipped = 0;

    for (const counter of counters) {
      const tokens = await Token.find({
        counterId: counter._id,
      })
        .populate("studentId", "name email")
        .populate("serviceId", "name fee")
        .sort({ isUrgent: -1, createdAt: 1 })
        .lean();

      const waiting = tokens.filter((t) => t.status === "waiting").length;
      const serving = tokens.find((t) => t.status === "serving") || null;
      const completed = tokens.filter((t) => t.status === "completed").length;
      const cancelled = tokens.filter((t) => t.status === "cancelled").length;
      const skipped = tokens.filter((t) => t.status === "skipped").length;

      // GLOBAL SUM
      totalWaiting += waiting;
      totalServing += serving ? 1 : 0;
      totalCompleted += completed;
      totalCancelled += cancelled;
      totalSkipped += skipped;

      result.push({
        counterId: counter._id,
        counterName: counter.name,

        summary: {
          waiting,
          serving: serving?.tokenNumber || "-",
          completed,
          cancelled,
          skipped,
        },

        currentToken: serving
          ? {
              tokenId: serving._id,
              tokenNumber: serving.tokenNumber,
              student: serving.studentId,
              service: serving.serviceId,
              status: serving.status,
              servingStartedAt: serving.servingStartedAt,
            }
          : null,

        queue: tokens,
      });
    }

    const response = {
      globalStats: {
        totalWaiting,
        totalServing,
        totalCompleted,
        totalCancelled,
        totalSkipped,
      },
      counters: result,
    };

    // 📡 REAL-TIME EMIT
    if (io) {
      io.to("role_ADMIN").emit("admin:queue:update", response);
    }

    return response;
  } catch (err) {
    console.error("❌ Admin Queue Service Error:", err.message);
    throw err;
  }
};

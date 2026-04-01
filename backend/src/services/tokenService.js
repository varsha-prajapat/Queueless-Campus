import mongoose from "mongoose";
import Token from "../models/tokenModel.js";
import Service from "../models/serviceModel.js";
import Counter from "../models/counterModel.js";
import {
  sendNotification,
  emitStudentStats,
  emitTokenEvent,
} from "./communicationService.js";

export const createToken = async (
  studentId,
  serviceId,
  isUrgent = false,
  io = null,
) => {
  try {
    // ---------------- VALIDATION ----------------
    if (!studentId || !serviceId) {
      throw new Error("Student ID and Service ID required");
    }

    // ---------------- ACTIVE TOKEN CHECK ----------------
    const existingToken = await Token.findOne({
      studentId,
      status: { $in: ["waiting", "waiting_payment", "serving"] },
    });

    if (existingToken) {
      throw new Error("Already have active token");
    }

    // ---------------- SERVICE ----------------
    const service = await Service.findById(serviceId);
    if (!service) throw new Error("Service not found");

    // ---------------- COUNTERS ----------------
    const counters = await Counter.find({
      serviceId: service._id,
      isActive: true,
    });

    if (!counters.length) {
      throw new Error("No active counter found");
    }

    // ---------------- LOAD BALANCING ----------------
    const tokenStats = await Token.aggregate([
      {
        $match: {
          serviceId: service._id,
          status: { $in: ["waiting", "waiting_payment", "serving"] },
        },
      },
      {
        $group: {
          _id: "$counterId",
          count: { $sum: 1 },
        },
      },
    ]);

    const loadMap = new Map();
    tokenStats.forEach((t) => {
      loadMap.set(String(t._id), t.count);
    });

    let selectedCounter = counters[0];

    for (const counter of counters) {
      const current = loadMap.get(String(counter._id)) || 0;
      const selected = loadMap.get(String(selectedCounter._id)) || 0;

      if (current < selected) {
        selectedCounter = counter;
      }
    }

    // ---------------- 🔥 TOKEN NUMBER GENERATION (NO COUNTER FIELD) ----------------
    const lastToken = await Token.findOne({
      counterId: selectedCounter._id,
    })
      .sort({ tokenNumber: -1 }) // highest first
      .select("tokenNumber");

    const tokenNumber = lastToken ? lastToken.tokenNumber + 1 : 1;

    // ---------------- CREATE TOKEN ----------------
    const token = await Token.create({
      studentId,
      serviceId: service._id,
      counterId: selectedCounter._id,
      tokenNumber,
      status: service.hasFee ? "waiting_payment" : "waiting",
      isUrgent,
    });

    // ---------------- SOCKET EVENTS ----------------
    if (io) {
      io.to(studentId.toString()).emit("token:new", token);
      io.to("role_STAFF").emit("token:create", token);
      io.to("role_ADMIN").emit("token:new", token);
      io.emit("token:update", token);
    }

    // ---------------- NOTIFICATION ----------------
    await sendNotification({
      title: "Token Created",
      message: `Your token ${tokenNumber} created`,
      type: "CREATED",
      counterId: token.counterId,
      tokenId: token._id,
      tokenNumber,
      userId: studentId,
      io,
    });

    await getAdminQueueDetails(io);

    return token;
  } catch (error) {
    console.error("createToken error:", error.message);
    throw error;
  }
}; /* ================= CALL NEXT TOKEN (STAFF) ================= */
export const callNextToken = async (counterId, io = null) => {
  const active = await Token.findOne({
    counterId,
    status: "serving",
  });

  if (active) {
    return {
      success: false,
      message: "Already serving token",
    };
  }

  const next = await Token.findOne({
    counterId,
    status: "waiting",
  })
    .sort({ isUrgent: -1, createdAt: 1 })
    .populate("studentId serviceId");

  if (!next) {
    return {
      success: false,
      message: "No token available",
    };
  }

  next.status = "serving";
  next.servingStartedAt = new Date();
  await next.save();
  await sendNotification({
    title: "Your Turn",
    message: `Token ${next.tokenNumber}, please come to the counter.`,
    type: "CALLED",
    userId: next.studentId._id,
    tokenId: next._id,
    tokenNumber: next.tokenNumber,
    io,
  });
  await getAdminQueueDetails(io);
  emitTokenEvent(next, "token:called", io);
  await emitStudentStats(next.studentId._id, io);

  return {
    success: true,
    token: next,
  };
};

/* ================= COMPLETE TOKEN ================= */
export const completeToken = async (tokenId, io) => {
  const token = await Token.findById(tokenId);
  if (!token) throw new Error("Token not found");
  if (token.status !== "serving") {
    throw new Error(
      `Token cannot be completed because current status is "${token.status}". It must be "serving".`,
    );
  }
  // ✅ mark as completed
  token.status = "completed";
  await token.save();
  await getAdminQueueDetails(io);
  // ✅ socket events
  emitTokenEvent(token, "token:completed", io);
  await emitStudentStats(token.studentId, io);

  // ✅ notification (FINAL CONFIRMATION)
  await sendNotification({
    title: "Token Completed",
    message: `Your token ${token.tokenNumber} has been completed successfully.`,
    type: "INFO",
    userId: token.studentId,
    io,
  });

  return token;
};
/* ================= SKIP TOKEN ================= */
export const skipToken = async (tokenId, io) => {
  const token = await Token.findById(tokenId);
  if (!token) throw new Error("Token not found");

  const allowed = ["waiting", "serving"];
  if (!allowed.includes(token.status)) {
    throw new Error("Cannot skip this token");
  }

  token.status = "skipped";
  await token.save();
  await sendNotification({
    title: "Token Skipped",
    message: `Token ${token.tokenNumber} has been skipped.`,
    type: "SKIPPED",
    userId: token.studentId,
    io,
  });
  await getAdminQueueDetails(io);
  emitTokenEvent(token, "token:skipped", io);
  return token;
};

/* ================= STAFF QUEUE ================= */
export const getStaffQueue = async (counterId) => {
  const tokens = await Token.find({
    counterId,
    status: { $in: ["waiting", "serving", "skipped"] },
  })
    .populate("studentId", "name email")
    .populate("serviceId", "name fee")
    .sort({ isUrgent: -1, createdAt: 1 })
    .lean();

  return tokens;
};

/* ================= MY TOKENS ================= */
export const getMyTokensService = async (studentId) => {
  const tokens = await Token.find({ studentId })
    .populate("serviceId counterId")
    .sort({ createdAt: -1 })
    .lean();

  const current = tokens.find((t) => t.status === "serving");
  const next = tokens.find((t) => t.status === "waiting");

  return {
    summary: {
      currentToken: current?.tokenNumber || "-",
      nextToken: next?.tokenNumber || "-",
      waiting: tokens.filter((t) => t.status === "waiting").length,
      completed: tokens.filter((t) => t.status === "completed").length,
      cancelled: tokens.filter((t) => t.status === "cancelled").length,
      skipped: tokens.filter((t) => t.status === "skipped").length,
    },
    tokens,
  };
};

/* ================= TOKEN STATS ================= */
export const getTokenStatsService = async (studentId) => {
  const tokens = await Token.find({ studentId }).lean();

  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  // ======================
  // STATUS GROUPING
  // ======================
  const waitingTokens = tokens.filter((t) => t.status === "waiting");
  const servingToken = tokens.find((t) => t.status === "serving");
  const myActiveToken = tokens.find((t) =>
    ["waiting", "serving"].includes(t.status),
  );

  // ======================
  // COUNTS
  // ======================
  const waiting = waitingTokens.length;

  const completed = tokens.filter((t) => t.status === "completed").length;
  const cancelled = tokens.filter((t) => t.status === "cancelled").length;
  const skipped = tokens.filter((t) => t.status === "skipped").length;

  const servedToday = tokens.filter(
    (t) => t.status === "completed" && new Date(t.updatedAt) >= todayStart,
  ).length;

  // ======================
  // QUEUE POSITION LOGIC
  // ======================
  let peopleAhead = 0;

  if (myActiveToken && myActiveToken.status === "waiting") {
    peopleAhead = waitingTokens.filter(
      (t) => t.createdAt < myActiveToken.createdAt,
    ).length;
  }

  // ======================
  // NEXT TOKEN IN QUEUE
  // ======================
  const nextToken =
    waitingTokens.sort(
      (a, b) => new Date(a.createdAt) - new Date(b.createdAt),
    )[0]?.tokenNumber || "-";

  return {
    currentToken: servingToken?.tokenNumber || "-",
    yourToken: myActiveToken?.tokenNumber || "-",
    nextToken,

    peopleAhead,
    waiting,

    completed,
    cancelled,
    skipped,
    servedToday,
  };
};
export const getTokenStatsForStaffDetailed = async (counterId) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(counterId)) {
      throw new Error("Invalid counter ID");
    }

    const tokens = await Token.find({ counterId })
      .populate("studentId", "name email")
      .populate("serviceId", "name fee")
      .sort({ createdAt: 1 })
      .lean();

    // 🔹 current serving token
    const current = tokens.find((t) => t.status === "serving");

    // 🔹 next waiting token
    const next = tokens.find((t) => t.status === "waiting");

    // 🔹 counts
    const waiting = tokens.filter((t) => t.status === "waiting").length;
    const skipped = tokens.filter((t) => t.status === "skipped").length;
    const cancelled = tokens.filter((t) => t.status === "cancelled").length;
    const completed = tokens.filter((t) => t.status === "completed").length;

    // 🔹 today start fix (IMPORTANT FIX)
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const servedToday = tokens.filter(
      (t) =>
        t.status === "completed" &&
        t.updatedAt &&
        new Date(t.updatedAt) >= todayStart,
    ).length;

    return {
      summary: {
        currentToken: current?.tokenNumber || "-",
        nextToken: next?.tokenNumber || "-",
        waiting,
        skipped,
        cancelled,
        completed,
        servedToday,
      },

      tokens: tokens.map((t) => ({
        tokenId: t._id,
        tokenNumber: t.tokenNumber,
        status: t.status,
        isUrgent: t.isUrgent || false,

        student: t.studentId
          ? {
              id: t.studentId._id,
              name: t.studentId.name,
              email: t.studentId.email,
            }
          : null,

        service: t.serviceId
          ? {
              id: t.serviceId._id,
              name: t.serviceId.name,
              fee: t.serviceId.fee,
            }
          : null,

        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
        servingStartedAt: t.servingStartedAt || null,
      })),
    };
  } catch (err) {
    console.error("❌ Staff Stats Error:", err.message);
    throw err;
  }
};
export const cancelToken = async (tokenId, studentId, io = null) => {
  try {
    if (!tokenId || !studentId) {
      throw new Error("Token ID and Student ID required");
    }

    const token = await Token.findOne({
      _id: tokenId,
      studentId,
    });

    if (!token) {
      throw new Error("Token not found or not yours");
    }

    // ❌ Already finished cases
    if (["completed", "cancelled"].includes(token.status)) {
      throw new Error("Cannot cancel this token");
    }

    // ✅ update status
    token.status = "cancelled";
    token.cancelledAt = new Date();
    await token.save();

    // 📡 socket emit
    emitTokenEvent(token, "token:cancelled", io);

    // 📊 update stats
    await emitStudentStats(studentId, io);

    // ✅ NOTIFICATION → COUNTER ko milega
    await sendNotification({
      title: "Token Cancelled",
      message: `Token ${token.tokenNumber} has been cancelled by student.`,
      type: "INFO",
      counterId: token.counterId, // 👈 counter ko bhejna
      io,
    });
    await getAdminQueueDetails(io);
    return {
      success: true,
      message: "Token cancelled successfully",
      token,
    };
  } catch (err) {
    console.error("❌ Cancel Token Error:", err.message);
    throw err;
  }
};
export const confirmPayment = async (tokenId, studentId, io = null) => {
  try {
    if (!tokenId || !studentId) {
      throw new Error("Token ID and Student ID required");
    }

    const token = await Token.findOne({
      _id: tokenId,
      studentId,
    });

    if (!token) {
      throw new Error("Token not found");
    }

    // ❌ already processed cases
    if (token.status !== "waiting_payment") {
      throw new Error("Payment is not required for this token");
    }

    // ✅ update status
    token.status = "waiting";
    token.paymentStatus = "paid";
    token.paymentConfirmedAt = new Date();

    await token.save();

    // 🔔 1. Notify Student
    await sendNotification({
      title: "Payment Successful",
      message: `Payment confirmed for Token ${token.tokenNumber}.`,
      type: "PAYMENT_SUCCESS",
      userId: studentId,
      tokenId: token._id,
      tokenNumber: token.tokenNumber,
      io,
    });
    await getAdminQueueDetails(io);

    // 🔔 2. Notify Staff / Counter
    if (token.counterId) {
      await sendNotification({
        title: "Payment Received",
        message: `Payment received for Token ${token.tokenNumber}.`,
        type: "PAYMENT_RECEIVED",
        counterId: token.counterId,
        tokenId: token._id,
        tokenNumber: token.tokenNumber,
        io,
      });
    }

    // 📡 3. Socket event (global token update)
    emitTokenEvent(token, "token:paymentConfirmed", io);

    // 📡 4. Socket event for staff/counter dashboard
    if (token.counterId && io) {
      io.to(`counter_${token.counterId}`).emit("counter:paymentConfirmed", {
        tokenId: token._id,
        tokenNumber: token.tokenNumber,
        studentId,
        counterId: token.counterId,
        paymentStatus: token.paymentStatus,
        status: token.status,
      });
    }

    // 📊 5. Update student stats
    await emitStudentStats(studentId, io);

    // 📊 6. Optional: update counter stats
    if (token.counterId) {
      io.to(`counter_${token.counterId}`).emit("counter:statsUpdate", {
        type: "payment_confirmed",
        tokenId: token._id,
      });
    }

    // 📡 7. Update admin queue details
    await getAdminQueueDetails(io);

    return {
      success: true,
      message: "Payment confirmed successfully",
      token,
    };
  } catch (err) {
    console.error("❌ Confirm Payment Error:", err.message);
    throw err;
  }
};
export const getAdminQueueDetails = async (io = null) => {
  try {
    const counters = await Counter.find({ isActive: true }).lean();

    const result = [];

    // 🔥 GLOBAL COUNTERS
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

      // 🔥 ADD TO GLOBAL TOTALS
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

    // 🔥 FINAL GLOBAL SUMMARY
    const globalStats = {
      totalWaiting,
      totalServing,
      totalCompleted,
      totalCancelled,
      totalSkipped,
    };

    const response = {
      globalStats,
      counters: result,
    };

    // 📡 REAL-TIME ADMIN UPDATE
    if (io) {
      io.to("role_ADMIN").emit("admin:queue:update", response);
    }

    return response;
  } catch (err) {
    console.error("❌ Admin Queue Error:", err.message);
    throw err;
  }
};

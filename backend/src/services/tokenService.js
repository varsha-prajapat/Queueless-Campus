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

    // ---------------- TOKEN NUMBER ----------------
    const lastToken = await Token.findOne({
      counterId: selectedCounter._id,
    })
      .sort({ tokenNumber: -1 })
      .select("tokenNumber");

    const tokenNumber = lastToken ? lastToken.tokenNumber + 1 : 1;

    // ---------------- 🔥 PAYMENT LOGIC ----------------
    const totalAmount = service.fee || 0;

    const paymentStatus = totalAmount === 0 ? "paid" : "pending";
    const status = totalAmount === 0 ? "waiting" : "waiting_payment";

    // ---------------- CREATE TOKEN ----------------
    const token = await Token.create({
      studentId,
      serviceId: service._id,
      serviceName: service.name,

      counterId: selectedCounter._id,
      tokenNumber,

      totalAmount,
      paymentStatus,
      status,

      isUrgent,
    });

    // ---------------- SOCKET EVENTS ----------------
    if (io) {
      io.to(studentId.toString()).emit("token:new", token);
      io.to(`role_COUNTER_${token.counterId}`).emit("token:create", token);
      io.to("role_ADMIN").emit("token:new", token);
      io.emit("token:update", token);
    }

    // ---------------- 🔥 IMPROVED NOTIFICATION ----------------
    const counterName = selectedCounter.name || "Counter";

    await sendNotification({
      title: "Token Created",
      message: `Token ${tokenNumber} no for ${service.name} is created at ${counterName} counter.`,
      type: "CREATED",
      counterId: token.counterId,
      tokenId: token._id,
      tokenNumber,
      userId: studentId,
      io,
    });

    // ---------------- ADMIN UPDATE ----------------
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

  // ---------------- 🔥 IMPROVED NOTIFICATION ----------------
  const counter = await Counter.findById(counterId).select("name");
  const counterName = counter?.name || "Counter";
  const serviceName = next.serviceId?.name || next.serviceName || "Service";

  await sendNotification({
    title: "Your Turn",
    message: `Token ${next.tokenNumber} no for ${serviceName} is now called at ${counterName} counter. Please proceed to the counter.`,
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

  // ---------------- 🔥 IMPROVED NOTIFICATION ----------------
  const service = await Service.findById(token.serviceId).select("name");
  const counter = await Counter.findById(token.counterId).select("name");

  const serviceName = service?.name || token.serviceName || "Service";
  const counterName = counter?.name || "Counter";

  // ✅ notification (FINAL CONFIRMATION)
  await sendNotification({
    title: "Token Completed",
    message: `Token ${token.tokenNumber} no for ${serviceName} at ${counterName} counter has been completed successfully.`,
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

  // ---------------- 🔥 IMPROVED NOTIFICATION ----------------
  const service = await Service.findById(token.serviceId).select("name");
  const counter = await Counter.findById(token.counterId).select("name");

  const serviceName = service?.name || token.serviceName || "Service";
  const counterName = counter?.name || "Counter";

  await sendNotification({
    title: "Token Skipped",
    message: `Token ${token.tokenNumber} no for ${serviceName} at ${counterName} counter has been skipped.`,
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
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  // ======================
  // 1. GET ALL USER TOKENS (for stats only)
  // ======================
  const userTokens = await Token.find({ studentId }).lean();

  const completed = userTokens.filter((t) => t.status === "completed").length;
  const cancelled = userTokens.filter((t) => t.status === "cancelled").length;
  const skipped = userTokens.filter((t) => t.status === "skipped").length;

  const servedToday = userTokens.filter(
    (t) =>
      t.status === "completed" &&
      t.updatedAt &&
      new Date(t.updatedAt) >= todayStart,
  ).length;

  // ======================
  // 2. GET ACTIVE TOKEN (IMPORTANT)
  // ======================
  const myActiveToken = await Token.findOne({
    studentId,
    status: { $in: ["waiting", "serving"] },
  }).lean();

  // 👉 If no active token
  if (!myActiveToken) {
    return {
      currentToken: "-",
      yourToken: "-",
      nextToken: "-",

      peopleAhead: 0,
      waiting: 0,

      completed,
      cancelled,
      skipped,
      servedToday,
    };
  }

  // ======================
  // 3. GET QUEUE TOKENS (SAME COUNTER)
  // ======================
  const queueTokens = await Token.find({
    counterId: myActiveToken.counterId, // 🔥 IMPORTANT
    status: { $in: ["waiting", "serving"] },
  })
    .sort({ createdAt: 1 }) // oldest first
    .lean();

  const waitingTokens = queueTokens.filter((t) => t.status === "waiting");

  // ======================
  // 4. CURRENT TOKEN (SERVING)
  // ======================
  const servingToken = queueTokens.find((t) => t.status === "serving");

  // ======================
  // 5. PEOPLE AHEAD
  // ======================
  let peopleAhead = 0;

  if (myActiveToken.status === "waiting") {
    peopleAhead = waitingTokens.filter(
      (t) => new Date(t.createdAt) < new Date(myActiveToken.createdAt),
    ).length;
  }

  // ======================
  // 6. NEXT TOKEN
  // ======================
  const nextToken =
    waitingTokens.length > 0 ? waitingTokens[0].tokenNumber : "-";

  // ======================
  // 7. WAITING COUNT (QUEUE)
  // ======================
  const waiting = waitingTokens.length;

  // ======================
  // FINAL RESPONSE
  // ======================
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

    // ---------------- 🔥 IMPROVED NOTIFICATION ----------------
    const service = await Service.findById(token.serviceId).select("name");
    const counter = await Counter.findById(token.counterId).select("name");

    const serviceName = service?.name || token.serviceName || "Service";
    const counterName = counter?.name || "Counter";

    // ✅ NOTIFICATION → COUNTER ko milega
    await sendNotification({
      title: "Token Cancelled",
      message: `Token ${token.tokenNumber} no for ${serviceName} at ${counterName} counter has been cancelled by student.`,
      type: "INFO",
      counterId: token.counterId,
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
    // ---------------- VALIDATION ----------------
    if (!tokenId || !studentId) {
      throw new Error("Token ID and Student ID required");
    }

    // ---------------- FIND TOKEN ----------------
    const token = await Token.findOne({
      _id: tokenId,
      studentId,
    });

    if (!token) {
      throw new Error("Token not found");
    }

    // ---------------- CHECK STATUS ----------------
    if (token.status !== "waiting_payment") {
      throw new Error("Payment is not required for this token");
    }

    // ---------------- ✅ UPDATE PAYMENT ----------------
    token.status = "waiting";
    token.paymentStatus = "paid";
    token.paidAt = new Date();

    await token.save();

    // ---------------- 🔥 FETCH EXTRA INFO ----------------
    const service = await Service.findById(token.serviceId).select("name");
    const counter = await Counter.findById(token.counterId).select("name");

    const serviceName = service?.name || token.serviceName || "Service";
    const counterName = counter?.name || "Counter";
    const amount = token.totalAmount || 0;

    // ---------------- 🔔 NOTIFY STUDENT ----------------
    await sendNotification({
      title: "Payment Successful",
      message: `Payment of ₹${amount} confirmed for Token ${token.tokenNumber} no  (${serviceName}) at ${counterName} counter.`,
      type: "PAYMENT_SUCCESS",
      userId: studentId,
      tokenId: token._id,
      tokenNumber: token.tokenNumber,
      io,
    });

    // ---------------- 🔔 NOTIFY COUNTER ----------------
    if (token.counterId) {
      await sendNotification({
        title: "Payment Received",
        message: `₹${amount} received for Token ${token.tokenNumber} no  (${serviceName}) at ${counterName} counter.`,
        type: "PAYMENT_RECEIVED",
        counterId: token.counterId,
        tokenId: token._id,
        tokenNumber: token.tokenNumber,
        io,
      });
    }

    // ---------------- 📡 SOCKET EVENTS ----------------
    emitTokenEvent(token, "token:paymentConfirmed", io);

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

    // ---------------- 📊 UPDATE STATS ----------------
    await emitStudentStats(studentId, io);

    if (token.counterId && io) {
      io.to(`counter_${token.counterId}`).emit("counter:statsUpdate", {
        type: "payment_confirmed",
        tokenId: token._id,
      });
    }

    // ---------------- 📡 ADMIN UPDATE ----------------
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

    /// 🔥 GLOBAL COUNTERS
    let totalWaiting = 0;
    let totalServing = 0;
    let totalCompleted = 0;
    let totalCancelled = 0;
    let totalSkipped = 0;

    /// 🔥 PAYMENT GLOBAL
    let totalPayment = 0;
    let totalUnpaid = 0;
    let totalTokens = 0;

    for (const counter of counters) {
      const tokens = await Token.find({
        counterId: counter._id,
      })
        .populate("studentId", "name email")
        .populate("serviceId", "name fee")
        .sort({ isUrgent: -1, createdAt: 1 })
        .lean();

      /// 🔥 BASIC COUNTS
      const waiting = tokens.filter((t) => t.status === "waiting").length;
      const servingToken = tokens.find((t) => t.status === "serving") || null;

      const completed = tokens.filter((t) => t.status === "completed").length;
      const cancelled = tokens.filter((t) => t.status === "cancelled").length;
      const skipped = tokens.filter((t) => t.status === "skipped").length;

      /// 🔥 PAYMENT LOGIC (FIXED)
      const unpaid = tokens.filter((t) => t.paymentStatus !== "paid").length;

      const counterPayment = tokens.reduce((sum, t) => {
        return t.paymentStatus === "paid" ? sum + (t.totalAmount || 0) : sum;
      }, 0);

      /// 🔥 GLOBAL ADD
      totalWaiting += waiting;
      totalServing += servingToken ? 1 : 0;
      totalCompleted += completed;
      totalCancelled += cancelled;
      totalSkipped += skipped;

      totalPayment += counterPayment;
      totalUnpaid += unpaid;
      totalTokens += tokens.length;

      result.push({
        counterId: counter._id,
        counterName: counter.name,

        summary: {
          waiting,
          serving: servingToken?.tokenNumber || "-",
          completed,
          cancelled,
          skipped,

          /// 🔥 PAYMENT
          unpaid,
          totalPayment: counterPayment,
        },

        currentToken: servingToken
          ? {
              tokenId: servingToken._id,
              tokenNumber: servingToken.tokenNumber,
              student: servingToken.studentId,
              service: servingToken.serviceId,
              status: servingToken.status,
              servingStartedAt: servingToken.servingStartedAt,

              /// 🔥 PAYMENT
              paymentAmount: servingToken.totalAmount || 0,
              paymentStatus: servingToken.paymentStatus,
            }
          : null,

        queue: tokens.map((t) => ({
          tokenId: t._id,
          tokenNumber: t.tokenNumber,
          studentId: t.studentId,
          serviceId: t.serviceId,
          status: t.status,
          isUrgent: t.isUrgent,

          /// 🔥 PAYMENT (FIXED)
          paymentAmount: t.totalAmount || 0,
          paymentStatus: t.paymentStatus,

          createdAt: t.createdAt,
        })),
      });
    }

    /// 🔥 FINAL GLOBAL SUMMARY
    const globalStats = {
      totalWaiting,
      totalServing,
      totalCompleted,
      totalCancelled,
      totalSkipped,

      /// 🔥 PAYMENT
      totalPayment,
      totalUnpaid,
      totalTokens,
    };

    const response = {
      globalStats,
      counters: result,
    };

    /// 📡 REAL-TIME ADMIN UPDATE
    if (io) {
      io.to("role_ADMIN").emit("admin:queue:update", response);
    }

    return response;
  } catch (err) {
    console.error("❌ Admin Queue Error:", err.message);
    throw err;
  }
};

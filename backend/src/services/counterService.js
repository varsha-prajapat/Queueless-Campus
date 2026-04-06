// services/counterService.js
import Counter from "../models/counterModel.js";
import Service from "../models/serviceModel.js";
import mongoose from "mongoose";
import Token from "../models/tokenModel.js";
import { sendNotification } from "./communicationService.js";

/**
 * ➕ Create a new counter
 */
export const createCounter = async (data, io = null) => {
  if (data.staffIds && !Array.isArray(data.staffIds))
    data.staffIds = [data.staffIds];
  if (data.name) data.name = data.name.toUpperCase();

  const existingCounter = await Counter.findOne({ name: data.name });
  if (existingCounter)
    throw new Error(`Counter with name "${data.name}" already exists`);

  const counter = await Counter.create(data);

  await Service.findByIdAndUpdate(data.serviceId, {
    $push: { counters: counter._id },
  });

  await counter.populate("serviceId", "name");
  await counter.populate("staffIds", "name email");

  return counter;
};
/**
 * Get counter by Name
 */
export const getCounterByName = async (name) => {
  if (!name?.trim()) return null;

  const counter = await Counter.findOne({
    name: { $regex: `^${name.trim()}$`, $options: "i" },
  })
    .populate("serviceId", "name")
    .populate("staffIds", "name email");

  return counter; // ❌ no error throw
};
/**
 * ✏️ Update a counter
 */
export const updateCounter = async (id, data, io = null) => {
  /* ================= 🧹 CLEAN INPUT ================= */

  if (data.staffIds && !Array.isArray(data.staffIds)) {
    data.staffIds = [data.staffIds];
  }

  if (data.serviceId && typeof data.serviceId === "string") {
    data.serviceId = new mongoose.Types.ObjectId(data.serviceId);
  }

  if (data.name) {
    const existingCounter = await Counter.findOne({ name: data.name });
    if (existingCounter && existingCounter._id.toString() !== id) {
      throw new Error(`Counter with name "${data.name}" already exists`);
    }
  }

  /* ================= 📦 GET OLD COUNTER ================= */

  let counter = await Counter.findById(id);
  if (!counter) throw new Error("Counter not found");

  const oldStatus = counter.isActive;

  /* ================= 🔄 UPDATE ================= */

  Object.assign(counter, data);
  await counter.save();

  /* ================= 🔥 RE-FETCH ================= */

  counter = await Counter.findById(id)
    .populate("serviceId", "name")
    .populate("staffIds", "name email");

  /* ================= 🔔 STATUS CHANGE ================= */

  if (
    data.hasOwnProperty("isActive") &&
    typeof data.isActive === "boolean" &&
    oldStatus !== data.isActive
  ) {
    const isActive = counter.isActive;

    const serviceName = counter.serviceId?.name || "Service";

    /* ================= 👨‍💼 STAFF NOTIFICATION (UPDATED) ================= */

    const staffMessage = isActive
      ? `Service ${serviceName}: Counter ${counter.name} is now ACTIVE`
      : `Service ${serviceName}: Counter ${counter.name} is now INACTIVE`;

    console.log("counter id:", counter._id);

    await sendNotification({
      title: "Counter Status Update",
      message: staffMessage,
      counterId: counter._id,
      roles: ["STAFF"],
      type: "INFO",
      io,
    });

    /* ================= 🎓 STUDENT NOTIFICATION ================= */

    const tokens = await Token.find({
      counterId: counter._id,
      status: { $in: ["waiting", "waiting_payment", "serving"] },
    }).select("studentId tokenNumber");

    const studentMap = new Map();

    tokens.forEach((t) => {
      const key = t.studentId.toString();
      if (!studentMap.has(key)) {
        studentMap.set(key, []);
      }
      studentMap.get(key).push(t.tokenNumber);
    });

    if (studentMap.size > 0) {
      await Promise.all(
        Array.from(studentMap.entries()).map(
          async ([studentId, tokenNumbers]) => {
            const tokenList = tokenNumbers.join(", ");

            const studentMessage = isActive
              ? `Service ${serviceName}: Your token ${tokenList} at counter ${counter.name} is now ACTIVE. Please be ready.`
              : `Service ${serviceName}: Your token ${tokenList} at counter ${counter.name} is temporarily INACTIVE.`;

            await sendNotification({
              title: "Service Update",
              message: studentMessage,
              userId: studentId,
              type: "INFO",
              io,
            });
          },
        ),
      );
    }
  }

  return counter;
};
export const deleteCounter = async (id, io = null) => {
  /* ================= 📦 FIND COUNTER ================= */

  let counter = await Counter.findById(id).populate("serviceId", "name");
  if (!counter) throw new Error("Counter not found");

  const serviceName = counter.serviceId?.name || "Service";

  /* ================= 👨‍🏫 GET STAFF IDS ================= */

  const staffIds = counter.staffIds || [];

  /* ================= 🎓 GET RELATED TOKENS ================= */

  const tokens = await Token.find({
    counterId: counter._id,
    status: { $in: ["waiting", "waiting_payment", "serving"] },
  }).select("studentId tokenNumber");

  /* 🔥 GROUP TOKENS BY STUDENT */
  const studentMap = new Map();

  tokens.forEach((t) => {
    const key = t.studentId.toString();
    if (!studentMap.has(key)) {
      studentMap.set(key, []);
    }
    studentMap.get(key).push(t.tokenNumber);
  });

  /* ================= 🔄 CANCEL TOKENS ================= */

  await Token.updateMany(
    {
      counterId: counter._id,
      status: { $in: ["waiting", "called"] },
    },
    {
      $set: { status: "cancelled" },
    },
  );

  /* ================= 🔔 STAFF NOTIFICATION ================= */

  const staffMessage = `Service ${serviceName}: Counter ${counter.name} has been shut down`;

  if (staffIds.length > 0) {
    await Promise.all(
      staffIds.map((staffId) =>
        sendNotification({
          title: "Counter Shut Down",
          message: staffMessage,
          userId: staffId,
          type: "INFO",
          io,
        }),
      ),
    );
  }

  /* ================= 🔔 STUDENT NOTIFICATION ================= */

  if (studentMap.size > 0) {
    await Promise.all(
      Array.from(studentMap.entries()).map(
        async ([studentId, tokenNumbers]) => {
          const tokenList = tokenNumbers.join(", ");

          const studentMessage = `Service ${serviceName}: Your token(s) ${tokenList} at counter ${counter.name} have been cancelled because this counter was shut down`;

          await sendNotification({
            title: "Token Cancelled",
            message: studentMessage,
            userId: studentId,
            type: "INFO",
            io,
          });
        },
      ),
    );
  }

  /* ================= 🧹 REMOVE FROM SERVICE ================= */

  await Service.findByIdAndUpdate(counter.serviceId, {
    $pull: { counters: counter._id },
  });

  /* ================= 🗑️ DELETE COUNTER ================= */

  await Counter.findByIdAndDelete(counter._id);

  /* ================= ✅ RETURN ================= */

  return {
    success: true,
    message: "Counter deleted, tokens cancelled, notifications sent",
  };
};

/**
 * Get all counters
 */
export const getAllCounters = async () => {
  return await Counter.find()
    .populate("serviceId", "name")
    .populate("staffIds", "name email");
};

/**
 * Get counter by ID
 */
export const getCounterById = async (id) => {
  const counter = await Counter.findById(id)
    .populate("serviceId", "name")
    .populate("staffIds", "name email");
  if (!counter) throw new Error("Counter not found");
  return counter;
};

/**
 * Get counters assigned to a specific staff member
 */
export const getCountersByStaffId = async (staffId) => {
  if (!mongoose.Types.ObjectId.isValid(staffId)) return [];
  const objectId = new mongoose.Types.ObjectId(staffId);
  return await Counter.find({ staffIds: objectId })
    .populate("serviceId", "name")
    .populate("staffIds", "name email");
};

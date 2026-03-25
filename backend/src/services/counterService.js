// services/counterService.js
import Counter from "../models/counterModel.js";
import Service from "../models/serviceModel.js";
import mongoose from "mongoose";
import { createNotification } from "./notificationService.js";

/**
 * 🎯 Helper: send notifications to admins + specific staff
 */
const sendNotification = async ({
  title,
  message,
  roles = [],
  userIds = [],
  io = null,
}) => {
  if (!title || !message) return;

  try {
    const notification = await createNotification({
      title,
      message,
      roles,
      userIds,
    });

    if (io) {
      // Emit to roles
      roles.forEach((role) =>
        io.to(`role_${role}`).emit("notifications:update", [notification]),
      );

      // Emit to specific users
      if (Array.isArray(userIds)) {
        userIds.forEach((id) =>
          io.to(id.toString()).emit("notifications:update", [notification]),
        );
      }
    }
  } catch (err) {
    console.error("Notification Error:", err.message);
  }
};

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

  // 🔔 Notifications to ADMIN + assigned staff
  sendNotification({
    title: "Counter Created",
    message: `Counter "${counter.name}" has been created.`,
    roles: ["ADMIN"],
    userIds: data.staffIds,
    io,
  });

  return counter;
};

/**
 * ✏️ Update a counter
 */
export const updateCounter = async (id, data, io = null) => {
  if (data.staffIds && !Array.isArray(data.staffIds))
    data.staffIds = [data.staffIds];
  if (data.name) data.name = data.name.toUpperCase();

  if (data.name) {
    const existingCounter = await Counter.findOne({ name: data.name });
    if (existingCounter && existingCounter._id.toString() !== id)
      throw new Error(`Counter with name "${data.name}" already exists`);
  }

  const counter = await Counter.findByIdAndUpdate(id, data, { new: true });
  if (!counter) throw new Error("Counter not found");

  await counter.populate("serviceId", "name");
  await counter.populate("staffIds", "name email");

  // 🔔 Notifications to ADMIN + assigned staff
  sendNotification({
    title: "Counter Updated",
    message: `Counter "${counter.name}" has been updated.`,
    roles: ["ADMIN"],
    userIds: counter.staffIds.map((s) => s._id),
    io,
  });

  return counter;
};

/**
 * ❌ Delete a counter
 */
export const deleteCounter = async (id, io = null) => {
  const counter = await Counter.findByIdAndDelete(id);
  if (!counter) throw new Error("Counter not found");

  await Service.findByIdAndUpdate(counter.serviceId, {
    $pull: { counters: counter._id },
  });

  // 🔔 Notifications to ADMIN + assigned staff
  sendNotification({
    title: "Counter Deleted",
    message: `Counter "${counter.name}" has been deleted.`,
    roles: ["ADMIN"],
    userIds: counter.staffIds,
    io,
  });

  return counter;
};

/**
 * Get counter by name
 */
export const getCounterByName = async (name) => {
  if (name) name = name.toUpperCase();
  return await Counter.findOne({ name });
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

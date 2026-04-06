import mongoose from "mongoose";
import Service from "../models/serviceModel.js";
import Counter from "../models/counterModel.js";
import User from "../models/userModel.js";
import { updateCounter, deleteCounter } from "./counterService.js";
/**
 * ➕ Create a service
 */
export const createService = async (data, io = null) => {
  if (data.name) data.name = data.name.toUpperCase();

  const exists = await Service.findOne({
    name: data.name,
    departmentId: data.departmentId,
  });
  if (exists)
    throw new Error(
      "A service with this name already exists in this department",
    );

  const service = await Service.create(data);

  return service;
};

/**
 * ✏️ Update a service
 */
export const updateService = async (id, data, io = null) => {
  /* ================= 🛑 VALIDATION ================= */

  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new Error("Invalid Service ID");
  }

  if (data.name) data.name = data.name.toUpperCase();

  /* ================= 🏷️ SERVICE TYPE LOGIC ================= */

  // ✅ Ensure valid enum
  const validTypes = ["Documents", "Fees"];

  if (data.serviceType && !validTypes.includes(data.serviceType)) {
    throw new Error("Invalid service type");
  }

  // ✅ If serviceType is provided → control hasFee
  if (data.serviceType) {
    if (data.serviceType === "Fees") {
      data.hasFee = true;
    } else if (data.serviceType === "Documents") {
      data.hasFee = false;
    }
  }

  /* ================= 💰 HAS FEE LOGIC ================= */

  if (data.hasFee === false) {
    data.fee = 0;
  }

  /* ================= 🔍 DUPLICATE CHECK ================= */

  if (data.name && data.departmentId) {
    const exists = await Service.findOne({
      _id: { $ne: id },
      name: data.name,
      departmentId: data.departmentId,
    });

    if (exists) {
      throw new Error(
        "A service with this name already exists in this department",
      );
    }
  }

  /* ================= 📦 GET OLD SERVICE ================= */

  const existingService = await Service.findById(id);
  if (!existingService) throw new Error("Service not found");

  const oldPausedStatus = existingService.isPaused;

  /* ================= 📦 UPDATE SERVICE ================= */

  const service = await Service.findByIdAndUpdate(id, data, {
    new: true,
    runValidators: true,
  });

  /* ================= 🔄 STATUS CHANGED ================= */

  if (data.isPaused !== undefined && oldPausedStatus !== data.isPaused) {
    const isActive = !data.isPaused;

    const counters = await Counter.find({ serviceId: id }).select("_id");

    await Promise.all(
      counters.map((counter) => updateCounter(counter._id, { isActive }, io)),
    );
  }

  return service;
};

/**
 * ❌ Delete a service
 */
export const deleteService = async (id, io = null) => {
  console.log("id:", id);

  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new Error("Invalid Service ID");
  }

  const service = await Service.findById(id);
  if (!service) throw new Error("Service not found");

  const counters = await Counter.find({ serviceId: id }).select("_id");

  await Promise.all(counters.map((counter) => deleteCounter(counter._id, io)));

  await Service.findByIdAndDelete(id);

  return {
    success: true,
    message: "Service deleted and all counters processed via deleteCounter()",
  };
};
/**
 * 📄 Get all services
 */
export const getAllServices = async () => {
  return await Service.find()
    .populate("departmentId", "name")
    .sort({ createdAt: -1 })
    .lean();
};

/**
 * 🔍 Get service by ID
 */
export const getServiceById = async (id) => {
  if (!mongoose.Types.ObjectId.isValid(id))
    throw new Error("Invalid Service ID");

  const service = await Service.findById(id).populate("departmentId", "name");
  if (!service) throw new Error("Service not found");

  return service;
};

/**
 * 🔥 Get services by Department ID
 * **/
export const getServicesByDepartmentId = async (departmentId) => {
  try {
    // ❌ if empty → return []
    if (!departmentId) return [];

    // ✅ remove spaces
    const cleanId = departmentId.trim();

    // ❌ invalid ObjectId → return []
    if (!mongoose.Types.ObjectId.isValid(cleanId)) {
      return [];
    }

    // ✅ convert string → ObjectId
    const objectId = new mongoose.Types.ObjectId(cleanId);

    // ✅ query
    const services = await Service.find({
      departmentId: objectId,
    })
      .populate("departmentId", "name")
      .sort({ createdAt: -1 });

    // ✅ always return array (no throw)
    return services || [];
  } catch (error) {
    // ❌ no crash
    return [];
  }
};

/**
 * ✅ Get only active services
 */
export const getActiveServices = async () => {
  return await Service.find({ isPaused: false }).populate(
    "departmentId",
    "name",
  );
};

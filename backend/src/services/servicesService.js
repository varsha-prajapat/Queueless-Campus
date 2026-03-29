import mongoose from "mongoose";
import Service from "../models/serviceModel.js";
import Counter from "../models/counterModel.js";
import Department from "../models/DepartmentModel.js";
import User from "../models/userModel.js";

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

  // Get all staff in the department
  const staffUsers = await User.find({
    departmentId: service.departmentId,
    role: "STAFF",
  }).select("_id");
  const staffIds = staffUsers.map((u) => u._id);

  return service;
};

/**
 * ✏️ Update a service
 */
export const updateService = async (id, data, io = null) => {
  if (!mongoose.Types.ObjectId.isValid(id))
    throw new Error("Invalid Service ID");

  if (data.name) data.name = data.name.toUpperCase();

  // Duplicate check
  if (data.name && data.departmentId) {
    const exists = await Service.findOne({
      _id: { $ne: id },
      name: data.name,
      departmentId: data.departmentId,
    });
    if (exists)
      throw new Error(
        "A service with this name already exists in this department",
      );
  }

  const service = await Service.findByIdAndUpdate(id, data, {
    new: true,
    runValidators: true,
  });
  if (!service) throw new Error("Service not found");

  if (data.isPaused !== undefined) {
    await Counter.updateMany({ serviceId: id }, { isActive: !data.isPaused });
  }

  // Get department staff
  const staffUsers = await User.find({
    departmentId: service.departmentId,
    role: "STAFF",
  }).select("_id");
  const staffIds = staffUsers.map((u) => u._id);

  return service;
};

/**
 * ❌ Delete a service
 */
export const deleteService = async (id, io = null) => {
  if (!mongoose.Types.ObjectId.isValid(id))
    throw new Error("Invalid Service ID");

  const service = await Service.findByIdAndDelete(id);
  if (!service) throw new Error("Service not found");

  await Counter.deleteMany({ serviceId: id });

  // Get department staff
  const staffUsers = await User.find({
    departmentId: service.departmentId,
    role: "STAFF",
  }).select("_id");
  const staffIds = staffUsers.map((u) => u._id);

  return true;
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

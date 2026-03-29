import mongoose from "mongoose";
import Department from "../models/DepartmentModel.js";
import Service from "../models/serviceModel.js";
import Counter from "../models/counterModel.js";
import Banner from "../models/bannerModel.js";

/**
 * ➕ Create department
 */
export const createDepartment = async (data, io = null) => {
  try {
    if (!data.name) {
      throw new Error("Department name is required");
    }

    // 🔤 normalize name
    const name = data.name.toUpperCase();

    // 🔍 check duplicate
    const existingDepartment = await Department.findOne({ name });

    if (existingDepartment) {
      throw new Error("Department already exists");
    }

    // ➕ create new department
    const department = new Department({
      ...data,
      name,
    });

    const savedDepartment = await department.save();

    // 📡 real-time update
    if (io) {
      io.emit("departmentCreated", savedDepartment);
    }

    return savedDepartment;
  } catch (err) {
    console.error("❌ Create Department Error:", err.message);
    throw err;
  }
};

/**
 * 📄 Get all departments
 */
export const getDepartments = async () => {
  return await Department.find().sort({ status: 1, createdAt: -1 });
};

/**
 * 🔍 Get department by ID
 */
export const getDepartmentById = async (id) => {
  if (!mongoose.Types.ObjectId.isValid(id))
    throw new Error("Invalid Department ID");

  const department = await Department.findById(id);

  if (!department) throw new Error("Department not found");

  return department;
};

/**
 * ✏️ Update department
 */
export const updateDepartment = async (id, data, io = null) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw new Error("Invalid Department ID");
    }

    const department = await Department.findById(id);
    if (!department) {
      throw new Error("Department not found");
    }

    // 🔤 normalize name
    if (data.name) {
      data.name = data.name.trim().toUpperCase();

      // 🔍 check duplicate name in OTHER departments
      const existing = await Department.findOne({
        name: data.name,
        _id: { $ne: id }, // 👈 exclude current department
      });

      if (existing) {
        throw new Error("Department name already exists");
      }
    }

    // ✏️ update department
    const updatedDepartment = await Department.findByIdAndUpdate(id, data, {
      new: true,
      runValidators: true,
    });

    // ⛔ If inactive → pause services & counters
    if (updatedDepartment.status === "inactive") {
      await Service.updateMany({ departmentId: id }, { isPaused: true });

      const serviceIds = (
        await Service.find({ departmentId: id }).select("_id")
      ).map((s) => s._id);

      await Counter.updateMany(
        { serviceId: { $in: serviceIds } },
        { isActive: false },
      );
    }

    // 📡 real-time update
    if (io) {
      io.emit("departmentUpdated", updatedDepartment);
    }

    return updatedDepartment;
  } catch (err) {
    console.error("❌ Update Department Error:", err.message);
    throw err;
  }
};

/**
 * 🗑 Delete department
 */
export const deleteDepartment = async (id, io = null) => {
  if (!mongoose.Types.ObjectId.isValid(id))
    throw new Error("Invalid Department ID");

  // Get related services
  const services = await Service.find({ departmentId: id }).select("_id");
  const serviceIds = services.map((s) => s._id);

  // Delete related data first
  await Counter.deleteMany({ serviceId: { $in: serviceIds } });
  await Service.deleteMany({ departmentId: id });
  await Banner.deleteMany({ departmentId: id });

  // Delete department
  const department = await Department.findByIdAndDelete(id);

  if (!department) throw new Error("Department not found");

  // 📡 real-time update
  if (io) {
    io.emit("departmentDeleted", {
      id: department._id,
      name: department.name,
    });
  }

  return department;
};

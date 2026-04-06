import mongoose from "mongoose";
import Department from "../models/DepartmentModel.js";
import Service from "../models/serviceModel.js";
import User from "../models/userModel.js";
import Banner from "../models/bannerModel.js";
import { updateService, deleteService } from "./servicesService.js";
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
    /* ================= 🛑 VALIDATION ================= */
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw new Error("Invalid Department ID");
    }

    /* ================= 📦 FIND EXISTING ================= */
    const department = await Department.findById(id);
    if (!department) {
      throw new Error("Department not found");
    }

    const previousStatus = department.status;

    /* ================= 🔤 NORMALIZE NAME ================= */
    if (data.name) {
      data.name = data.name.trim().toUpperCase();

      const exists = await Department.findOne({
        name: data.name,
        _id: { $ne: id },
      });

      if (exists) {
        throw new Error("Department name already exists");
      }
    }

    /* ================= ✏️ UPDATE DEPARTMENT ================= */
    const updatedDepartment = await Department.findByIdAndUpdate(id, data, {
      new: true,
      runValidators: true,
    });

    /* ================= 🔄 CHECK STATUS CHANGE ================= */
    const statusChanged = data.status && data.status !== previousStatus;

    /* ================= 🔥 CALL SERVICE UPDATE ================= */
    if (statusChanged) {
      const services = await Service.find({ departmentId: id }).select("_id");

      await Promise.all(
        services.map(async (service) => {
          try {
            await updateService(
              service._id,
              { isPaused: updatedDepartment.status === "inactive" },
              io,
            );
          } catch (err) {
            console.error("Service update failed:", service._id, err.message);
          }
        }),
      );
    }

    /* ================= 📡 SOCKET EVENT ================= */
    if (io) {
      io.emit("departmentUpdated", {
        id: updatedDepartment._id,
        name: updatedDepartment.name,
        status: updatedDepartment.status,
        statusChanged,
      });
    }

    /* ================= ✅ RETURN ================= */
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
  try {
    /* ================= 🛑 VALIDATION ================= */
    if (!id || !mongoose.Types.ObjectId.isValid(id)) {
      throw new Error("Invalid Department ID");
    }

    /* ================= 📦 FIND SERVICES ================= */
    const services = await Service.find({ departmentId: id }).select("_id");

    /* ================= 🔥 DELETE SERVICES ================= */
    await Promise.all(
      services.map(async (service) => {
        try {
          await deleteService(service._id, io); // reuse logic
        } catch (err) {
          console.error("Service delete failed:", service._id, err.message);
        }
      }),
    );

    /* ================= 🧹 DELETE BANNERS ================= */
    await Banner.deleteMany({ departmentId: id });

    /* ================= 👤 REMOVE DEPARTMENT FROM USERS ================= */
    await User.updateMany(
      { departmentId: id },
      { $set: { departmentId: null } },
    );

    /* ================= 🗑️ DELETE DEPARTMENT ================= */
    const department = await Department.findByIdAndDelete(id);

    if (!department) {
      throw new Error("Department not found");
    }

    /* ================= 📡 SOCKET ================= */
    if (io) {
      io.emit("departmentDeleted", {
        id: department._id,
        name: department.name,
      });
    }

    /* ================= ✅ RETURN ================= */
    return department;
  } catch (err) {
    console.error("❌ Delete Department Error:", err.message);
    throw err;
  }
};

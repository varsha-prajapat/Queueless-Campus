// services/departmentService.js
import mongoose from "mongoose";
import Department from "../models/DepartmentModel.js";
import Service from "../models/serviceModel.js";
import Counter from "../models/counterModel.js";
import Banner from "../models/bannerModel.js";
import { createNotification } from "./notificationService.js";

/**
 * ➕ Create department
 * Notifications: ADMIN only
 */
export const createDepartment = async (data, io = null) => {
  if (data.name) data.name = data.name.toUpperCase();

  const department = new Department(data);
  const savedDepartment = await department.save();

  try {
    await createNotification({
      title: "Department Created",
      message: `Department "${savedDepartment.name}" has been created.`,
      roles: ["ADMIN"], // Only admins
    });

    // Real-time socket notification
    io?.to("role_ADMIN")?.emit("departmentCreated", savedDepartment);
  } catch (err) {
    console.error("Notification error (createDepartment):", err.message);
  }

  return savedDepartment;
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
 * Notifications: ADMIN only
 */
export const updateDepartment = async (id, data, io = null) => {
  if (!mongoose.Types.ObjectId.isValid(id))
    throw new Error("Invalid Department ID");

  if (data.name) data.name = data.name.toUpperCase();

  const updatedDepartment = await Department.findByIdAndUpdate(id, data, {
    new: true,
    runValidators: true,
  });

  if (!updatedDepartment) throw new Error("Department not found");

  // Pause related services & deactivate counters if department is inactive
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

  try {
    await createNotification({
      title: "Department Updated",
      message: `Department "${updatedDepartment.name}" has been updated.`,
      roles: ["ADMIN"], // Only admins
    });

    io?.to("role_ADMIN")?.emit("departmentUpdated", updatedDepartment);
  } catch (err) {
    console.error("Notification error (updateDepartment):", err.message);
  }

  return updatedDepartment;
};

/**
 * 🗑 Delete department
 * Notifications: ADMIN only
 */
export const deleteDepartment = async (id, io = null) => {
  if (!mongoose.Types.ObjectId.isValid(id))
    throw new Error("Invalid Department ID");

  // Delete services, counters, banners first
  const services = await Service.find({ departmentId: id }).select("_id");
  const serviceIds = services.map((s) => s._id);

  await Counter.deleteMany({ serviceId: { $in: serviceIds } });
  await Service.deleteMany({ departmentId: id });
  await Banner.deleteMany({ departmentId: id });

  // Delete department
  const department = await Department.findByIdAndDelete(id);
  if (!department) throw new Error("Department not found");

  try {
    await createNotification({
      title: "Department Deleted",
      message: `Department "${department.name}" has been deleted.`,
      roles: ["ADMIN"], // Only admins
    });

    io?.to("role_ADMIN")?.emit("departmentDeleted", {
      id: department._id,
      name: department.name,
    });
  } catch (err) {
    console.error("Notification error (deleteDepartment):", err.message);
  }

  return department;
};

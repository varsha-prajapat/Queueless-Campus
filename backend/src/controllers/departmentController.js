// controllers/departmentController.js
import mongoose from "mongoose";
import * as departmentService from "../services/departmentService.js";

// ➕ Create department
export const createDepartment = async (req, res) => {
  try {
    const department = await departmentService.createDepartment({
      ...req.body,
      createdBy: req.user?._id,
    });

    // Emit real-time event
    if (req.io) {
      req.io.emit("departmentCreated", department);
    }

    res.status(201).json({
      success: true,
      message: "Department created successfully",
      data: department,
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: "Department name already exists",
      });
    }

    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// 📄 Get all departments
export const getDepartments = async (req, res) => {
  try {
    const departments = await departmentService.getDepartments();
    res.status(200).json({ success: true, data: departments });
  } catch (error) {
    console.error("GET ALL ERROR:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// 🔍 Get department by ID
export const getDepartmentById = async (req, res) => {
  try {
    const { id } = req.params;

    // ✅ Check if ID is missing
    if (!id) {
      return res.status(400).json({
        success: false,
        message: "Department ID is required",
      });
    }

    // ✅ Check if ID is valid Mongo ObjectId
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid department ID",
      });
    }

    const department = await departmentService.getDepartmentById(id);

    if (!department) {
      return res.status(404).json({
        success: false,
        message: "Department not found",
      });
    }

    res.status(200).json({
      success: true,
      data: department,
    });
  } catch (error) {
    console.error("GET BY ID ERROR:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ✏️ Update department
export const updateDepartment = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid department ID",
      });
    }

    const department = await departmentService.updateDepartment(id, req.body);

    if (!department) {
      return res.status(404).json({
        success: false,
        message: "Department not found or already deleted",
      });
    }

    // Emit real-time event
    if (req.io) {
      req.io.emit("departmentUpdated", department);
    }

    res.status(200).json({
      success: true,
      message: "Department updated successfully",
      data: department,
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: "Department name already exists",
      });
    }

    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ❌ Soft delete department
export const deleteDepartment = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid department ID",
      });
    }

    const department = await departmentService.deleteDepartment(id);

    if (!department) {
      return res.status(404).json({
        success: false,
        message: "Department not found or already deleted",
      });
    }

    // Emit real-time event
    if (req.io) {
      req.io.emit("departmentDeleted", {
        id: department._id,
        name: department.name,
      });
    }

    res.status(200).json({
      success: true,
      message: "Department deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

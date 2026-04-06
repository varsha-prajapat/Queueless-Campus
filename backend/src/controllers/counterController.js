// controllers/counterController.js
import * as counterService from "../services/counterService.js";

/**
 * ➕ Create Counter
 */
export const createCounter = async (req, res) => {
  try {
    const { name, serviceId, staffIds = [], isActive = true } = req.body;

    if (!name || !serviceId) {
      return res.status(400).json({
        success: false,
        message: "Counter name and serviceId are required",
      });
    }

    // Check if counter name already exists
    const existingCounter = await counterService.getCounterByName(name);
    if (existingCounter) {
      return res.status(400).json({
        success: false,
        message: `Counter with name "${name}" already exists`,
      });
    }

    // Ensure staffIds is an array
    const staffArray = Array.isArray(staffIds) ? staffIds : [staffIds];

    const counter = await counterService.createCounter(
      {
        name,
        serviceId,
        staffIds: staffArray,
        isActive,
      },
      req.io,
    );

    // Emit real-time event
    if (req.io) {
      req.io.emit("counterCreated", counter);
    }
    res.status(201).json({
      success: true,
      message: "Counter created successfully",
      data: counter,
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * 📄 Get All Counters
 */
export const getAllCounters = async (req, res) => {
  try {
    const counters = await counterService.getAllCounters();
    res.status(200).json({ success: true, data: counters });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * 🔍 Get Counter by ID
 */
export const getCounterById = async (req, res) => {
  try {
    const counter = await counterService.getCounterById(req.params.id);
    if (!counter) {
      return res
        .status(404)
        .json({ success: false, message: "Counter not found" });
    }
    res.status(200).json({ success: true, data: counter });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * 📄 Get Counters by Staff ID
 */
export const getCountersByStaffId = async (req, res) => {
  try {
    const staffId = req.params.staffId;

    if (!staffId) {
      return res
        .status(400)
        .json({ success: false, message: "Staff ID is required" });
    }

    const counters = await counterService.getCountersByStaffId(staffId);
    res.status(200).json({ success: true, data: counters });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * ✏️ Update Counter
 */
export const updateCounter = async (req, res) => {
  try {
    const { name, serviceId, staffIds, isActive } = req.body;

    // Check if new name is unique
    if (name) {
      const existingCounter = await counterService.getCounterByName(name);
      if (existingCounter && existingCounter._id.toString() !== req.params.id) {
        return res.status(400).json({
          success: false,
          message: `Counter with name "${name}" already exists`,
        });
      }
    }

    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (serviceId !== undefined) updateData.serviceId = serviceId;
    if (staffIds !== undefined)
      updateData.staffIds = Array.isArray(staffIds) ? staffIds : [staffIds];
    if (isActive !== undefined) updateData.isActive = isActive;

    const updatedCounter = await counterService.updateCounter(
      req.params.id,
      updateData,
    );

    if (!updatedCounter) {
      return res
        .status(404)
        .json({ success: false, message: "Counter not found" });
    }

    // Emit real-time event
    if (req.io) {
      req.io.emit("counterUpdated", updatedCounter);
    }

    res.status(200).json({ success: true, data: updatedCounter });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * ❌ Delete Counter
 */
export const deleteCounter = async (req, res) => {
  try {
    const deleted = await counterService.deleteCounter(req.params.id);
    if (!deleted) {
      return res
        .status(404)
        .json({ success: false, message: "Counter not found" });
    }

    // Emit real-time event
    if (req.io) {
      req.io.emit("counterDeleted", { id: deleted._id, name: deleted.name });
    }

    res.status(200).json({
      success: true,
      message: "Counter deleted successfully",
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

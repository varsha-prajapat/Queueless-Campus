// controllers/serviceController.js
import mongoose from "mongoose";
import * as serviceService from "../services/servicesService.js";

/**
 * ➕ Create Service
 */
export const createService = async (req, res) => {
  try {
    const { name, departmentId, serviceType, allowUrgent, isPaused, fee } =
      req.body;

    if (!name || !departmentId || !serviceType) {
      return res.status(400).json({
        success: false,
        message: "Name, Department and Service Type are required",
      });
    }

    if (!mongoose.Types.ObjectId.isValid(departmentId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid Department ID",
      });
    }

    const serviceData = {
      name: name.trim(),
      departmentId,
      serviceType,
      allowUrgent: allowUrgent ?? false,
      isPaused: isPaused ?? false,
      hasFee: serviceType === "Fees",
      fee: serviceType === "Fees" ? Math.max(0, Number(fee) || 0) : 0,
      createdBy: req.user?._id,
    };

    const service = await serviceService.createService(serviceData);

    // Emit Socket.IO event
    if (req.io) {
      req.io.emit("serviceCreated", service);
    }

    return res.status(201).json({
      success: true,
      message: "Service created successfully",
      data: service,
    });
  } catch (error) {
    console.error("CREATE SERVICE ERROR:", error);

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: "Service name already exists",
      });
    }

    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
    });
  }
};

/**
 * 📄 Get All Services
 */
export const getAllServices = async (req, res) => {
  try {
    const services = await serviceService.getAllServices();

    return res.status(200).json({
      success: true,
      data: services,
    });
  } catch (error) {
    console.error("GET ALL SERVICES ERROR:", error);
    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
    });
  }
};

/**
 * ✅ Get All Active Services
 */
export const getActiveServices = async (req, res) => {
  try {
    const services = await serviceService.getActiveServices();

    return res.status(200).json({
      success: true,
      data: services,
    });
  } catch (error) {
    console.error("GET ACTIVE SERVICES ERROR:", error);
    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
    });
  }
};

/**
 * 🔥 Get Services By Department ID
 */
export const getServicesByDepartment = async (req, res) => {
  try {
    const services = await serviceService.getServicesByDepartmentId(
      req.params.departmentId, // ✅ correct
    );

    return res.json({
      success: true,
      data: services,
    });
  } catch (error) {
    return res.json({
      success: false,
      data: [],
    });
  }
};
/**
 * 🔍 Get Service By ID
 */
export const getServiceById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid Service ID",
      });
    }

    const service = await serviceService.getServiceById(id);

    if (!service) {
      return res.status(404).json({
        success: false,
        message: "Service not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: service,
    });
  } catch (error) {
    console.error("GET SERVICE ERROR:", error);
    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
    });
  }
};

/**
 * ✏️ Update Service
 */
export const updateService = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid Service ID",
      });
    }

    const service = await serviceService.updateService(id, req.body);

    if (!service) {
      return res.status(404).json({
        success: false,
        message: "Service not found or already deleted",
      });
    }

    // Emit Socket.IO event
    if (req.io) {
      req.io.emit("serviceUpdated", service);
    }

    return res.status(200).json({
      success: true,
      message: "Service updated successfully",
      data: service,
    });
  } catch (error) {
    console.error("UPDATE SERVICE ERROR:", error);

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: "Service name already exists",
      });
    }

    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
    });
  }
};

/**
 * ❌ Delete Service
 */
export const deleteService = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid Service ID",
      });
    }

    const service = await serviceService.deleteService(id);

    if (!service) {
      return res.status(404).json({
        success: false,
        message: "Service not found or already deleted",
      });
    }

    // Emit Socket.IO event
    if (req.io) {
      req.io.emit("serviceDeleted", {
        id: service._id,
        name: service.name,
      });
    }

    return res.status(200).json({
      success: true,
      message: "Service deleted successfully",
    });
  } catch (error) {
    console.error("DELETE SERVICE ERROR:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
    });
  }
};

// controllers/bannerController.js
import mongoose from "mongoose";
import * as bannerService from "../services/bannerService.js";

/**
 * ➕ Create Banner
 */
export const createBanner = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "Image is required",
      });
    }

    let departmentId = req.body.departmentId;
    if (departmentId === "ALL") departmentId = null;

    const bannerData = {
      title: req.body.title?.trim() || "",
      description: req.body.description?.trim() || "",
      targetRole: req.body.targetRole
        ? req.body.targetRole.trim().toUpperCase()
        : "ALL",
      departmentId,
      status: req.body.status || "active",
      image: `/banner/${req.file.filename}`,
      createdBy: req.user?._id,
    };

    const banner = await bannerService.createBanner(bannerData, req.io);

    return res.status(201).json({
      success: true,
      message: "Banner created successfully",
      data: banner,
    });
  } catch (error) {
    console.error("CREATE BANNER ERROR:", error);

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: "Banner title already exists",
      });
    }

    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
    });
  }
};

/**
 * 🔎 Get Banner By ID
 */
export const getBannerById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid banner ID",
      });
    }

    const banner = await bannerService.getBannerById(id);

    if (!banner) {
      return res.status(404).json({
        success: false,
        message: "Banner not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: banner,
    });
  } catch (error) {
    console.error("GET BANNER BY ID ERROR:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Server Error",
    });
  }
};

/**
 * 📄 Get All Banners
 */
export const getBanners = async (req, res) => {
  try {
    const role = req.user?.role;
    const departmentId = req.user?.departmentId || null;

    const banners = await bannerService.getBanners(role, departmentId);

    return res.status(200).json({
      success: true,
      count: banners.length,
      data: banners,
    });
  } catch (error) {
    console.error("GET BANNERS ERROR:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
    });
  }
};

/**
 * ✏️ Update Banner
 */
export const updateBanner = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid banner ID",
      });
    }

    let departmentId = req.body.departmentId;
    if (departmentId === "ALL") departmentId = null;

    const updateData = {
      title: req.body.title?.trim(),
      description: req.body.description?.trim(),
      targetRole: req.body.targetRole
        ? req.body.targetRole.trim().toUpperCase()
        : "ALL",
      departmentId,
      status: req.body.status,
    };

    // remove undefined fields (IMPORTANT FIX)
    Object.keys(updateData).forEach(
      (key) => updateData[key] === undefined && delete updateData[key],
    );

    if (req.file) {
      updateData.image = `/banner/${req.file.filename}`;
    }

    const banner = await bannerService.updateBanner(id, updateData, req.io);

    if (!banner) {
      return res.status(404).json({
        success: false,
        message: "Banner not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Banner updated successfully",
      data: banner,
    });
  } catch (error) {
    console.error("UPDATE BANNER ERROR:", error);

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: "Banner title already exists",
      });
    }

    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
    });
  }
};

/**
 * ❌ Delete Banner
 */
export const deleteBanner = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid banner ID",
      });
    }

    const banner = await bannerService.deleteBanner(id, req.io);

    if (!banner) {
      return res.status(404).json({
        success: false,
        message: "Banner not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Banner deleted successfully",
    });
  } catch (error) {
    console.error("DELETE BANNER ERROR:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
    });
  }
};

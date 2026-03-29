import Banner from "../models/bannerModel.js";
import mongoose from "mongoose";
import Department from "../models/DepartmentModel.js";

/**
 * ➕ Create a banner
 */
export const createBanner = async (data, io = null) => {
  if (!data.title || !data.description) {
    throw new Error("Banner requires title and description");
  }

  const banner = await Banner.create(data);

  io?.emit("bannerCreated", banner);

  return banner;
};

/**
 * 📄 Get Banners
 */
export const getBanners = async (role, departmentId) => {
  if (role === "ADMIN") {
    return await Banner.find().sort({ createdAt: -1 });
  }

  const query = {
    status: "active",
    $or: [{ targetRole: "ALL" }, { targetRole: role }],
  };

  if (departmentId && mongoose.Types.ObjectId.isValid(departmentId)) {
    query.$and = [{ $or: [{ departmentId: null }, { departmentId }] }];
  } else {
    query.departmentId = null;
  }

  return await Banner.find(query).sort({ createdAt: -1 });
};

/**
 * 🔎 Get banner by ID
 */
export const getBannerById = async (id) => {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new Error("Invalid banner ID");
  }
  return await Banner.findById(id);
};

/**
 * ✏️ Update banner
 */
export const updateBanner = async (id, data, io = null) => {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new Error("Invalid banner ID");
  }

  const banner = await Banner.findByIdAndUpdate(id, data, {
    new: true,
    runValidators: true,
  });

  if (!banner) return null;

  io?.emit("bannerUpdated", banner);

  return banner;
};

/**
 * ❌ Delete banner
 */
export const deleteBanner = async (id, io = null) => {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new Error("Invalid banner ID");
  }

  const banner = await Banner.findByIdAndDelete(id);

  if (!banner) return null;

  io?.emit("bannerDeleted", {
    id: banner._id,
    title: banner.title,
  });

  return banner;
};

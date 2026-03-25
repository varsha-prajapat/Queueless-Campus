// services/bannerService.js
import Banner from "../models/bannerModel.js";
import mongoose from "mongoose";
import { createNotification } from "./notificationService.js";

/**
 * 🎯 Helper: resolve target roles for notification
 */
const resolveRoles = (targetRole) => {
  if (!targetRole) return [];
  if (Array.isArray(targetRole)) return targetRole;
  return [targetRole];
};

/**
 * 🎯 Helper: send banner notifications
 */
const sendBannerNotification = async ({ banner, io }) => {
  if (!banner) return;

  const roles = resolveRoles(banner.targetRole);
  const userIds = banner.departmentId?.staffIds || []; // if departmentId has staffIds

  try {
    const notification = await createNotification({
      title: `Banner: ${banner.title}`,
      message: banner.message,
      roles: roles.length ? roles : ["ALL"],
      userIds,
    });

    if (io) {
      // Emit to roles
      roles.forEach((role) =>
        io.to(`role_${role}`).emit("notifications:update", [notification]),
      );
      // Emit to department staff
      userIds.forEach((id) =>
        io.to(id.toString()).emit("notifications:update", [notification]),
      );
    }
  } catch (err) {
    console.error("Notification Error (banner):", err.message);
  }
};

/**
 * ➕ Create a banner
 */
export const createBanner = async (data, io = null) => {
  if (!data.title || !data.message)
    throw new Error("Banner requires title and message");

  const banner = await Banner.create(data);

  // 🔔 Send notification
  await sendBannerNotification({ banner, io });

  io?.emit("bannerCreated", banner);

  return banner;
};

/**
 * 📄 Get Banners (filtered by role + department)
 */
export const getBanners = async (role, departmentId) => {
  // Admin sees all
  if (role === "ADMIN") return await Banner.find().sort({ createdAt: -1 });

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
  if (!mongoose.Types.ObjectId.isValid(id))
    throw new Error("Invalid banner ID");
  return await Banner.findById(id);
};

/**
 * ✏️ Update banner
 */
export const updateBanner = async (id, data, io = null) => {
  if (!mongoose.Types.ObjectId.isValid(id))
    throw new Error("Invalid banner ID");

  const banner = await Banner.findByIdAndUpdate(id, data, {
    new: true,
    runValidators: true,
  });
  if (!banner) return null;

  await sendBannerNotification({ banner, io });

  io?.emit("bannerUpdated", banner);

  return banner;
};

/**
 * ❌ Delete banner
 */
export const deleteBanner = async (id, io = null) => {
  if (!mongoose.Types.ObjectId.isValid(id))
    throw new Error("Invalid banner ID");

  const banner = await Banner.findByIdAndDelete(id);
  if (!banner) return null;

  // 🔔 Notify roles and department staff
  await sendBannerNotification({ banner, io });

  io?.emit("bannerDeleted", { id: banner._id, title: banner.title });

  return banner;
};

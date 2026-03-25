// services/adminService.js
import User from "../models/userModel.js";

/**
 * Get Admin Contact Info
 * Only returns active admins
 */
export const getAdminContact = async () => {
  try {
    // Fetch first active admin
    const admin = await User.findOne({
      role: "ADMIN",
      isActive: true,
    }).select("name email phone profileImage");

    if (!admin) return null;

    return {
      name: admin.name,
      email: admin.email,
      phone: admin.phone || "Not available",
      profileImage: admin.profileImage || "",
    };
  } catch (error) {
    console.error("Admin Service Error:", error);
    throw new Error("Failed to fetch admin contact");
  }
};

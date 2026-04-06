import bcrypt from "bcrypt";
import mongoose from "mongoose";
import User from "../models/UserModel.js";
import { env } from "../config/env.js";
import ApiError from "../utils/ApiError.js";
import { STATUS } from "../config/status.js";
import { sendInviteEmail } from "./send_invite_Email.js";
import jwt from "jsonwebtoken";
import Department from "../models/DepartmentModel.js";

export const adminService = {
  // ================= INVITE USER =================
  inviteUser: async ({ email, role, departmentId }) => {
    /* ================= 🔍 VALIDATION ================= */

    if (!email || !role) {
      throw new ApiError(
        STATUS.ERROR.BAD_REQUEST.statusCode,
        "Email and role are required",
      );
    }

    email = email.toLowerCase().trim();

    const existingUser = await User.findOne({ email });

    if (existingUser) {
      throw new ApiError(
        STATUS.ERROR.CONFLICT.statusCode,
        "User already exists",
      );
    }

    const allowedRoles = ["STUDENT", "STAFF", "ADMIN"];

    if (!allowedRoles.includes(role)) {
      throw new ApiError(STATUS.ERROR.BAD_REQUEST.statusCode, "Invalid role");
    }

    /* ================= 🏢 DEPARTMENT FETCH ================= */

    let departmentName = null;

    if (departmentId) {
      if (!mongoose.Types.ObjectId.isValid(departmentId)) {
        throw new ApiError(
          STATUS.ERROR.BAD_REQUEST.statusCode,
          "Invalid department ID",
        );
      }

      const department = await Department.findById(departmentId);

      if (!department) {
        throw new ApiError(
          STATUS.ERROR.NOT_FOUND.statusCode,
          "Department not found",
        );
      }

      departmentName = department.name; // ✅ name extract
    }

    /* ================= 🔐 TOKEN GENERATION ================= */

    const token = jwt.sign(
      {
        email,
        role,
        departmentId: departmentId || null,
        department: departmentName, // ✅ store name also
        type: "invite",
      },
      env.JWT_INVITE_SECRET,
      { expiresIn: "1h" },
    );

    /* ================= 🔗 INVITE LINK ================= */

    const registrationLink = `${env.BASE_URL}${env.API_PREFIX}/invite/${token}`;

    /* ================= 📧 SEND EMAIL ================= */

    await sendInviteEmail({
      email,
      registrationLink,
      role,
      department: departmentName, // ✅ email me name bhejo
    });

    /* ================= ✅ RESPONSE ================= */

    return {
      success: true,
      message: "Invitation sent successfully",
    };
  },
  // ================= SEED SUPER ADMIN =================
  seedSuperAdmin: async () => {
    const enabled = String(env.SUPER_ADMIN_ENABLED || "true") === "true";

    if (!enabled) return;

    const email = (env.SUPER_ADMIN_EMAIL || "").toLowerCase().trim();
    const password = env.SUPER_ADMIN_PASSWORD;
    const name = env.SUPER_ADMIN_NAME || "Super Admin";

    if (!email || !password) {
      console.log("⚠️ Super Admin seed skipped: missing credentials");
      return;
    }

    const existing = await User.findOne({ email });

    if (existing) {
      let changed = false;

      if (existing.role !== "ADMIN") {
        existing.role = "ADMIN";
        changed = true;
      }

      if (!existing.isSuperAdmin) {
        existing.isSuperAdmin = true;
        changed = true;
      }

      if (!existing.isEmailVerified) {
        existing.isEmailVerified = true;
        changed = true;
      }

      if (!existing.isActive) {
        existing.isActive = true;
        changed = true;
      }

      if (changed) await existing.save();

      console.log("✅ Super Admin already exists");
      return;
    }

    const saltRounds = Number(env.BCRYPT_SALT_ROUNDS) || 10;

    const passwordHash = await bcrypt.hash(password, saltRounds);

    await User.create({
      name,
      email,
      passwordHash,
      role: "ADMIN",
      isSuperAdmin: true,
      isEmailVerified: true,
      isActive: true,
    });

    console.log("✅ Super Admin created successfully");
  },

  // ================= DASHBOARD STATS =================
  getDashboardStats: async () => {
    const totalUsers = await User.countDocuments({});
    const activeUsers = await User.countDocuments({ isActive: true });
    const unverifiedUsers = await User.countDocuments({
      isEmailVerified: false,
    });

    return {
      users: {
        total: totalUsers,
        active: activeUsers,
        unverified: unverifiedUsers,
      },
    };
  },

  // ================= LIST USERS =================
  listUsers: async () => {
    return User.find({})
      .select("-passwordHash")
      .populate("departmentId", "name")
      .sort({ createdAt: -1 });
  },

  // ================= UPDATE USER =================
  updateUserByAdmin: async (userId, payload) => {
    const user = await User.findById(userId);

    if (!user) {
      throw new ApiError(STATUS.NOT_FOUND.statusCode, "User not found");
    }

    if (user.isSuperAdmin) {
      if (payload.role && payload.role !== "ADMIN") {
        throw new ApiError(
          STATUS.FORBIDDEN.statusCode,
          "Super Admin role cannot be changed",
        );
      }

      if (payload.isActive === false) {
        throw new ApiError(
          STATUS.FORBIDDEN.statusCode,
          "Super Admin cannot be deactivated",
        );
      }
    }

    const allowed = [
      "name",
      "phone",
      "departmentId",
      "role",
      "isActive",
      "isEmailVerified",
    ];

    for (const key of Object.keys(payload)) {
      if (allowed.includes(key)) {
        user[key] = payload[key];
      }
    }

    await user.save();

    return User.findById(userId)
      .select("-passwordHash")
      .populate("departmentId", "name");
  },

  // ================= DELETE USER =================
  deleteUserById: async (userId) => {
    const user = await User.findById(userId);

    if (!user) {
      throw new ApiError(STATUS.NOT_FOUND.statusCode, "User not found");
    }

    if (user.role === "ADMIN") {
      throw new ApiError(
        STATUS.FORBIDDEN.statusCode,
        "Admin users cannot be deleted",
      );
    }

    await user.deleteOne();

    return {
      success: true,
      message: "User deleted successfully",
      name: user.name,
    };
  },

  // ================= BLOCK USER =================
  blockUser: async (userId) => {
    const user = await User.findById(userId);

    if (!user) {
      throw new ApiError(STATUS.NOT_FOUND.statusCode, "User not found");
    }

    if (!user.isActive) {
      throw new ApiError(
        STATUS.ERROR.BAD_REQUEST.statusCode,
        "User already blocked",
      );
    }

    user.isActive = false;

    await user.save();

    return {
      success: true,
      message: "User blocked successfully",
      name: user.name,
    };
  },

  // ================= UNBLOCK USER =================
  unblockUser: async (userId) => {
    const user = await User.findById(userId);

    if (!user) {
      throw new ApiError(STATUS.NOT_FOUND.statusCode, "User not found");
    }

    user.isActive = true;

    await user.save();

    return {
      success: true,
      message: "User unblocked successfully",
      name: user.name,
    };
  },

  getStaffByDepartment: async (departmentId) => {
    if (!mongoose.Types.ObjectId.isValid(departmentId)) {
      throw new ApiError(
        STATUS.ERROR.BAD_REQUEST.statusCode,
        "Invalid department ID",
      );
    }

    const staff = await User.find({
      role: "STAFF",
      departmentId: new mongoose.Types.ObjectId(departmentId),
      isActive: true,
    })
      .select("-passwordHash")
      .populate("departmentId", "name");

    return staff;
  },
};

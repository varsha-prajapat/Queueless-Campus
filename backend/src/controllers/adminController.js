import mongoose from "mongoose";
import { adminService } from "../services/adminService.js";
import { createNotification } from "../services/notificationService.js";

export const adminController = {
  // ================= INVITE USER =================
  inviteUser: async (req, res, next) => {
    try {
      const result = await adminService.inviteUser(req.body);

      if (req.io) req.io.emit("userInvited", result);

      res.status(201).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  },

  // ================= DASHBOARD =================
  dashboardStats: async (req, res, next) => {
    try {
      const data = await adminService.getDashboardStats();

      res.status(200).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  },

  // ================= GET USERS =================
  getAllUsers: async (req, res, next) => {
    try {
      const users = await adminService.listUsers();

      const filteredUsers = users.filter((user) => user.role !== "ADMIN");

      res.status(200).json({
        success: true,
        data: filteredUsers,
      });
    } catch (error) {
      next(error);
    }
  },

  // ================= UPDATE USER =================
  updateUser: async (req, res, next) => {
    try {
      const { id } = req.params;
      const { role, departmentId, isActive } = req.body;

      if (!mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({
          success: false,
          message: "Invalid user ID",
        });
      }

      if (departmentId && !mongoose.Types.ObjectId.isValid(departmentId)) {
        return res.status(400).json({
          success: false,
          message: "Invalid department ID",
        });
      }

      const updatedUser = await adminService.updateUserByAdmin(id, {
        role,
        departmentId: departmentId,
        isActive,
      });

      if (req.io) req.io.emit("userUpdated", updatedUser);

      await createNotification(req.io, {
        title: "User Updated",
        message: `User "${updatedUser.name}" has been updated.`,
        roles: ["ADMIN"],
        isGlobal: false,
      });

      res.status(200).json({
        success: true,
        message: "User updated successfully",
        data: updatedUser,
      });
    } catch (error) {
      next(error);
    }
  },

  // ================= DELETE USER =================
  deleteUser: async (req, res, next) => {
    try {
      const { id } = req.params;

      if (!mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({
          success: false,
          message: "Invalid user ID",
        });
      }

      const deletedUser = await adminService.deleteUserById(id);

      if (req.io) req.io.emit("userDeleted", { id });

      await createNotification(req.io, {
        title: "User Deleted",
        message: `User "${deletedUser.name}" has been deleted.`,
        roles: ["ADMIN"],
        isGlobal: false,
      });

      res.status(200).json({
        success: true,
        message: "User deleted successfully",
      });
    } catch (error) {
      next(error);
    }
  },

  // ================= BLOCK USER =================
  blockUser: async (req, res, next) => {
    try {
      const { id } = req.params;

      if (!mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({
          success: false,
          message: "Invalid user ID",
        });
      }

      const blockedUser = await adminService.blockUser(id);

      if (req.io) req.io.emit("userBlocked", blockedUser);

      await createNotification(req.io, {
        title: "User Blocked",
        message: `User "${blockedUser.name}" has been blocked.`,
        roles: ["ADMIN"],
        isGlobal: false,
      });

      res.status(200).json({
        success: true,
        data: blockedUser,
      });
    } catch (error) {
      next(error);
    }
  },

  // ================= UNBLOCK USER =================
  unblockUser: async (req, res, next) => {
    try {
      const { id } = req.params;

      if (!mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({
          success: false,
          message: "Invalid user ID",
        });
      }

      const unblockedUser = await adminService.unblockUser(id);

      if (req.io) req.io.emit("userUnblocked", unblockedUser);

      await createNotification(req.io, {
        title: "User Unblocked",
        message: `User "${unblockedUser.name}" has been unblocked.`,
        roles: ["ADMIN"],
        isGlobal: false,
      });

      res.status(200).json({
        success: true,
        data: unblockedUser,
      });
    } catch (error) {
      next(error);
    }
  },

  // ================= STAFF BY DEPARTMENT =================
  getStaffByDepartment: async (req, res, next) => {
    try {
      const { departmentId } = req.params;

      if (!mongoose.Types.ObjectId.isValid(departmentId)) {
        return res.status(400).json({
          success: false,
          message: "Invalid department ID",
        });
      }

      const staff = await adminService.getStaffByDepartment(departmentId);

      res.status(200).json({
        success: true,
        data: staff,
      });
    } catch (error) {
      next(error);
    }
  },
};

import { Router } from "express";

import { requireAuth } from "../middlewares/authMiddleware.js";
import { uploadProfile } from "../middlewares/multerMiddleware.js";
import { validate } from "../middlewares/validateMiddleware.js";
import { editProfileSchema } from "../Validators/editprofileValidation.js";

// 👤 Profile
import {
  getMyProfile,
  updateMyProfile,
} from "../controllers/profile_controller.js";

// 🔔 Notifications
import {
  getMyNotifications,
  deleteNotification,
  deleteAllNotifications,
  markAllNotificationsRead,
  getUnreadNotificationCount,
} from "../controllers/notificationController.js";

// 🏢 Department & Services
import { getDepartmentById } from "../controllers/departmentController.js";
import {
  getActiveServices,
  getServiceById,
} from "../controllers/serviceController.js";

// 🎫 Queue
import { getQueueByCounter } from "../controllers/tokencommon.js";

// 🖼️ Banner
import { getBanners } from "../controllers/bannerController.js";

const router = Router();

// 🔒 All routes require login
router.use(requireAuth);

// ==================== 🔔 NOTIFICATIONS ====================

// 📥 Get all notifications (with read/unread)
router.get("/notifications", getMyNotifications);

// 👁️ Mark notification as read
router.patch("/notifications/read-all", markAllNotificationsRead);

router.get("/notifications/unread-count", getUnreadNotificationCount);

// ❌ Delete single notification (only for current user)
router.delete("/notifications/:id", deleteNotification);

// ❌ Delete all notifications (only for current user)
router.delete("/notifications", deleteAllNotifications);

// ==================== 🏢 SERVICES & DEPARTMENT ====================

// Get all active services
router.get("/service", getActiveServices);

// Get service by ID
router.get("/service/:id", getServiceById);

// Get department by ID
router.get("/department/:id", getDepartmentById);

// ==================== 👤 PROFILE ====================

// Get logged-in user profile
router.get("/me", getMyProfile);

// Update profile
router.put(
  "/me",
  uploadProfile.single("profileImage"),
  validate(editProfileSchema),
  updateMyProfile,
);

// ==================== 🎫 QUEUE ====================

// Get queue by counter
router.get("/queue/:counterId", getQueueByCounter);

// ==================== 🖼️ BANNERS ====================

// Get banners
router.get("/banner", getBanners);

export default router;

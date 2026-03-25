import { Router } from "express";
import {
  getMyProfile,
  updateMyProfile,
} from "../controllers/profile_controller.js";
import { uploadProfile } from "../middlewares/multerMiddleware.js";
import { editProfileSchema } from "../Validators/editprofileValidation.js";
import { validate } from "../middlewares/validateMiddleware.js";
import {
  getMyNotifications,
  deleteNotification,
  deleteAllNotifications,
  setNotificationExpiry,
} from "../controllers/notificationController.js";
import { getDepartmentById } from "../controllers/departmentController.js";
import { getActiveServices } from "../controllers/serviceController.js";

import { getQueueByCounter } from "../controllers/tokencommon.js";
import { requireAuth } from "../middlewares/authMiddleware.js";
import { getBanners } from "../controllers/bannerController.js";
import { getServiceById } from "../controllers/serviceController.js";

const router = Router();

router.use(requireAuth);

// 👨‍🎓👩‍🏫 Shared access

// 🟢 Get all notifications for logged-in user
router.get("/notifications", getMyNotifications);

// 🟢 Delete a single notification by ID
router.delete("/notifications/:id", deleteNotification);

// 🟢 Delete all notifications for logged-in user
router.delete("/notifications", deleteAllNotifications);

router.patch("/notifications/:id/expiry", setNotificationExpiry);

router.get("/service", getActiveServices);
router.get("/department/:id", getDepartmentById);

// 👤 Profile
router.get("/me", getMyProfile);
router.get("/banner", getBanners);
router.get("/service/:id", getServiceById);
router.put(
  "/me",
  uploadProfile.single("profileImage"),
  validate(editProfileSchema),
  updateMyProfile,
);
router.get("/queue/:counterId", getQueueByCounter);

export default router;

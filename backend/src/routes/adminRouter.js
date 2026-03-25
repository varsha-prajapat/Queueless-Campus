import { Router } from "express";
import asyncHandler from "../utils/asyncHandler.js";
import { validate } from "../middlewares/validateMiddleware.js";
import { adminController } from "../controllers/adminController.js";
import { getMyNotifications } from "../controllers/notificationController.js";
import { notificationJoiSchema } from "../Validators/notificationValidation.js";
import { requireAuth } from "../middlewares/authMiddleware.js";
import { requireRole } from "../middlewares/roleMiddleware.js";
import { bannerJoiSchema } from "../Validators/bannerValidation.js";
import { departmentJoiSchema } from "../Validators/departmentValidation.js";
import { bannerUpload } from "../middlewares/bannerUpload.js";
import {
  createService,
  getAllServices,
  getServiceById,
  updateService,
  deleteService,
} from "../controllers/serviceController.js";
import {
  createDepartment,
  getDepartmentById,
  updateDepartment,
  deleteDepartment,
  getDepartments,
} from "../controllers/departmentController.js";
import { getAdminDashboardInfoToken } from "../controllers/tokenadminController.js";

import {
  createBanner,
  getBanners,
  getBannerById,
  updateBanner,
  deleteBanner,
} from "../controllers/bannerController.js";
import {
  createCounter,
  getAllCounters,
  getCounterById,
  updateCounter,
  deleteCounter,
} from "../controllers/counterController.js";

const router = Router();

router.use(requireAuth, requireRole("ADMIN"));

// 🔔 Banners
// 🔔 Banner routes
router.post(
  "/banner",
  bannerUpload.single("image"),
  validate(bannerJoiSchema),
  createBanner,
);
router.get("/banner", getBanners);
router.get("/banner/:id", getBannerById);
router.put("/banner/:id", bannerUpload.single("image"), updateBanner);

router.delete("/banner/:id", deleteBanner);

// 🏫 Departments
router.post("/department", validate(departmentJoiSchema), createDepartment);
router.get("/department", getDepartments);
router.put("/department/:id", updateDepartment);
router.delete("/department/:id", deleteDepartment);

// 🧑‍💼 Users
router.get("/users", asyncHandler(adminController.getAllUsers));
router.patch("/users/:id", asyncHandler(adminController.updateUser));
router.delete("/users/:id", asyncHandler(adminController.deleteUser));
router.get("/staff/:departmentId", adminController.getStaffByDepartment);

// 📊 Dashboard
router.get("/dashboard-stats", asyncHandler(adminController.dashboardStats));

// Service CRUD
router.post("/service", createService);
router.put("/service/:id", updateService);
router.delete("/service/:id", deleteService);
router.get("/service", getAllServices);
router.get("/service/:id", getServiceById);

//counter
router.post("/counter", createCounter);
router.put("/counter/:id", updateCounter);
router.delete("/counter/:id", deleteCounter);
router.get("/counter", getAllCounters);
router.get("/counter/:id", getCounterById);

// Dashboard
router.get("/dashboardtoken", getAdminDashboardInfoToken);

// 🔔 Notifications

router.get(
  "/notifications",
  validate(notificationJoiSchema),
  getMyNotifications,
);

// Block / Unblock user

// ⛔ Block / Unblock
router.patch("/users/:id/block", asyncHandler(adminController.blockUser));
router.patch("/users/:id/unblock", asyncHandler(adminController.unblockUser));
router.post("/register-invite", asyncHandler(adminController.inviteUser));

export default router;

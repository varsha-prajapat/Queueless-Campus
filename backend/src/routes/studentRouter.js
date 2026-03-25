import { Router } from "express";

import { requireAuth } from "../middlewares/authMiddleware.js";
import { requireRole } from "../middlewares/roleMiddleware.js";
import { isActiveUser } from "../middlewares/isActive.middleware.js";

import {
  bookToken,
  confirmPaymentCtrl,
  getTokenStats,
  getMyTokens,
  cancelTokenCtrl, // 🔹 import cancel token controller
} from "../controllers/tokenstudentController.js";

// ✅ Import department-based services controller
import { getServicesByDepartment } from "../controllers/serviceController.js";

import { getAdminContactController } from "../controllers/adminContactControlller.js";

const router = Router();

/// =============================
/// 🔐 Apply Student Middleware
/// =============================r
router.use(requireAuth, requireRole("STUDENT"), isActiveUser);

/// =============================
/// 📌 Get Services by Department
/// Example: GET /api/student/services/:departmentId
/// =============================
router.get("/services/:departmentId", getServicesByDepartment);

/// =============================
/// 📌 Book Token
/// Example: POST /api/student/token
/// =============================
router.post("/token", bookToken);

/// =============================
/// 📌 Confirm Payment
/// Example: POST /api/student/token/payment/confirm
// /// =============================
router.post("/token/payment/confirm", confirmPaymentCtrl);

/// =============================
/// 📌 Token Stats (Dashboard)
/// Example: GET /api/student/token/stats
/// =============================
router.get("/token/stats", getTokenStats);

/// =============================
/// 📌 Get My Tokens
/// Example: GET /api/student/token/my-tokens
/// =============================
router.get("/token/my-tokens", getMyTokens);

/// =============================
/// 📌 Cancel Token
/// Example: POST /api/student/token/cancel
/// =============================
router.post("/token/cancel", cancelTokenCtrl);

/// =============================
/// 📌 Get Admin Contact
/// Example: GET /api/student/contact
/// =============================
router.get("/contact", getAdminContactController);

export default router;

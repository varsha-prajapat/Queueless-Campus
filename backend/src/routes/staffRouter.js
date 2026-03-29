// routes/tokenStaffRoutes.js

import express from "express";
import { requireAuth } from "../middlewares/authMiddleware.js";
import { requireRole } from "../middlewares/roleMiddleware.js";
import { isActiveUser } from "../middlewares/isActive.middleware.js";
import { getAdminContactController } from "../controllers/adminContactControlller.js";

import {
  getQueue,
  callNext,
  completeTokenCtrl,
  skipTokenCtrl, // ✅ added
  getTokenStatsCtrl,
  getTokenStatsDetailedCtrl,
} from "../controllers/tokenstaffController.js";

import { getCountersByStaffId } from "../controllers/counterController.js";

const router = express.Router();

/* ================= APPLY MIDDLEWARES ================= */
router.use(requireAuth, requireRole("STAFF"), isActiveUser);

/* ================= STAFF TOKEN ROUTES ================= */

// 📌 Get Queue of Tokens for the Staff's Counter
router.get("/queue", getQueue);

// 📌 Get Token Stats (Current / Next / Waiting / Served Today)
router.get("/stats", getTokenStatsCtrl);

// 📌 Get Detailed Token Stats (Summary + All Tokens)
router.get("/stats/detailed", getTokenStatsDetailedCtrl);

// 📌 Get Counters Assigned to a Staff Member
router.get("/counter/:staffId", getCountersByStaffId);

// 📌 Call Next Token in the Queue
router.post("/call-next", callNext);

// 📌 Complete a Token
router.post("/token/complete", completeTokenCtrl);

// ✅ NEW: Skip Token (Manual)
router.post("/token/skip", skipTokenCtrl);

router.get("/stats/detailed", getTokenStatsDetailedCtrl);

/// =============================
/// 📌 Get Admin Contact
/// Example: GET /api/student/contact
/// =============================
router.get("/contact", getAdminContactController);

export default router;

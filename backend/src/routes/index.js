import { Router } from "express";
import path from "path";
import { fileURLToPath } from "url";
import { getDepartments } from "../controllers/departmentController.js";

import authRouter from "./authRouter.js";
import adminRouter from "./adminRouter.js";
import staffRouter from "./staffRouter.js";
import studentRouter from "./studentRouter.js";
import commonRouter from "./common.js";
import { notFound, errorHandler } from "../middlewares/error_middleware.js";
import { handleInvite } from "../controllers/inviteController.js";

const router = Router();

// ESM-safe __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 🌍 Public routes
router.get("/health", (req, res) => {
  res.json({ ok: true, message: "QueueLess API running" });
});

router.get("/invite/:inviteToken", handleInvite);

router.get("/register", (req, res) => {
  res.sendFile(path.join(__dirname, "../../public/register.html"));
});

// 🔐 Auth
router.use("/auth", authRouter);

// 🛡 Role-based protected routes
router.use("/admin", adminRouter);
router.use("/staff", staffRouter);
router.use("/student", studentRouter);

// 👥 Any authenticated user
router.use("/common", commonRouter);

router.get("/departments", getDepartments);

router.use(errorHandler);

router.use(notFound);

export default router;

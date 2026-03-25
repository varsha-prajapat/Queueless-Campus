import { Router } from "express";
import asyncHandler from "../utils/asyncHandler.js";
import { validate } from "../middlewares/validateMiddleware.js";
import { authController } from "../controllers/authController.js";
import { registerSchema, loginSchema } from "../Validators/userValidator.js";
import { verifyOtpController } from "../controllers/verifyOtpController.js";
import { userValidationSchema } from "../Validators/otpValidation.js";
import { requireRefreshToken } from "../middlewares/requireRefreshToken.js";
import { refreshAccessToken } from "../controllers/refreshController.js";

const router = Router();

router.post("/refresh", requireRefreshToken, refreshAccessToken);

router.post(
  "/register",
  validate(registerSchema),
  asyncHandler(authController.register),
);

router.post(
  "/login",
  validate(loginSchema),
  asyncHandler(authController.login),
);

router.post(
  "/registerbyinvite",
  asyncHandler(authController.registerUserWithInvite),
);

router.post(
  "/otp",
  validate(userValidationSchema),
  asyncHandler(verifyOtpController),
);

export default router;

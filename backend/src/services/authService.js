import bcrypt from "bcrypt";
import User from "../models/UserModel.js";
import { env } from "../config/env.js";
import ApiError from "../utils/ApiError.js";
import { STATUS } from "../config/status.js";
import { sendOtpService } from "../services/otp_service.js";
import { suceessful_register_invite } from "../utils/successful_register_invite.js";

export const authService = {
  // ================= REGISTER USING INVITE =================
  registerUserWithInvite: async ({ tokenData, name, password }) => {
    if (!tokenData?.email || !tokenData?.role) {
      throw new ApiError(
        STATUS.ERROR.BAD_REQUEST.statusCode,
        "Invalid invitation token",
      );
    }

    const existingUser = await User.findOne({ email: tokenData.email });

    if (existingUser) {
      throw new ApiError(
        STATUS.ERROR.CONFLICT.statusCode,
        "User already registered",
      );
    }

    const hashedPassword = await bcrypt.hash(
      password,
      Number(env.BCRYPT_SALT_ROUNDS) || 10,
    );

    const user = await User.create({
      name,
      email: tokenData.email.toLowerCase().trim(),
      passwordHash: hashedPassword,
      role: tokenData.role,
      departmentId: tokenData.departmentId || null,
      isEmailVerified: true,
      isActive: true,
    });

    await suceessful_register_invite(name, tokenData.email);

    return {
      success: true,
      message: "User registered successfully",
      userId: user._id,
      role: user.role,
    };
  },

  // ================= NORMAL REGISTER =================
  register: async ({ name, email, password, phone, departmentId }) => {
    console.log(departmentId);
    const normalizedEmail = email.toLowerCase().trim();

    const existing = await User.findOne({ email: normalizedEmail });

    if (existing) {
      throw new ApiError(
        STATUS.ERROR.CONFLICT.statusCode,
        "Email already registered",
      );
    }

    const passwordHash = await bcrypt.hash(
      password,
      Number(env.BCRYPT_SALT_ROUNDS) || 10,
    );

    const user = await User.create({
      name,
      email: normalizedEmail,
      passwordHash,
      phone: phone || null,
      departmentId: departmentId || null,
      role: "STUDENT",
      isEmailVerified: false,
      isActive: true,
    });

    sendOtpService(user.email, "EMAIL_VERIFICATION").catch((err) =>
      console.error("OTP email failed:", err),
    );

    return {
      success: true,
      userId: user._id,
      email: user.email,
      isEmailVerified: user.isEmailVerified,
      message: "OTP sent for email verification",
    };
  },

  // ================= LOGIN =================
  login: async ({ email, password }) => {
    const normalizedEmail = email.toLowerCase().trim();

    const user = await User.findOne({ email: normalizedEmail }).select(
      "+passwordHash",
    );

    if (!user) {
      throw new ApiError(
        STATUS.ERROR.UNAUTHORIZED.statusCode,
        "Invalid email or password",
      );
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);

    if (!isMatch) {
      throw new ApiError(
        STATUS.ERROR.UNAUTHORIZED.statusCode,
        "Invalid email or password",
      );
    }

    if (!user.isEmailVerified) {
      throw new ApiError(
        STATUS.ERROR.FORBIDDEN.statusCode,
        "Email not verified",
      );
    }

    if (!user.isActive) {
      throw new ApiError(
        STATUS.ERROR.FORBIDDEN.statusCode,
        "Account is blocked",
      );
    }

    sendOtpService(user.email, "LOGIN_2FA").catch((err) =>
      console.error("OTP email failed:", err),
    );

    return {
      success: true,
      message: "OTP sent to email",
      userId: user._id,
    };
  },
};

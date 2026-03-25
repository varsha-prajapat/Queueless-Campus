import ApiError from "../utils/ApiError.js";
import { generate_Otp } from "../utils/otp.js";
import Otp from "../models/OtpModel.js";
import { env } from "../config/env.js";
import bcrypt from "bcrypt";
import { otpMailTemplate } from "../utils/mailTemplates_otp.js";
import { signAccessToken, signRefreshToken } from "../utils/jwt.js";
import User from "../models/UserModel.js";
import { sendMail } from "../utils/mailer.js";

export const sendOtpService = async (email, purpose) => {
  email = email.toLowerCase().trim();

  const otp = generate_Otp();
  console.log("Generated OTP:", otp);

  const otphash = await bcrypt.hash(otp, env.BCRYPT_SALT_ROUNDS);
  const expiresAt = new Date(Date.now() + env.OTP_EXPIRE_MINUTES * 60 * 1000);

  // Remove any previous unverified OTPs for this email/purpose
  await Otp.deleteMany({ email, purpose, verifiedAt: null });

  // Create a new OTP record
  await Otp.create({
    email,
    purpose,
    otphash,
    expiresAt,
    attempts: 0,
  });

  // Safe sendMail
  try {
    await sendMail({
      to: email,
      subject: "Your OTP Code",
      html: otpMailTemplate({ email, otp }).html,
    });
    console.log("OTP email sent successfully to", email);
  } catch (err) {
    console.error("Failed to send OTP email:", err.message);
    // Optionally, you can throw a custom error if you want to notify the client
    // throw new ApiError(500, "Failed to send OTP email. Please try again.");
  }
};

export const verify_Otp_service = async ({ email, otp, purpose }) => {
  email = email.toLowerCase().trim();
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return { success: false, message: "User is not registered" };
    }

    const allowedPurposes = ["EMAIL_VERIFICATION", "LOGIN_2FA"];
    if (!allowedPurposes.includes(purpose)) {
      return { success: false, message: "Invalid request" };
    }

    const now = new Date();

    const record = await Otp.findOne({
      email,
      purpose,
      verifiedAt: null,
      expiresAt: { $gt: now },
    }).sort({ createdAt: -1 });

    // 🔒 Generic failure
    if (!record) {
      return {
        success: false,
        message: "Invalid or expired verification code",
      };
    }

    // 🚫 Max attempts reached
    if (record.attempts >= env.OTP_MAX_ATTEMPTS) {
      await Otp.updateMany(
        { email, purpose, verifiedAt: null },
        { expiresAt: now },
      );
      return {
        success: false,
        message: "Too many failed attempts. Request a new code.",
      };
    }

    const isMatch = await bcrypt.compare(otp.trim(), record.otphash);

    // ❌ Wrong OTP
    if (!isMatch) {
      await Otp.updateOne({ _id: record._id }, { $inc: { attempts: 1 } });
      return {
        success: false,
        message: "Invalid or expired verification code",
      };
    }

    // ✅ Mark OTP as used (single-use)
    record.verifiedAt = now;
    await record.save();

    // -------------------------
    // 🟢 EMAIL VERIFICATION
    // -------------------------
    if (purpose === "EMAIL_VERIFICATION") {
      const userUpdated = await User.findOneAndUpdate(
        { email },
        {
          isEmailVerified: true,
          isActive: true,
        },
      );

      if (!userUpdated) {
        return {
          success: false,
          message: "Invalid or expired verification code",
        };
      }

      return { success: true, message: "Email verified successfully" };
    }

    // -------------------------
    // 🔵 LOGIN 2FA
    // -------------------------
    if (purpose === "LOGIN_2FA") {
      const userVerified = await User.findOne({ email });

      if (
        !userVerified ||
        !userVerified.isEmailVerified ||
        !userVerified.isActive
      ) {
        return { success: false, message: "Unable to complete login" };
      }

      userVerified.lastLoginAt = now;
      await userVerified.save();

      const accessToken = signAccessToken({
        userId: userVerified._id,
        name: userVerified.name,
        email: userVerified.email,
        role: userVerified.role,
        isActive: userVerified.isActive,
      });

      const refreshToken = signRefreshToken({
        userId: userVerified._id,
        email: userVerified.email,
        isActive: userVerified.isActive,
      });

      return {
        success: true,
        message: "Login successful",
        accessToken,
        refreshToken,
      };
    }

    return { success: false, message: "Invalid request" };
  } catch (err) {
    console.error("verify_Otp_service error:", err.message);
    return {
      success: false,
      message: "Something went wrong. Please try again.",
    };
  }
};

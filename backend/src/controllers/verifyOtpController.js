import { verify_Otp_service } from "../services/otp_service.js";

export const verifyOtpController = async (req, res) => {
  const { email, otp, purpose } = req.body;

  const result = await verify_Otp_service({
    email,
    otp,
    purpose,
  });

  // ❌ OTP failed
  if (!result.success) {
    return res.status(400).json({
      success: false,
      message: result.message,
    });
  }

  // 🔵 LOGIN FLOW → RETURN TOKENS (NO COOKIES)
  if (purpose === "LOGIN_2FA") {
    return res.status(200).json({
      success: true,
      message: result.message,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      purpose,
    });
  }

  // 🟢 REGISTER / EMAIL VERIFICATION → no tokens
  return res.status(200).json({
    success: true,
    message: result.message,
    purpose,
  });
};

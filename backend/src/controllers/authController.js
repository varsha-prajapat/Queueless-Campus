import { authService } from "../services/authService.js";
import { STATUS } from "../config/status.js";
import { verifyInviteToken } from "../utils/jwt.js";

export const authController = {
  registerUserWithInvite: async (req, res) => {
    try {
      const { name, password } = req.body;
      const token = req.cookies?.inviteToken;

      // 1️⃣ Check token
      if (!token) {
        return res
          .status(403)
          .json({ message: "You must be invited by an Admin" });
      }

      // 2️⃣ Verify token
      let decoded;
      try {
        decoded = verifyInviteToken(token, process.env.JWT_INVITE_SECRET);
      } catch (err) {
        return res
          .status(401)
          .json({ message: "Invalid or expired invite token" });
      }

      if (!decoded?.email) {
        return res.status(400).json({ message: "Invite token missing email" });
      }

      // 3️⃣ Create user via service
      const user = await authService.registerUserWithInvite({
        tokenData: decoded,
        name,
        password,
      });

      // 4️⃣ Clear invite cookie AFTER success
      res.clearCookie("inviteToken", {
        httpOnly: true,
        sameSite: "lax",
        path: "/",
      });

      return res.status(201).json({
        message: "Registration successful",
        user,
      });
    } catch (err) {
      console.error("Register by invite error:", err);
      return res.status(500).json({
        message: "Registration failed",
        error: err.message,
      });
    }
  },
  register: async (req, res) => {
    const data = await authService.register(req.body);
    res.status(STATUS.SUCCESS.CREATED.statusCode).json({
      success: true,
      message: STATUS.SUCCESS.CREATED.message,
      data,
    });
  },
  login: async (req, res) => {
    const data = await authService.login(req.body);

    res.status(STATUS.SUCCESS.CREATED.statusCode).json({
      success: true,
      message: STATUS.SUCCESS.CREATED.message,
      data,
    });
  },
};

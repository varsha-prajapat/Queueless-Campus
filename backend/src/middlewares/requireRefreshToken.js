import jwt from "jsonwebtoken";
import { env } from "../config/env.js";

export const requireRefreshToken = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader?.startsWith("Bearer ")) {
      return res.status(401).json({ message: "No refresh token provided" });
    }

    const refreshToken = authHeader.split(" ")[1];
    const decoded = jwt.verify(refreshToken, env.JWT_REFRESH_SECRET);

    req.userId = decoded.userId;
    next();
  } catch {
    return res.status(401).json({
      message: "Refresh token expired or invalid",
    });
  }
};

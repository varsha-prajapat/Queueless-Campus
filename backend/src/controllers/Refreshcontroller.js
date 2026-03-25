import User from "../models/UserModel.js";
import { signAccessToken } from "../utils/jwt.js";

export const refreshAccessToken = async (req, res) => {
  const user = await User.findById(req.userId);
  if (!user) {
    return res.status(401).json({
      success: false,
      message: "User not found",
    });
  }

  // 🔥 SAME payload as LOGIN
  const newAccessToken = signAccessToken({
    userId: user._id,
    name: user.name,
    email: user.email,
    role: user.role,
    isActive: user.isActive,
  });

  return res.status(200).json({
    success: true,
    accessToken: newAccessToken,
  });
};

import {
  getMyProfileService,
  updateMyProfileService,
} from "../services/profile_service.js";

import { signAccessToken } from "../utils/jwt.js"; // adjust path if needed

export const getMyProfile = async (req, res) => {
  try {
    const id = req.user._id;
    console.log(id);
    const user = await getMyProfileService(id);

    res.status(200).json(user);
  } catch (err) {
    res.status(404).json({
      success: false,
      message: err.message,
    });
  }
};

export const updateMyProfile = async (req, res) => {
  try {
    const userid = req.user._id;

    const data = {
      name: req.body.name,
      phone: req.body.phone,
    };

    const user = await updateMyProfileService(userid, data, req.file);

    // ✅ LOG
    console.log("📡 Emitting userUpdated to:", user._id.toString());

    // ✅ SOCKET EMIT (THIS WAS MISSING / NOT EXECUTING)
    req.io.to(user._id.toString()).emit("userUpdated");

    // ✅ NEW TOKEN (VERY IMPORTANT)
    const newAccessToken = signAccessToken({
      userId: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
    });

    res.json({
      success: true,
      user,
      accessToken: newAccessToken,
    });
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

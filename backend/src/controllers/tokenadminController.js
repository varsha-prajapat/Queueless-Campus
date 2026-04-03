import { getAdminQueueDetails } from "../services/tokenService.js";

/// 🔥 GET ADMIN DASHBOARD DATA
export const getAdminQueue = async (req, res) => {
  try {
    const data = await getAdminQueueDetails(req.io); // socket pass

    return res.status(200).json({
      success: true,
      message: "Admin queue fetched successfully",
      data,
    });
  } catch (err) {
    console.error("❌ Controller Error:", err.message);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch admin queue",
      error: err.message,
    });
  }
};

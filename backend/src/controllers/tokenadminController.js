import Token from "../models/tokenModel.js";

/// ================= GET ADMIN DASHBOARD TOKEN INFO =================
export const getAdminDashboardInfoToken = async (req, res) => {
  try {
    const data = await Token.aggregate([
      {
        $group: {
          _id: "$counterId",

          waiting: {
            $sum: {
              $cond: [{ $eq: ["$status", "waiting"] }, 1, 0],
            },
          },

          serving: {
            $sum: {
              $cond: [{ $eq: ["$status", "serving"] }, 1, 0],
            },
          },

          paymentPending: {
            $sum: {
              $cond: [{ $eq: ["$status", "waiting_payment"] }, 1, 0],
            },
          },
        },
      },
    ]);

    return res.json({
      success: true,
      data,
    });
  } catch (error) {
    console.error("Admin dashboard token stats error:", error.message);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch dashboard token stats",
      error: error.message,
    });
  }
};

// controllers/adminController.js
import * as AdminContact from "../services/admincontactService.js";

/**
 * GET /api/admin/contact
 * Returns admin contact info for students without a department
 */
export const getAdminContactController = async (req, res) => {
  try {
    const adminContact = await AdminContact.getAdminContact();

    if (!adminContact) {
      return res.status(404).json({
        success: false,
        message: "No admin found",
      });
    }

    res.status(200).json({
      success: true,
      data: adminContact,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message || "Server error",
    });
  }
};

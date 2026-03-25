import { createNotification } from "../services/notificationService.js";

export const sendNotification = async (req, res) => {
  try {
    const io = req.app.get("io");

    const notification = await createNotification(io, req.body);

    res.status(201).json({
      success: true,
      data: notification,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

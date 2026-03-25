import Notification from "../models/NotificationModel.js";

export const createNotification = async (io, data) => {
  try {
    const notification = await Notification.create(data);

    // Send to personal user
    if (notification.userId) {
      io.to(notification.userId.toString()).emit("notifications:update", [
        notification,
      ]);
      console.log("Notification sent to personal room:", notification.userId);
    }

    // Send to role rooms
    if (notification.roles && notification.roles.length > 0) {
      notification.roles.forEach((role) => {
        const room = `role_${role}`;
        io.to(room).emit("notifications:update", [notification]);
        console.log("Notification sent to role room:", room);
      });
    }

    // Send global notifications
    if (notification.isGlobal) {
      io.emit("notifications:update", [notification]);
      console.log("Notification sent globally");
    }

    return notification;
  } catch (err) {
    console.error("Error creating notification:", err);
    throw err;
  }
};

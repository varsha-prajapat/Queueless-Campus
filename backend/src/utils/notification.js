// Helper: Emit notifications to personal, role, or global targets
const emitNotification = (io, notification) => {
  if (!io || !notification) return;

  if (notification.userId) {
    // Personal notification
    io.to(notification.userId.toString()).emit("notifications:update", [
      notification,
    ]);
  } else if (notification.roles?.length) {
    // Role-based notifications
    notification.roles.forEach((role) => {
      io.to(`role_${role}`).emit("notifications:update", [notification]);
    });
  } else if (notification.isGlobal) {
    // Global notification
    io.emit("notifications:update", [notification]);
  }
};

export const isActiveUser = (req, res, next) => {
  // assumes req.user is already set by auth middleware (JWT/session)
  if (!req.user) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  if (!req.user.isActive) {
    return res.status(403).json({
      message: "Your account has been blocked by admin",
    });
  }

  next();
};

import ApiError from "../utils/ApiError.js";
import { STATUS } from "../config/status.js";

export function requireRole(...roles) {
  return (req, _res, next) => {
    if (!req.user?.role) {
      return next(
        new ApiError(
          STATUS.ERROR.UNAUTHORIZED.statusCode,
          STATUS.ERROR.UNAUTHORIZED.message,
        ),
      );
    }

    if (!roles.includes(req.user.role)) {
      return next(
        new ApiError(
          STATUS.ERROR.FORBIDDEN.statusCode,
          STATUS.ERROR.FORBIDDEN.message,
        ),
      );
    }

    next();
  };
}

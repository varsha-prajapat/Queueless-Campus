import { STATUS } from "../config/status.js";

export function notFound(req, res, next) {
  res.status(404).json({
    success: false,
    message: "API route not found",
  });
}

export function errorHandler(err, req, res, next) {
  res
    .status(err.statusCode || STATUS.ERROR.INTERNAL_SERVER_ERROR.statusCode)
    .json({
      success: false,
      message: err.message || STATUS.ERROR.INTERNAL_SERVER_ERROR.message,
    });
}

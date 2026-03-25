import Joi from "joi";
import mongoose from "mongoose";

/**
 * Notification Validation Schema
 * Validates data before creating/updating a notification
 */
export const notificationJoiSchema = Joi.object({
  title: Joi.string().trim().min(3).max(100).required().messages({
    "string.empty": "Title is required",
    "string.min": "Title must be at least 3 characters",
    "string.max": "Title cannot exceed 100 characters",
  }),

  message: Joi.string().trim().min(5).max(500).required().messages({
    "string.empty": "Message is required",
    "string.min": "Message must be at least 5 characters",
    "string.max": "Message cannot exceed 500 characters",
  }),

  // Who should receive the notification
  targetRoles: Joi.array()
    .items(Joi.string().valid("ADMIN", "STAFF", "STUDENT", "ALL"))
    .min(1)
    .required()
    .messages({
      "array.base": "Target roles must be an array",
      "array.min": "At least one target role must be specified",
      "any.only": "Invalid role specified",
    }),

  // Optional department filter
  departmentId: Joi.string()
    .allow(null)
    .custom((value, helpers) => {
      if (value === null) return value;
      if (!mongoose.Types.ObjectId.isValid(value)) {
        return helpers.message("Invalid Department ID");
      }
      return value;
    }),

  // Optional createdBy field (user ID)
  createdBy: Joi.string()
    .optional()
    .custom((value, helpers) => {
      if (!mongoose.Types.ObjectId.isValid(value)) {
        return helpers.message("Invalid User ID");
      }
      return value;
    }),

  // Active flag
  isActive: Joi.boolean().default(true),
});

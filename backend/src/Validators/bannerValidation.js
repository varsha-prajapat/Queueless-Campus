import Joi from "joi";
import mongoose from "mongoose";

export const bannerJoiSchema = Joi.object({
  title: Joi.string().trim().required(),

  targetRole: Joi.string()
    .valid("ADMIN", "STAFF", "STUDENT", "ALL")
    .default("ALL"),

  departmentId: Joi.string()
    .allow("ALL", null)
    .default("ALL")
    .custom((value, helpers) => {
      // Allow ALL departments
      if (value === "ALL" || value === null) {
        return value;
      }

      // Validate Mongo ObjectId
      if (!mongoose.Types.ObjectId.isValid(value)) {
        return helpers.error("any.invalid");
      }

      return value;
    })
    .messages({
      "any.invalid": "Invalid departmentId",
    }),

  status: Joi.string().valid("active", "inactive").default("active"),
});

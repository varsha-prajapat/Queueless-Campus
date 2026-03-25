import Joi from "joi";
import mongoose from "mongoose";

export const departmentJoiSchema = Joi.object({
  name: Joi.string().trim().min(1).required(),

  status: Joi.string().valid("active", "inactive").default("active"),

  createdBy: Joi.string()
    .custom((value, helpers) => {
      if (!mongoose.Types.ObjectId.isValid(value)) {
        return helpers.error("any.invalid");
      }
      return value;
    })
    .optional(),
});

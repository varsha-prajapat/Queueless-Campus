import Joi from "joi";

export const editProfileSchema = Joi.object({
  name: Joi.string().trim().min(2).max(50).required().messages({
    "string.empty": "Name is required",
    "string.min": "Name must be at least 2 characters",
    "string.max": "Name must be less than 50 characters",
  }),

  phone: Joi.string()
    .pattern(/^[6-9]\d{9}$/)
    .optional()
    .allow("")
    .messages({
      "string.pattern.base":
        "Phone number must be 10-digit  Indian mobile number starting with 6-9",
    }),
});

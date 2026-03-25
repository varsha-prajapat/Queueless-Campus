import Joi from "joi";

export const registerSchema = Joi.object({
  name: Joi.string().trim().min(2).max(50).required(),

  email: Joi.string().lowercase().trim().email().required(),

  password: Joi.string()
    .min(6)
    .max(50)
    .pattern(/^(?=.*[A-Za-z])(?=.*\d).+$/)
    .required()
    .messages({
      "string.pattern.base":
        "Password must contain at least 1 letter and 1 number",
    }),

  // Optional fields
  phone: Joi.string()
    .trim()
    .pattern(/^[6-9]\d{9}$/)
    .optional()
    .messages({
      "string.pattern.base":
        "Enter valid 10-digit Indian mobile number starting with 6-9",
    }),
  department: Joi.string().trim().min(2).max(50).optional(),
});

export const loginSchema = Joi.object({
  email: Joi.string().lowercase().trim().email().required(),
  password: Joi.string().required(),
});

export const updateUserSchema = Joi.object({
  name: Joi.string().trim().min(2).max(50).optional(),
  phone: Joi.string()
    .trim()
    .pattern(/^[6-9]\d{9}$/)
    .empty("")
    .optional()
    .messages({
      "string.pattern.base":
        "Enter valid 10-digit Indian mobile number starting with 6-9",
    }),
  department: Joi.string().trim().min(2).max(50).optional(),

  // Role updates should be admin-only
  role: Joi.string().valid("STUDENT", "STAFF", "ADMIN").optional(),

  isActive: Joi.boolean().optional(),
});

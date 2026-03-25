import Joi from "joi";

export const userValidationSchema = Joi.object({
  email: Joi.string().email().lowercase().required(),

  otp: Joi.string()
    .pattern(/^\d{6}$/)
    .required()
    .messages({
      "string.pattern.base": "OTP must be  6 digits",
      "string.empty": "OTP is required",
    }),

  purpose: Joi.string().valid("EMAIL_VERIFICATION", "LOGIN_2FA").required(),
});

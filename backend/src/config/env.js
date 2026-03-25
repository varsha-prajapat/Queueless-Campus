import dotenv from "dotenv";

dotenv.config();

const NODE_ENV = process.env.NODE_ENV || "development";

const getDatabaseName = () => {
  switch (NODE_ENV) {
    case "production":
      return process.env.MONGO_DB_PROD;
    case "staging":
      return process.env.MONGO_DB_STAGE;
    case "test":
      return process.env.MONGO_DB_TEST;
    default:
      return process.env.MONGO_DB_DEV;
  }
};

export const env = {
  NODE_ENV,

  PORT: Number(process.env.PORT || 3005),
  BASE_URL:
    process.env.BASE_URL || `http://localhost:${process.env.PORT || 3005}`,
  API_PREFIX: process.env.API_PREFIX || "/api/v1",
  PUBLIC_BASE_URL: process.env.PUBLIC_BASE_URL,

  // Mongo
  MONGO_DB_URI: process.env.MONGO_DB_URI,
  DB_NAME: getDatabaseName(),

  // JWT
  JWT_ACCESS_SECRET: process.env.JWT_ACCESS_SECRET,
  JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET,
  JWT_ACCESS_EXPIRES_IN: process.env.JWT_ACCESS_EXPIRES_IN,
  JWT_REFRESH_EXPIRES_IN: process.env.JWT_REFRESH_EXPIRES_IN,
  JWT_INVITE_SECRET: process.env.JWT_INVITE_SECRET,

  JWT_TEMP_SECRET: process.env.JWT_TEMP_SECRET,
  JWT_TEMP_EXPIRES: process.env.JWT_TEMP_EXPIRES,

  // OTP
  OTP_LENGTH: Number(process.env.OTP_LENGTH || 6),
  OTP_EXPIRE_MINUTES: Number(process.env.OTP_EXPIRE_MINUTES || 10),
  OTP_MAX_ATTEMPTS: Number(process.env.OTP_MAX_ATTEMPTS || 5),

  // Security
  BCRYPT_SALT_ROUNDS: Number(process.env.BCRYPT_SALT_ROUNDS || 10),

  // Email
  SMTP_HOST: process.env.SMTP_HOST,
  SMTP_PORT: Number(process.env.SMTP_PORT || 587),
  SMTP_USER: process.env.SMTP_USER,
  SMTP_PASS: process.env.SMTP_PASS,
  EMAIL_FROM: process.env.EMAIL_FROM,

  // Queue settings
  MAX_ACTIVE_TOKENS_PER_USER: Number(
    process.env.MAX_ACTIVE_TOKENS_PER_USER || 1,
  ),
  TOKEN_EXPIRY_MINUTES: Number(process.env.TOKEN_EXPIRY_MINUTES || 120),
  NO_SHOW_GRACE_MINUTES: Number(process.env.NO_SHOW_GRACE_MINUTES || 5),

  // CORS
  CORS_ORIGIN: process.env.CORS_ORIGIN || "*",

  SUPER_ADMIN_NAME: process.env.SUPER_ADMIN_NAME,
  SUPER_ADMIN_EMAIL: process.env.SUPER_ADMIN_EMAIL,
  SUPER_ADMIN_PASSWORD: process.env.SUPER_ADMIN_PASSWORD,
  SUPER_ADMIN_ENABLED: process.env.SUPER_ADMIN_ENABLED,
};

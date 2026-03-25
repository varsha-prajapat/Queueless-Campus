import bcrypt from "bcrypt";
import { env } from "../config/env.js";

export const generate_Otp = () => {
  const min = 10 ** (env.OTP_LENGTH - 1);
  const max = 10 ** env.OTP_LENGTH - 1;
  return Math.floor(min + Math.random() * (max - min)).toString();
};

export const hashOtp = async (otp) => {
  return await bcrypt.hash(otp, env.process.BCRYPT_SALT_ROUNDS);
};

export const CompareOtp = async (otp, hash) => {
  return await bcrypt.compare(otp, hash);
};

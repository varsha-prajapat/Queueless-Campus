import nodemailer from "nodemailer";
import { env } from "../config/env.js";
import { transporter } from "../utils/transporter.js";

export const sendMail = async ({ to, subject, html }) => {
  await transporter.sendMail({
    from: `"Queueless Campus" <${env.SMTP_USER}>`,
    to,
    subject,
    html,
  });
};

import nodemailer from "nodemailer";
import { env } from "../config/env.js";
import { transporter } from "../utils/transporter.js";
export const suceessful_register_invite = async (name, email) => {
  await transporter.sendMail({
    from: `"Queueless Campus" <${process.env.MAIL_USER}>`,
    to: email,
    subject: "Welcome to Queueless Campus 🎓",
    html: `
        <h3>Dear ${name},</h3>
        <p>Thank you for registering with <b>Queueless Campus</b>.</p>
        <p>Your registration has been successfully completed.</p>
        <p>We will contact you shortly if needed.</p>
        <br/>
        <p>Best Regards,<br/>Queueless Campus Team</p>
      `,
  });
};

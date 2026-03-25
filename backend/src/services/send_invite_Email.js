import nodemailer from "nodemailer";
import { inviteTemplate } from "../utils/inviteTemplate.js";
import { transporter } from "../utils/transporter.js";

export const sendInviteEmail = async ({
  name,
  email,
  registrationLink,
  role,
  department,
}) => {
  const html = inviteTemplate({ name, registrationLink, role, department });
  await transporter.sendMail({
    from: `"Queueless Campus" <${process.env.SMTP_USER}>`,
    to: email,
    subject: "You are invited!",
    html,
  });
};

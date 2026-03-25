
export const otpMailTemplate = ({ name = "User", otp }) => {
  return {
    subject: "Your OTP Code (Valid for 1 Minutes)",
    html: `
      <div style="
        font-family: Arial, sans-serif;
        max-width: 600px;
        margin: auto;
        padding: 20px;
        border: 1px solid #eee;
        border-radius: 8px;
      ">
        <h2 style="color: #333;">Hello ${name},</h2>

        <p style="font-size: 14px; color: #555;">
          Use the OTP below to complete your verification.
        </p>

        <div style="
          font-size: 32px;
          font-weight: bold;
          letter-spacing: 6px;
          margin: 20px 0;
          color: #000;
        ">
          ${otp}
        </div>

        <p style="font-size: 14px; color: #555;">
          ⏳ This OTP is valid for <b>2 minutes</b>.
        </p>

        <p style="font-size: 13px; color: #777;">
          If you didn’t request this OTP, please ignore this email.
        </p>

        <hr style="margin: 20px 0;" />

        <p style="font-size: 12px; color: #999;">
          This is an automated email. Please do not reply.
        </p>
      </div>
    `,
  };
};

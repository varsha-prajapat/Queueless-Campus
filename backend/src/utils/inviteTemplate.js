export const inviteTemplate = ({
  name = "user",
  registrationLink,
  role,
  department,
}) => `
<div style="font-family: Arial, sans-serif; line-height: 1.6; max-width:600px;">
  
  <h2>Hello ${name || "there"}, 👋</h2>

  <p>
    You have been invited to join <strong>QueueLess Campus</strong>.
  </p>

  <p>
    <strong>Role:</strong> ${role}<br/>
    <strong>Department:</strong> ${department || "N/A"}
  </p>

  <a href="${registrationLink}"
     style="
       display:inline-block;
       padding:12px 24px;
       color:#ffffff;
       background-color:#4CAF50;
       text-decoration:none;
       border-radius:6px;
       font-weight:bold;
       margin-top:12px;
     ">
    Register Now
  </a>

  <p style="margin-top:20px; color:#666; font-size:14px;">
    ⏳ This invitation link will expire in 24 hours.
  </p>

</div>
`;

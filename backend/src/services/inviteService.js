import { verifyInviteToken } from "../utils/jwt.js";

export default function verify_Invite_Token(token) {
  if (!token) throw new Error("no token");

  try {
    // Must use the same secret as signing
    const decoded = verifyInviteToken(token); // { email, role, department, iat, exp }
    const now = Math.floor(Date.now() / 1000);

    if (decoded.exp <= now) throw new Error("Expired");

    return decoded;
  } catch (err) {
    if (err.name === "TokenExpiredError") throw new Error("Expired");
    throw new Error("Invalid");
  }
}

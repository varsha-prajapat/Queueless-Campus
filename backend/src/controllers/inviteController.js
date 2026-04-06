// controllers/inviteController.js

import { env } from "../config/env.js";
import verify_Invite_Token from "../services/inviteService.js";

/**
 * Handle invite link verification and redirect to registration page
 */
export const handleInvite = async (req, res) => {
  try {
    const inviteToken = req.params.inviteToken;

    /* ================= VALIDATION ================= */

    if (!inviteToken) {
      return res.status(400).send("No invite token provided");
    }

    /* ================= VERIFY TOKEN ================= */

    const decoded = verify_Invite_Token(inviteToken);

    if (!decoded || !decoded.exp) {
      return res.status(401).send("Invalid invite token");
    }

    /* ================= CHECK EXPIRY ================= */

    const expiresAt = decoded.exp * 1000;
    const now = Date.now();

    if (expiresAt <= now) {
      return res.status(401).send("Invite link expired");
    }

    const maxAge = expiresAt - now;

    /* ================= DEBUG ================= */

    console.log("decoded:", decoded);

    /* ================= OPTIONAL BASIC CHECK ================= */

    if (!decoded.department) {
      return res.status(400).send("Department not found in invite");
    }

    /* ================= SET COOKIE ================= */

    res.cookie("inviteToken", inviteToken, {
      httpOnly: false, // frontend read ke liye
      secure: env.NODE_ENV === "production",
      sameSite: "lax",
      maxAge,
      path: "/",
    });

    /* ================= REDIRECT ================= */

    return res.redirect(`${env.BASE_URL}${env.API_PREFIX}/register`);
  } catch (err) {
    console.error("Invite verification failed:", err.message);

    return res.status(401).send("Invalid or expired invite token");
  }
};

// inviteController.js
import { env } from "../config/env.js";
import verify_Invite_Token from "../services/inviteService.js";

// 🔐 Memory store for used invite tokens
const usedInviteTokens = new Set();

/**
 * Handle invite link verification and redirect to registration page
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 */
export const handleInvite = (req, res) => {
  try {
    const inviteToken = req.params.inviteToken;

    if (!inviteToken) {
      return res.status(400).send("No invite token provided");
    }

    // ❌ Check if token was already used
    if (usedInviteTokens.has(inviteToken)) {
      return res.status(401).send("Invite link already used");
    }

    // ✅ Verify JWT token
    const decoded = verify_Invite_Token(inviteToken);

    if (!decoded || !decoded.exp) {
      return res.status(401).send("Invalid invite token");
    }

    // ⏳ Check expiry
    const expiresAt = decoded.exp * 1000;
    const now = Date.now();

    if (expiresAt <= now) {
      return res.status(401).send("Invite link expired");
    }

    const maxAge = expiresAt - now;

    // 🔥 Mark token as used BEFORE redirect
    usedInviteTokens.add(inviteToken);

    // 🧹 Auto cleanup after expiry (optional but recommended)
    setTimeout(() => {
      usedInviteTokens.delete(inviteToken);
    }, maxAge);

    // 🍪 Set cookie with invite token
    res.cookie("inviteToken", inviteToken, {
      httpOnly: false, // false if frontend JS needs to read it
      secure: env.NODE_ENV === "production", // true in production
      sameSite: "lax",
      maxAge,
      path: "/",
    });

    // ✅ Redirect to registration page
    return res.redirect(`${env.BASE_URL}${env.API_PREFIX}/register`);
  } catch (err) {
    console.error("Invite verification failed:", err.message);
    return res.status(401).send("Invalid or expired invite token");
  }
};

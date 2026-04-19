// controllers/tokenController.js

import {
  createToken,
  confirmPayment,
  getTokenStatsService,
  getMyTokensService,
  cancelToken,
} from "../services/tokenService.js";
import mongoose from "mongoose";

/* ================= BOOK TOKEN ================= */
export const bookToken = async (req, res) => {
  try {
    const { serviceId, isUrgent } = req.body;

    if (!serviceId || !mongoose.Types.ObjectId.isValid(serviceId)) {
      return res.status(400).json({
        success: false,
        message: "Valid Service ID is required",
      });
    }

    const token = await createToken(
      req.user._id,
      serviceId,
      isUrgent || false,
      req.io, // socket io
    );

    return res.status(201).json({
      success: true,
      token,
    });
  } catch (error) {
    console.error("Book Token Error:", error.message);
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

/* ================= CONFIRM PAYMENT ================= */
export const confirmPaymentCtrl = async (req, res) => {
  try {
    const { tokenId } = req.body;

    if (!tokenId || !mongoose.Types.ObjectId.isValid(tokenId)) {
      return res.status(400).json({
        success: false,
        message: "Valid Token ID is required",
      });
    }

    const token = await confirmPayment(tokenId, req.user._id, req.io);

    return res.json({
      success: true,
      token,
    });
  } catch (error) {
    console.error("Confirm Payment Error:", error.message);
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

/* ================= GET TOKEN STATS ================= */
export const getTokenStats = async (req, res) => {
  try {
    const stats = await getTokenStatsService(req.user._id);
    console.log("stats", stats);

    return res.json({
      success: true,
      stats,
    });
  } catch (error) {
    console.error("Get Token Stats Error:", error.message);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/* ================= GET MY TOKENS ================= */
export const getMyTokens = async (req, res) => {
  try {
    const tokens = await getMyTokensService(req.user._id);

    return res.json({
      success: true,
      tokens,
    });
  } catch (error) {
    console.error("Get My Tokens Error:", error.message);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/* ================= CANCEL TOKEN ================= */
export const cancelTokenCtrl = async (req, res) => {
  try {
    const { tokenId } = req.body;

    if (!tokenId || !mongoose.Types.ObjectId.isValid(tokenId)) {
      return res.status(400).json({
        success: false,
        message: "Valid Token ID is required",
      });
    }

    const token = await cancelToken(tokenId, req.user._id, req.io);

    return res.json({
      success: true,
      token,
    });
  } catch (error) {
    console.error("Cancel Token Error:", error.message);
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

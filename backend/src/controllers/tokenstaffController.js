// controllers/staffController.js

import Counter from "../models/counterModel.js";
import {
  callNextToken,
  completeToken,
  skipToken, // ✅ added
  getStaffQueue,
  getTokenStatsForStaffDetailed,
} from "../services/tokenService.js";

/* ================= GET STAFF QUEUE ================= */
export const getQueue = async (req, res) => {
  try {
    const staffId = req.user.id;

    const counter = await Counter.findOne({
      staffIds: staffId,
      isActive: true,
    });

    if (!counter) {
      return res.status(404).json({
        success: false,
        message: "No counter assigned to this staff",
      });
    }

    const tokens = await getStaffQueue(counter._id);

    res.json({
      success: true,
      data: tokens,
    });
  } catch (error) {
    console.error("getQueue Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch queue",
      error: error.message,
    });
  }
};

/* ================= GET TOKEN STATS (SUMMARY) ================= */
export const getTokenStatsCtrl = async (req, res) => {
  try {
    const staffId = req.user.id;

    const counter = await Counter.findOne({
      staffIds: staffId,
      isActive: true,
    });

    if (!counter) {
      return res.status(404).json({
        success: false,
        message: "No counter assigned",
      });
    }

    const stats = await getTokenStatsForStaffDetailed(counter._id);

    res.json({
      success: true,
      data: stats.summary,
    });
  } catch (error) {
    console.error("getTokenStatsCtrl Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch token stats",
      error: error.message,
    });
  }
};

/* ================= GET DETAILED TOKEN STATS ================= */
export const getTokenStatsDetailedCtrl = async (req, res) => {
  try {
    const staffId = req.user.id;

    const counter = await Counter.findOne({
      staffIds: staffId,
      isActive: true,
    });

    if (!counter) {
      return res.status(404).json({
        success: false,
        message: "No counter assigned",
      });
    }

    const stats = await getTokenStatsForStaffDetailed(counter._id);

    res.json({
      success: true,
      data: stats,
    });
  } catch (error) {
    console.error("getTokenStatsDetailedCtrl Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch detailed token stats",
      error: error.message,
    });
  }
};

/* ================= CALL NEXT TOKEN ================= */
export const callNext = async (req, res) => {
  try {
    const staffId = req.user.id;
    const io = req.io;

    const counter = await Counter.findOne({
      staffIds: staffId,
      isActive: true,
    });

    if (!counter) {
      return res.status(404).json({
        success: false,
        message: "No counter assigned",
      });
    }

    const token = await callNextToken(counter._id, io);

    if (!token) {
      return res.json({
        success: true,
        message: "No tokens in queue",
      });
    }
    res.json({ success: true, tokenNumber: token.tokenNumber, data: token });
  } catch (error) {
    console.error("callNext Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to call next token",
      error: error.message,
    });
  }
};

/* ================= COMPLETE TOKEN ================= */
export const completeTokenCtrl = async (req, res) => {
  try {
    const { tokenId } = req.body;
    const io = req.io;

    if (!tokenId) {
      return res.status(400).json({
        success: false,
        message: "tokenId is required",
      });
    }

    const token = await completeToken(tokenId, io);

    res.json({
      success: true,
      data: token,
    });
  } catch (error) {
    console.error("completeTokenCtrl Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to complete token",
      error: error.message,
    });
  }
};

/* ================= SKIP TOKEN (MANUAL) ================= */
export const skipTokenCtrl = async (req, res) => {
  try {
    const { tokenId } = req.body;
    const io = req.io;

    if (!tokenId) {
      return res.status(400).json({
        success: false,
        message: "tokenId is required",
      });
    }

    const token = await skipToken(tokenId, io);

    res.json({
      success: true,
      data: token,
    });
  } catch (error) {
    console.error("skipTokenCtrl Error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to skip token",
      error: error.message,
    });
  }
};

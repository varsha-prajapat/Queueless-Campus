import mongoose from "mongoose";

const notificationSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    message: { type: String, required: true, trim: true },

    // Department-wise notification (optional)
    departmentId: { type: mongoose.Schema.Types.ObjectId, ref: "Department" },

    // Types of recipients
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User" }, // Personal notification
    roles: {
      type: [{ type: String, enum: ["ADMIN", "STAFF", "STUDENT", "ALL"] }],
      default: [],
    },
    isGlobal: { type: Boolean, default: false },

    // Soft delete per user
    hiddenFor: {
      type: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
      default: [],
    },

    // Track read per user
    readBy: {
      type: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
      default: [],
    },

    // Per-user expiry (handled manually)
    expiresFor: {
      type: Map,
      of: Date, // userId -> expiry datetime
      default: {},
    },
  },
  { timestamps: true },
);

// Fast queries
notificationSchema.index({ userId: 1 });
notificationSchema.index({ roles: 1 });
notificationSchema.index({ isGlobal: 1 });
notificationSchema.index({ hiddenFor: 1 });
notificationSchema.index({ departmentId: 1 }); // index for department-wise queries

export default mongoose.model("Notification", notificationSchema);

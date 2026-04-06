import mongoose from "mongoose";

const tokenSchema = new mongoose.Schema(
  {
    tokenNumber: {
      type: Number,
      required: true,
    },

    studentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    serviceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Service",
      required: true,
    },
    serviceName: {
      type: String,
      required: true,
      trim: true,
    },

    counterId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Counter",
      required: true,
    },
    paymentStatus: {
      type: String,
      enum: ["pending", "paid", "failed"],
      default: "pending",
    },
    totalAmount: {
      type: Number,
      default: 0,
    },

    status: {
      type: String,
      enum: [
        "waiting",
        "serving",
        "completed",
        "waiting_payment",
        "skipped",
        "cancelled", // ✅ Added cancelled
      ],
      default: "waiting",
    },

    isUrgent: {
      type: Boolean,
      default: false,
    },

    /// 🔥 When token started serving
    servingStartedAt: {
      type: Date,
      default: null,
    },

    /// 🔥 How many times token called
    calledCount: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  },
);

/// 🔥 Index for fast auto-skip queries
tokenSchema.index({ status: 1, servingStartedAt: 1 });

export default mongoose.model("Token", tokenSchema);

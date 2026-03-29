import mongoose from "mongoose";

const notificationSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
    },

    message: {
      type: String,
      required: true,
      trim: true,
    },

    counterId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Counter",
      default: null,
    },

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },

    roles: {
      type: [String],
      enum: ["ADMIN", "STAFF", "STUDENT"],
      default: [],
    },

    isGlobal: {
      type: Boolean,
      default: false,
    },

    hiddenFor: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],

    readBy: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],

    type: {
      type: String,
      enum: [
        "PAYMENT_SUCCESS",
        "PAYMENT_RECEIVED",
        "CALLED",
        "SKIPPED",
        "CREATED",
        "INFO",
      ],
      default: "INFO",
    },
  },
  {
    timestamps: true,
  },
);

/* ================= INDEXES ================= */

// fast user notifications
notificationSchema.index({ userId: 1 });

// role-based filtering
notificationSchema.index({ roles: 1 });

// global notifications
notificationSchema.index({ isGlobal: 1 });

// counter-based notifications
notificationSchema.index({ counterId: 1 });

// hide/read optimization
notificationSchema.index({ hiddenFor: 1 });
notificationSchema.index({ readBy: 1 });

// main compound query optimization
notificationSchema.index({
  isGlobal: 1,
  roles: 1,
  counterId: 1,
  userId: 1,
});

export default mongoose.model("Notification", notificationSchema);

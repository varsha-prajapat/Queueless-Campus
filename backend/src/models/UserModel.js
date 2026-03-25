import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      trim: true,
      minlength: 2,
      maxlength: 50,
    },

    email: {
      type: String,
      required: true,
      unique: true, // creates unique index automatically
      lowercase: true,
      trim: true,
    },

    passwordHash: {
      type: String,
      required: true,
      select: false,
    },

    role: {
      type: String,
      enum: ["STUDENT", "STAFF", "ADMIN"],
      default: "STUDENT",
      index: true,
    },

    isEmailVerified: {
      type: Boolean,
      default: false,
    },

    isSuperAdmin: {
      type: Boolean,
      default: false,
      index: true,
    },

    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },

    lastLoginAt: {
      type: Date,
      default: null,
    },

    phone: {
      type: String,
      trim: true,
      default: null,
    },

    // ✅ FIX: store department as ObjectId reference
    departmentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Department",
      default: null,
      index: true,
    },

    profileImage: {
      type: String,
      default: "",
    },

    notificationExpiry: {
      type: Number,
      default: 0, // 0 = no expiry
    },
  },
  { timestamps: true },
);

// ✅ Prevent OverwriteModelError
export default mongoose.models.User || mongoose.model("User", userSchema);

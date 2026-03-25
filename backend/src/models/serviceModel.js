import mongoose from "mongoose";

const serviceSchema = new mongoose.Schema({
  name: String,
  departmentId: { type: mongoose.Schema.Types.ObjectId, ref: "Department" },
  counters: [{ type: mongoose.Schema.Types.ObjectId, ref: "Counter" }],
  hasFee: { type: Boolean, default: false },
  fee: { type: Number, default: 0 },
  serviceType: {
    type: String,
    enum: ["Documents", "Fees"],
    required: true,
  },
  isPaused: { type: Boolean, default: false },
  allowUrgent: { type: Boolean, default: false },
});

export default mongoose.model("Service", serviceSchema);

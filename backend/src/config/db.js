import mongoose from "mongoose";
import { env } from "./env.js";

export async function connectDB() {
  try {
    if (!env.MONGO_DB_URI) {
      throw new Error("MONGO_DB_URI missing in .env");
    }

    if (!env.DB_NAME) {
      throw new Error("Database name missing in .env");
    }

    const fullUri = `${env.MONGO_DB_URI}/${env.DB_NAME}`;

    mongoose.set("strictQuery", true);

    await mongoose.connect(fullUri);

    console.log("=====================================");
    console.log("✅ MongoDB Connected");
    console.log(`📦 Database : ${env.DB_NAME}`);
    console.log("=====================================");
  } catch (error) {
    console.error("❌ MongoDB connection failed:", error.message);
    process.exit(1);
  }
}
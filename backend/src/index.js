import { server } from "./app.js";
import { env } from "./config/env.js";
import { connectDB } from "./config/db.js";
import { adminService } from "./services/adminService.js";

async function startServer() {
  try {
    await connectDB();
    await adminService.seedSuperAdmin();

    server.listen(env.PORT, () => {
      console.log("=====================================");
      console.log("🚀 QueueLess Backend Started");
      console.log(`🌍 Environment : ${env.NODE_ENV}`);
      console.log(`📦 Database    : ${env.DB_NAME}`);
      console.log(`🔗 Server URL  : ${env.BASE_URL}`);
      console.log(`📡 API Base    : ${env.BASE_URL}${env.API_PREFIX}`);
      console.log(`🛠 Port        : ${env.PORT}`);
      console.log("=====================================");
    });
  } catch (error) {
    console.error("❌ Failed to start server:", error.message);
    process.exit(1);
  }
}

startServer();

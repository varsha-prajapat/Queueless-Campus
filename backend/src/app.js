import express from "express";
import cors from "cors";
import cookieParser from "cookie-parser";
import { env } from "./config/env.js";
import apiRoutes from "./routes/index.js";
import { errorHandler } from "./middlewares/error_middleware.js";
import path from "path";
import { fileURLToPath } from "url";
import http from "http";
import { Server } from "socket.io";
import { queueSocket } from "./socket/socket.js";

const app = express();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ✅ serve public folder
app.use(env.API_PREFIX, express.static(path.join(__dirname, "../public")));

// Body parser
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// CORS (Flutter-friendly)
app.use(
  cors({
    origin: env.CORS_ORIGIN === "*" ? true : env.CORS_ORIGIN,
    credentials: true,
  }),
);

// ✅ Create HTTP server
const server = http.createServer(app);

// ✅ Attach Socket.IO
const io = new Server(server, { cors: { origin: "*" } });

// Make io available in routes
app.use((req, res, next) => {
  req.io = io;
  next();
});

// Mount API routes
app.use(env.API_PREFIX, apiRoutes);

// Initialize socket logic
queueSocket(io);

// Global error handler
app.use(errorHandler);

// ✅ IMPORTANT: named export
export { app, server };

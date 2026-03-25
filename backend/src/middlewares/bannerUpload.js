import multer from "multer";
import path from "path";

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "public/banner");
  },
  filename: function (req, file, cb) {
    cb(null, "banner_" + Date.now() + path.extname(file.originalname));
  },
});

export const bannerUpload = multer({ storage });

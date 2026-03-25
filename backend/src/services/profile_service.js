import User from "../models/UserModel.js";
import fs from "fs";
import path from "path";
import { env } from "process";

export const getMyProfileService = async (id) => {
  const user = await User.findOne({
    _id: id,
  }).select("-passwordHash -__v");

  if (!user) throw new Error("User not found");
  return user;
};

export const updateMyProfileService = async (id, updateData, file) => {
  const user = await User.findById(id);
  if (!user) throw new Error("User not found");

  // update text fields
  if (updateData.name) user.name = updateData.name;
  if (updateData.phone) user.phone = updateData.phone;

  // update image if new file uploaded
  if (file) {
    // delete old image
    if (user.profileImage) {
      const oldPath = path.join(process.cwd(), "public", user.profileImage);

      if (fs.existsSync(oldPath)) {
        fs.unlinkSync(oldPath);
      }
    }

    // save new image path
    user.profileImage = `${env.BASE_URL}${env.API_PREFIX}/upload/profile/${file.filename}`;
  }

  await user.save();
  return user;
};

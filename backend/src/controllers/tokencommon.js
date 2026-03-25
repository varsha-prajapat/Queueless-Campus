import Token from "../models/tokenModel.js";

export const getQueueByCounter = async (req, res) => {
  const tokens = await Token.find({
    counterId: req.params.counterId,
    status: { $in: ["waiting", "serving"] },
  }).sort({ isUrgent: -1, tokenNumber: 1 });
  res.json(tokens);
};

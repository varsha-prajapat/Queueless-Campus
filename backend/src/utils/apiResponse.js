export const success = (res, data, message = "Success") =>
  res.json({ success: true, message, data });

export const error = (res, message = "Error", code = 400) =>
  res.status(code).json({ success: false, message });

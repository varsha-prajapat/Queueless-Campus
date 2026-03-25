export const STATUS = {
  SUCCESS: {
    SUCCESS: { statusCode: 200, message: "Request successful." },
    CREATED: { statusCode: 201, message: "Created successfully." },
    NO_CONTENT: { statusCode: 204, message: "No content." },
  },

  ERROR: {
    BAD_REQUEST: { statusCode: 400, message: "Bad request." },
    UNAUTHORIZED: { statusCode: 401, message: "Unauthorized." },
    FORBIDDEN: { statusCode: 403, message: "Forbidden." },
    NOT_FOUND: { statusCode: 404, message: "Not found." },
    CONFLICT:{statusCode: 409,message:"USer already exists"},
    INTERNAL_SERVER_ERROR: { statusCode: 500, message: "Internal server error." },

  },
};

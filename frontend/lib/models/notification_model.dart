class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String? userId;
  final List<String>? roles; // 👈 ADD THIS
  final bool isGlobal;
  final List<String>? hiddenFor;
  bool read;
  final DateTime? expiresAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.userId,
    this.roles,
    this.isGlobal = false,
    this.hiddenFor,
    this.read = false,
    this.expiresAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json["_id"],
      title: json["title"] ?? "",
      message: json["message"] ?? "",
      userId: json["userId"],
      roles: json["roles"] != null
          ? List<String>.from(json["roles"])
          : null, // 👈 ADD THIS
      isGlobal: json["isGlobal"] ?? false,
      hiddenFor: json["hiddenFor"] != null
          ? List<String>.from(json["hiddenFor"])
          : null,
      read: json["read"] ?? false,
      expiresAt:
          json["expiresAt"] != null ? DateTime.parse(json["expiresAt"]) : null,
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;

  final String? userId;
  final List<String>? roles;
  final bool isGlobal;
  final List<String>? hiddenFor;

  final bool isRead;
  final DateTime? expiresAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.userId,
    this.roles,
    this.isGlobal = false,
    this.hiddenFor,
    this.isRead = false,
    this.expiresAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json["_id"] ?? "",
      title: json["title"] ?? "",
      message: json["message"] ?? "",
      userId: json["userId"],
      roles: json["roles"] != null ? List<String>.from(json["roles"]) : null,
      isGlobal: json["isGlobal"] ?? false,
      hiddenFor: json["hiddenFor"] != null
          ? List<String>.from(json["hiddenFor"])
          : null,
      isRead: json["isRead"] ?? false,
      expiresAt: json["expiresAt"] != null
          ? DateTime.tryParse(json["expiresAt"])
          : null,
    );
  }
}

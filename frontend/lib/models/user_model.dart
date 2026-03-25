// models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String role;
  final String? departmentId;
  final String? email;
  final String? phone;
  final String? profileImage;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    this.departmentId,
    this.email,
    this.phone,
    this.profileImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? "unknown_id",
      name: json['name']?.toString() ?? "Unknown",
      role: json['role']?.toString() ?? "Unknown",
      departmentId: json['departmentId']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      profileImage: json['profileImage']?.toString(),
    );
  }

  /// Optional: convert UserModel back to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'role': role,
      'departmentId': departmentId,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
    };
  }
}

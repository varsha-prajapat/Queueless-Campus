import '../../../core/config/api_config.dart';

class Userui {
  String id;
  String name;
  String email;
  String departmentId; // store department ID
  String role;
  bool isActive;
  String imageUrl; // full profile image URL

  Userui({
    required this.id,
    required this.name,
    required this.email,
    required this.departmentId,
    required this.role,
    required this.isActive,
    required this.imageUrl,
  });

  // ✅ Create Userui object from backend JSON
  factory Userui.fromJson(Map<String, dynamic> json) => Userui(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        // ✅ Correctly handle department as string or nested object
        departmentId: json['departmentId'] is String
            ? json['departmentId']
            : json['departmentId']?['_id'] ?? '',
        role: json['role'] ?? '',
        isActive: json['isActive'] ?? true,
        imageUrl: json['profileImage'] ?? '', // full profile image URL
      );

  // ✅ Convert Userui to JSON for backend (send departmentId as 'department')
  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'department': departmentId, // send departmentId to backend
        'role': role,
        'isActive': isActive,
        'profileImage': imageUrl,
      };

  // ✅ Copy with method for immutability
  Userui copyWith({
    String? id,
    String? name,
    String? email,
    String? departmentId,
    String? role,
    bool? isActive,
    String? imageUrl,
  }) {
    return Userui(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      departmentId: departmentId ?? this.departmentId,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'Userui(id: $id, name: $name, email: $email, departmentId: $departmentId, role: $role, isActive: $isActive)';
  }
}

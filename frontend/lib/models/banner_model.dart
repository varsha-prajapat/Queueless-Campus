class BannerModel {
  final String id;
  final String title;
  final String image;
  final String description;
  final String targetRole;
  final String? departmentId;
  final String createdBy;
  final bool isActive;
  final DateTime createdAt;

  BannerModel({
    required this.id,
    required this.title,
    required this.image,
    required this.description,
    required this.targetRole,
    this.departmentId,
    required this.createdBy,
    required this.isActive,
    required this.createdAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['_id'],
      title: json['title'],
      image: json['image'],
      description: json['description'] ?? '',
      targetRole: json['targetRole'],
      departmentId: json['departmentId'],
      createdBy: json['createdBy'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "image": image,
      "description": description,
      "targetRole": targetRole,
      "departmentId": departmentId,
      "isActive": isActive,
    };
  }
}

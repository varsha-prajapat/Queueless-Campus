class Department {
  final String id;
  final String name;
  final String status;
  final String? createdBy;

  Department({
    required this.id,
    required this.name,
    required this.status,
    this.createdBy,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['_id'],
      name: json['name'],
      status: json['status'],
      createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "status": status,
    };
  }
}

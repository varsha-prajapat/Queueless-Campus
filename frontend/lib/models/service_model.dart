class Service {
  final String id;
  final String name;
  final bool hasFee;
  final double fee;
  final bool isPaused;
  final bool allowUrgent;

  Service({
    required this.id,
    required this.name,
    required this.hasFee,
    required this.fee,
    required this.isPaused,
    required this.allowUrgent,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['_id'],
      name: json['name'],
      hasFee: json['hasFee'] ?? false,
      fee: (json['fee'] ?? 0).toDouble(),
      isPaused: json['isPaused'] ?? false,
      allowUrgent: json['allowUrgent'] ?? false,
    );
  }
}

class TokenStats {
  final String currentToken;
  final String nextToken;
  final int waiting;
  final int servedToday;
  final int urgentWaiting;
  final int completed; // new
  final int cancelled; // new
  final int skipped; // new

  TokenStats({
    required this.currentToken,
    required this.nextToken,
    required this.waiting,
    required this.servedToday,
    this.urgentWaiting = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.skipped = 0,
  });

  /// Empty/default stats
  factory TokenStats.empty() {
    return TokenStats(
      currentToken: "-",
      nextToken: "-",
      waiting: 0,
      servedToday: 0,
      urgentWaiting: 0,
      completed: 0,
      cancelled: 0,
      skipped: 0,
    );
  }

  /// Parse JSON into TokenStats
  factory TokenStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return TokenStats.empty();
    return TokenStats(
      currentToken: json["currentToken"]?.toString() ?? "-",
      nextToken: json["nextToken"]?.toString() ?? "-",
      waiting: json["waiting"] is int ? json["waiting"] : 0,
      servedToday: json["servedToday"] is int ? json["servedToday"] : 0,
      urgentWaiting: json["urgentWaiting"] is int ? json["urgentWaiting"] : 0,
      completed: json["completed"] is int ? json["completed"] : 0,
      cancelled: json["cancelled"] is int ? json["cancelled"] : 0,
      skipped: json["skipped"] is int ? json["skipped"] : 0,
    );
  }

  @override
  String toString() {
    return 'TokenStats(current: $currentToken, next: $nextToken, waiting: $waiting, served: $servedToday, urgent: $urgentWaiting, completed: $completed, cancelled: $cancelled, skipped: $skipped)';
  }
}

class TokenModel {
  final String id;
  final int tokenNumber;
  String status;
  final bool isUrgent;
  final String? serviceId;
  final String? studentId;
  final String? counterId; // ✅ Added
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TokenModel({
    required this.id,
    required this.tokenNumber,
    required this.status,
    this.isUrgent = false,
    this.serviceId,
    this.studentId,
    this.counterId, // ✅ Added
    this.createdAt,
    this.updatedAt,
  });

  /// Factory to parse JSON robustly
  factory TokenModel.fromJson(Map<String, dynamic> json, {String? studentId}) {
    String parseId() {
      if (json["tokenId"] != null) return json["tokenId"].toString();
      if (json["_id"] != null) return json["_id"].toString();
      return "";
    }

    String? parseServiceId(dynamic serviceField) {
      if (serviceField == null) return null;
      if (serviceField is Map) {
        return serviceField["_id"]?.toString() ??
            serviceField["id"]?.toString();
      }
      return serviceField.toString();
    }

    DateTime? parseDate(dynamic field) {
      if (field == null) return null;
      try {
        return DateTime.parse(field.toString());
      } catch (_) {
        return null;
      }
    }

    String parseStatus(dynamic s) {
      if (s == null || s.toString().trim().isEmpty) return "waiting";
      return s.toString().toLowerCase();
    }

    return TokenModel(
      id: parseId(),
      tokenNumber: json["tokenNumber"] is int ? json["tokenNumber"] : 0,
      status: parseStatus(json["status"]),
      isUrgent: json["isUrgent"] is bool ? json["isUrgent"] : false,
      serviceId: parseServiceId(json["serviceId"] ?? json["service"]),
      studentId: studentId ?? json["studentId"]?.toString(),
      counterId: json["counterId"]?.toString(), // ✅ Parse counterId
      createdAt: parseDate(json["createdAt"]),
      updatedAt: parseDate(json["updatedAt"]),
    );
  }

  get calledCount => null;

  /// Convert object to JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "tokenNumber": tokenNumber,
      "status": status,
      "isUrgent": isUrgent,
      "serviceId": serviceId,
      "studentId": studentId,
      "counterId": counterId, // ✅ Include counterId in JSON
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
    };
  }

  /// Display token with urgency label
  String displayToken() => isUrgent ? "$tokenNumber (Urgent)" : "$tokenNumber";

  @override
  String toString() {
    return 'TokenModel(id: $id, number: $tokenNumber, status: $status, urgent: $isUrgent, serviceId: $serviceId, studentId: $studentId, counterId: $counterId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  TokenModel copyWith({
    String? id,
    int? tokenNumber,
    String? status,
    bool? isUrgent,
    String? serviceId,
    String? studentId,
    String? counterId, // ✅ Added
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TokenModel(
      id: id ?? this.id,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      status: status ?? this.status,
      isUrgent: isUrgent ?? this.isUrgent,
      serviceId: serviceId ?? this.serviceId,
      studentId: studentId ?? this.studentId,
      counterId: counterId ?? this.counterId, // ✅ Added
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CounterModel {
  final String id;
  final String name;
  final String serviceId;
  final String serviceName;
  final bool isActive;
  final List<String> staffIds;
  final List<Map<String, dynamic>> staffObjects;

  CounterModel({
    required this.id,
    required this.name,
    required this.serviceId,
    required this.serviceName,
    required this.isActive,
    required this.staffIds,
    required this.staffObjects,
  });

  factory CounterModel.fromJson(Map<String, dynamic> json) {
    String serviceId = '';
    String serviceName = '';

    /// HANDLE SERVICE OBJECT
    if (json['serviceId'] is Map) {
      serviceId = json['serviceId']['_id']?.toString() ?? '';
      serviceName = json['serviceId']['name']?.toString() ?? '';
    } else {
      serviceId = json['serviceId']?.toString() ?? '';
    }

    List<String> staffIds = [];
    List<Map<String, dynamic>> staffObjects = [];

    if (json['staffIds'] is List) {
      for (var staff in json['staffIds']) {
        if (staff is Map) {
          staffIds.add(staff['_id']?.toString() ?? '');
          staffObjects.add(Map<String, dynamic>.from(staff));
        } else {
          staffIds.add(staff.toString());
        }
      }
    }

    return CounterModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      serviceId: serviceId,
      serviceName: serviceName,
      isActive: json['isActive'] ?? false,
      staffIds: staffIds,
      staffObjects: staffObjects,
    );
  }
}

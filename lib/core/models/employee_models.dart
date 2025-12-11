class Employee {
  final String id;
  final String name;
  final String? photoUrl;
  final bool active;
  final List<String> serviceIds;

  Employee({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.active,
    this.serviceIds = const [],
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    // Handle different possible formats for service assignments
    List<String> serviceIds = [];

    if (json['serviceIds'] != null) {
      // Direct array of IDs
      serviceIds = List<String>.from(json['serviceIds'] as List);
    } else if (json['services'] != null) {
      // Array of service objects - extract IDs
      final services = json['services'] as List;
      serviceIds = services
          .map((s) {
            if (s is Map<String, dynamic>) {
              return s['id'] as String? ?? s['serviceId'] as String? ?? '';
            }
            return s.toString();
          })
          .where((id) => id.isNotEmpty)
          .toList();
    } else if (json['employeeServices'] != null) {
      // Nested employeeServices array
      final employeeServices = json['employeeServices'] as List;
      serviceIds = employeeServices
          .map((es) {
            if (es is Map<String, dynamic>) {
              return es['serviceId'] as String? ??
                  es['service']?['id'] as String? ??
                  '';
            }
            return es.toString();
          })
          .where((id) => id.isNotEmpty)
          .toList();
    }

    print(
      '[Employee] Parsing employee - name: ${json['name']}, serviceIds found: ${serviceIds.length}',
    );

    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      active: json['active'] as bool? ?? true,
      serviceIds: serviceIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'photoUrl': photoUrl,
    'active': active,
  };
}

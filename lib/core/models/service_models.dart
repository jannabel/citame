class Service {
  final String id;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
  final bool active;

  Service({
    required this.id,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.price,
    required this.active,
  });

  factory Service.fromJson(Map<String, dynamic> json) => Service(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        durationMinutes: json['durationMinutes'] as int,
        price: (json['price'] as num).toDouble(),
        active: json['active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'durationMinutes': durationMinutes,
        'price': price,
        'active': active,
      };
}


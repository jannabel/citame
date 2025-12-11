class Business {
  final String id;
  final String name;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? description;
  final String? phone;
  final String? address;
  final String timezone;
  final bool requiresDeposit;
  final DepositType? depositType;
  final double? depositAmount;

  Business({
    required this.id,
    required this.name,
    this.logoUrl,
    this.coverImageUrl,
    this.description,
    this.phone,
    this.address,
    required this.timezone,
    required this.requiresDeposit,
    this.depositType,
    this.depositAmount,
  });

  factory Business.fromJson(Map<String, dynamic> json) => Business(
    id: json['id'] as String,
    name: json['name'] as String,
    logoUrl: json['logoUrl'] as String?,
    coverImageUrl: json['coverImageUrl'] as String?,
    description: json['description'] as String?,
    phone: json['phone'] as String?,
    address: json['address'] as String?,
    timezone: json['timezone'] as String,
    requiresDeposit: json['requiresDeposit'] as bool? ?? false,
    depositType: json['depositType'] != null
        ? DepositType.fromString(json['depositType'] as String)
        : null,
    depositAmount: json['depositAmount'] != null
        ? (json['depositAmount'] as num).toDouble()
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logoUrl': logoUrl,
    'coverImageUrl': coverImageUrl,
    'description': description,
    'phone': phone,
    'address': address,
    'timezone': timezone,
    'requiresDeposit': requiresDeposit,
    'depositType': depositType?.toString(),
    'depositAmount': depositAmount,
  };

  Business copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? coverImageUrl,
    String? description,
    String? phone,
    String? address,
    String? timezone,
    bool? requiresDeposit,
    DepositType? depositType,
    double? depositAmount,
  }) => Business(
    id: id ?? this.id,
    name: name ?? this.name,
    logoUrl: logoUrl ?? this.logoUrl,
    coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    description: description ?? this.description,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    timezone: timezone ?? this.timezone,
    requiresDeposit: requiresDeposit ?? this.requiresDeposit,
    depositType: depositType ?? this.depositType,
    depositAmount: depositAmount ?? this.depositAmount,
  );
}

enum DepositType {
  fixed,
  percentage;

  static DepositType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'FIXED':
        return DepositType.fixed;
      case 'PERCENTAGE':
        return DepositType.percentage;
      default:
        throw ArgumentError('Invalid deposit type: $value');
    }
  }

  @override
  String toString() {
    switch (this) {
      case DepositType.fixed:
        return 'FIXED';
      case DepositType.percentage:
        return 'PERCENTAGE';
    }
  }
}

enum SubscriptionStatus {
  trial,
  active,
  pastDue,
  cancelled,
  expired;

  static SubscriptionStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'TRIAL':
        return SubscriptionStatus.trial;
      case 'ACTIVE':
        return SubscriptionStatus.active;
      case 'PAST_DUE':
        return SubscriptionStatus.pastDue;
      case 'CANCELLED':
        return SubscriptionStatus.cancelled;
      case 'EXPIRED':
        return SubscriptionStatus.expired;
      default:
        throw ArgumentError('Invalid subscription status: $value');
    }
  }

  @override
  String toString() {
    switch (this) {
      case SubscriptionStatus.trial:
        return 'TRIAL';
      case SubscriptionStatus.active:
        return 'ACTIVE';
      case SubscriptionStatus.pastDue:
        return 'PAST_DUE';
      case SubscriptionStatus.cancelled:
        return 'CANCELLED';
      case SubscriptionStatus.expired:
        return 'EXPIRED';
    }
  }

  bool get isActive => this == SubscriptionStatus.active || this == SubscriptionStatus.trial;
}

class Plan {
  final String id;
  final String name;
  final String? description;
  final int priceCents;
  final String? lemonSqueezyVariantId;
  final bool isActive;

  Plan({
    required this.id,
    required this.name,
    this.description,
    required this.priceCents,
    this.lemonSqueezyVariantId,
    this.isActive = true,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        priceCents: json['priceCents'] as int? ?? json['price_cents'] as int,
        lemonSqueezyVariantId: json['lemonSqueezyVariantId'] as String? ??
            json['lemon_squeezy_variant_id'] as String?,
        isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'priceCents': priceCents,
        'lemonSqueezyVariantId': lemonSqueezyVariantId,
        'isActive': isActive,
      };

  String get formattedPrice {
    final dollars = priceCents / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }
}

class Feature {
  final String key;
  final String name;

  Feature({
    required this.key,
    required this.name,
  });

  factory Feature.fromJson(Map<String, dynamic> json) => Feature(
        key: json['key'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
      };
}

class Subscription {
  final String id;
  final SubscriptionStatus status;
  final DateTime? trialEndDate;
  final DateTime? currentPeriodEnd;
  final Plan? plan;
  final List<Feature> features;

  Subscription({
    required this.id,
    required this.status,
    this.trialEndDate,
    this.currentPeriodEnd,
    this.plan,
    this.features = const [],
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    Plan? plan;
    if (json['plan'] != null) {
      plan = Plan.fromJson(json['plan'] as Map<String, dynamic>);
    }

    List<Feature> features = [];
    if (json['features'] != null) {
      final featuresList = json['features'] as List<dynamic>;
      features = featuresList
          .map((f) => Feature.fromJson(f as Map<String, dynamic>))
          .toList();
    }

    return Subscription(
      id: json['id'] as String,
      status: SubscriptionStatus.fromString(
        json['status'] as String,
      ),
      trialEndDate: json['trialEndDate'] != null
          ? DateTime.parse(json['trialEndDate'] as String)
          : json['trial_end_date'] != null
              ? DateTime.parse(json['trial_end_date'] as String)
              : null,
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.parse(json['currentPeriodEnd'] as String)
          : json['current_period_end'] != null
              ? DateTime.parse(json['current_period_end'] as String)
              : null,
      plan: plan,
      features: features,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.toString(),
        'trialEndDate': trialEndDate?.toIso8601String(),
        'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
        'plan': plan?.toJson(),
        'features': features.map((f) => f.toJson()).toList(),
      };

  bool hasFeature(String featureKey) {
    return features.any((f) => f.key == featureKey);
  }

  int? get trialDaysRemaining {
    if (trialEndDate == null || status != SubscriptionStatus.trial) {
      return null;
    }
    final now = DateTime.now();
    final difference = trialEndDate!.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }
}

class CreateCheckoutRequest {
  final String planId;

  CreateCheckoutRequest({required this.planId});

  Map<String, dynamic> toJson() => {
        'planId': planId,
      };
}

class CreateCheckoutResponse {
  final String checkoutUrl;

  CreateCheckoutResponse({required this.checkoutUrl});

  factory CreateCheckoutResponse.fromJson(Map<String, dynamic> json) =>
      CreateCheckoutResponse(
        checkoutUrl: json['checkoutUrl'] as String? ??
            json['checkout_url'] as String,
      );
}


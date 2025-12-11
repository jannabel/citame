import '../../core/models/subscription_models.dart';

/// Utility class for subscription and feature checking
class SubscriptionUtils {
  /// Check if subscription has active status (ACTIVE or TRIAL)
  static bool hasActiveSubscription(Subscription? subscription) {
    return subscription?.status.isActive ?? false;
  }

  /// Check if subscription has a specific feature
  static bool hasFeature(Subscription? subscription, String featureKey) {
    return subscription?.hasFeature(featureKey) ?? false;
  }

  /// Get subscription status display text
  static String getStatusDisplayText(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.trial:
        return 'Trial';
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.pastDue:
        return 'Past Due';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.expired:
        return 'Expired';
    }
  }

  /// Get subscription status color for UI
  static String getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.trial:
      case SubscriptionStatus.active:
        return 'success';
      case SubscriptionStatus.pastDue:
        return 'warning';
      case SubscriptionStatus.cancelled:
      case SubscriptionStatus.expired:
        return 'error';
    }
  }

  /// Format price from cents to currency string
  static String formatPrice(int priceCents, {String currency = '\$'}) {
    final dollars = priceCents / 100;
    return '$currency${dollars.toStringAsFixed(2)}';
  }
}


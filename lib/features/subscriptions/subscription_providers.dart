import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/subscription_models.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/api_providers.dart';
import '../auth/auth_providers.dart';

// Plans provider
final plansProvider = FutureProvider<List<Plan>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getPlans();
});

// Subscription provider for a specific business
final subscriptionProvider =
    FutureProvider.family<Subscription?, String>((ref, businessId) async {
  final apiService = ref.watch(apiServiceProvider);
  try {
    return await apiService.getBusinessSubscription(businessId);
  } catch (e) {
    print('[Subscription] Error fetching subscription: $e');
    return null;
  }
});

// Current business subscription provider (uses auth state)
final currentSubscriptionProvider = FutureProvider<Subscription?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final businessId = authState.businessId;
  
  if (businessId == null) {
    return null;
  }
  
  final apiService = ref.watch(apiServiceProvider);
  try {
    return await apiService.getBusinessSubscription(businessId);
  } catch (e) {
    print('[Subscription] Error fetching current subscription: $e');
    return null;
  }
});

// Subscription state notifier
class SubscriptionState {
  final Subscription? subscription;
  final bool isLoading;
  final String? error;

  SubscriptionState({
    this.subscription,
    this.isLoading = false,
    this.error,
  });

  SubscriptionState copyWith({
    Subscription? subscription,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionState(
      subscription: subscription ?? this.subscription,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get hasActiveSubscription =>
      subscription?.status.isActive ?? false;

  bool hasFeature(String featureKey) =>
      subscription?.hasFeature(featureKey) ?? false;
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final ApiService _apiService;
  final String businessId;

  SubscriptionNotifier(this._apiService, this.businessId)
      : super(SubscriptionState());

  Future<void> loadSubscription() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final subscription = await _apiService.getBusinessSubscription(businessId);
      state = state.copyWith(
        subscription: subscription,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshSubscription() async {
    await loadSubscription();
  }
}

final subscriptionNotifierProvider =
    StateNotifierProvider.family<SubscriptionNotifier, SubscriptionState, String>(
  (ref, businessId) {
    final apiService = ref.watch(apiServiceProvider);
    final notifier = SubscriptionNotifier(apiService, businessId);
    // Load subscription when notifier is created
    Future.microtask(() => notifier.loadSubscription());
    return notifier;
  },
);

// Current business subscription notifier
final currentSubscriptionNotifierProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final authState = ref.watch(authStateProvider);
  final businessId = authState.businessId ?? '';
  final apiService = ref.watch(apiServiceProvider);
  final notifier = SubscriptionNotifier(apiService, businessId);
  if (businessId.isNotEmpty) {
    Future.microtask(() => notifier.loadSubscription());
  }
  return notifier;
});


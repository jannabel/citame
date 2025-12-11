import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/business_models.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/api_providers.dart';

final businessProvider = FutureProvider.family<Business, String>((ref, businessId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getBusiness(businessId);
});

final businessNotifierProvider = StateNotifierProvider<BusinessNotifier, BusinessState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return BusinessNotifier(apiService);
});

class BusinessState {
  final Business? business;
  final bool isLoading;
  final String? error;

  BusinessState({
    this.business,
    this.isLoading = false,
    this.error,
  });

  BusinessState copyWith({
    Business? business,
    bool? isLoading,
    String? error,
  }) {
    return BusinessState(
      business: business ?? this.business,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BusinessNotifier extends StateNotifier<BusinessState> {
  final ApiService _apiService;

  BusinessNotifier(this._apiService) : super(BusinessState());

  Future<void> loadBusiness(String businessId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final business = await _apiService.getBusiness(businessId);
      state = state.copyWith(business: business, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateBusiness(String businessId, Map<String, dynamic> updates) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _apiService.updateBusiness(businessId, updates);
      state = state.copyWith(business: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}


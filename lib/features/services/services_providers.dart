import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/service_models.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/api_providers.dart';

final servicesProvider = FutureProvider.family<List<Service>, String>((ref, businessId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getServices(businessId);
});

final servicesNotifierProvider = StateNotifierProvider<ServicesNotifier, ServicesState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ServicesNotifier(apiService);
});

class ServicesState {
  final List<Service> services;
  final bool isLoading;
  final String? error;

  ServicesState({
    this.services = const [],
    this.isLoading = false,
    this.error,
  });

  ServicesState copyWith({
    List<Service>? services,
    bool? isLoading,
    String? error,
  }) {
    return ServicesState(
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ServicesNotifier extends StateNotifier<ServicesState> {
  final ApiService _apiService;

  ServicesNotifier(this._apiService) : super(ServicesState());

  Future<void> loadServices(String businessId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final services = await _apiService.getServices(businessId);
      state = state.copyWith(services: services, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createService(String businessId, Service service) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.createService(businessId, service);
      await loadServices(businessId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateService(String serviceId, Map<String, dynamic> updates, String businessId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.updateService(serviceId, updates);
      await loadServices(businessId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/auth_models.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/api_providers.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';

final customerAuthStateProvider =
    StateNotifierProvider<CustomerAuthNotifier, CustomerAuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);

  final notifier = CustomerAuthNotifier(apiService, apiClient, storage);
  // Load saved auth after the notifier is created
  Future.microtask(() => notifier.loadSavedAuth());
  return notifier;
});

class CustomerAuthState {
  final bool isLoading;
  final String? accessToken;
  final String? customerId;
  final String? error;

  CustomerAuthState({
    this.isLoading = false,
    this.accessToken,
    this.customerId,
    this.error,
  });

  bool get isAuthenticated => accessToken != null;

  CustomerAuthState copyWith({
    bool? isLoading,
    String? accessToken,
    String? customerId,
    String? error,
  }) {
    return CustomerAuthState(
      isLoading: isLoading ?? this.isLoading,
      accessToken: accessToken ?? this.accessToken,
      customerId: customerId ?? this.customerId,
      error: error,
    );
  }
}

class CustomerAuthNotifier extends StateNotifier<CustomerAuthState> {
  final ApiService _apiService;
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  CustomerAuthNotifier(this._apiService, this._apiClient, this._storage)
      : super(CustomerAuthState());

  Future<void> loadSavedAuth() async {
    print('[CustomerAuth] Loading saved authentication...');
    try {
      final token = await _storage.getCustomerAccessToken();
      final customerId = await _storage.getCustomerId();

      if (token != null && token.isNotEmpty) {
        print('[CustomerAuth] Found saved token, restoring session');
        // Update API client with saved token
        await _apiClient.setCustomerAccessToken(token);
        state = state.copyWith(accessToken: token, customerId: customerId);
        print(
          '[CustomerAuth] Session restored - isAuthenticated: ${state.isAuthenticated}',
        );
      } else {
        print('[CustomerAuth] No saved token found');
      }
    } catch (e) {
      print('[CustomerAuth] Error loading saved auth: $e');
    }
  }

  Future<void> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    print('[CustomerAuth] Sign up started');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.customerSignUp(
        CustomerSignUpRequest(
          name: name,
          phone: phone,
          email: email,
          password: password,
        ),
      );
      print(
        '[CustomerAuth] Sign up response received - accessToken: ${response.accessToken.isNotEmpty ? "***" : "EMPTY"}, customerId: ${response.customerId}',
      );

      // Save to secure storage
      await _storage.saveCustomerAccessToken(response.accessToken);
      if (response.refreshToken != null) {
        await _storage.saveCustomerRefreshToken(response.refreshToken!);
      }
      await _storage.saveCustomerId(response.customerId);

      // Update API client
      await _apiClient.setCustomerAccessToken(response.accessToken);

      print(
        '[CustomerAuth] Setting state - customerId: ${response.customerId}, authenticated: true',
      );
      state = state.copyWith(
        isLoading: false,
        accessToken: response.accessToken,
        customerId: response.customerId,
      );
      print(
        '[CustomerAuth] State updated - isAuthenticated: ${state.isAuthenticated}',
      );
    } catch (e) {
      print('[CustomerAuth] Sign up error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow; // Re-throw so the UI can handle it
    }
  }

  Future<void> login(String email, String password) async {
    print('[CustomerAuth] Login started - email: $email');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.customerLogin(
        CustomerLoginRequest(email: email, password: password),
      );
      print(
        '[CustomerAuth] Login response received - accessToken: ${response.accessToken.isNotEmpty ? "***" : "EMPTY"}, customerId: ${response.customerId}',
      );

      // Save to secure storage
      await _storage.saveCustomerAccessToken(response.accessToken);
      if (response.refreshToken != null) {
        await _storage.saveCustomerRefreshToken(response.refreshToken!);
      }
      await _storage.saveCustomerId(response.customerId);

      // Update API client
      await _apiClient.setCustomerAccessToken(response.accessToken);

      print(
        '[CustomerAuth] Setting state - customerId: ${response.customerId}, authenticated: true',
      );
      state = state.copyWith(
        isLoading: false,
        accessToken: response.accessToken,
        customerId: response.customerId,
      );
      print(
        '[CustomerAuth] State updated - isAuthenticated: ${state.isAuthenticated}',
      );
    } catch (e) {
      print('[CustomerAuth] Login error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow; // Re-throw so the UI can handle it
    }
  }

  Future<void> logout() async {
    print('[CustomerAuth] Logging out...');
    await _apiClient.clearCustomerAccessToken();
    await _storage.deleteCustomerRefreshToken();
    await _storage.deleteCustomerId();
    state = CustomerAuthState();
    print('[CustomerAuth] Logout complete');
  }
}


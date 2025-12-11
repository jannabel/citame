import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/auth_models.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/api_providers.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);

  final notifier = AuthNotifier(apiService, apiClient, storage);
  // Load saved auth after the notifier is created
  Future.microtask(() => notifier.loadSavedAuth());
  return notifier;
});

class AuthState {
  final bool isLoading;
  final String? accessToken;
  final String? businessId;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.accessToken,
    this.businessId,
    this.error,
  });

  bool get isAuthenticated => accessToken != null;

  AuthState copyWith({
    bool? isLoading,
    String? accessToken,
    String? businessId,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      accessToken: accessToken ?? this.accessToken,
      businessId: businessId ?? this.businessId,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthNotifier(this._apiService, this._apiClient, this._storage)
    : super(AuthState());

  Future<void> loadSavedAuth() async {
    print('[Auth] Loading saved authentication...');
    try {
      final token = await _storage.getAccessToken();
      final businessId = await _storage.getBusinessId();

      if (token != null && token.isNotEmpty) {
        print('[Auth] Found saved token, restoring session');
        // Update API client with saved token
        await _apiClient.setAccessToken(token);
        state = state.copyWith(accessToken: token, businessId: businessId);
        print(
          '[Auth] Session restored - isAuthenticated: ${state.isAuthenticated}',
        );
      } else {
        print('[Auth] No saved token found');
      }
    } catch (e) {
      print('[Auth] Error loading saved auth: $e');
    }
  }

  Future<void> login(String email, String password) async {
    print('[Auth] Login started - email: $email');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.login(
        LoginRequest(email: email, password: password),
      );
      print(
        '[Auth] Login response received - accessToken: ${response.accessToken.isNotEmpty ? "***" : "EMPTY"}, businessId: ${response.businessId}',
      );

      // Use businessId from response
      final responseBusinessId = response.businessId;

      // Save to secure storage
      await _storage.saveAccessToken(response.accessToken);
      if (response.refreshToken != null) {
        await _storage.saveRefreshToken(response.refreshToken!);
      }
      await _storage.saveBusinessId(responseBusinessId);

      // Update API client
      await _apiClient.setAccessToken(response.accessToken);

      print(
        '[Auth] Setting state - businessId: $responseBusinessId, authenticated: true',
      );
      state = state.copyWith(
        isLoading: false,
        accessToken: response.accessToken,
        businessId: responseBusinessId,
      );
      print('[Auth] State updated - isAuthenticated: ${state.isAuthenticated}');
    } catch (e) {
      print('[Auth] Login error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow; // Re-throw so the UI can handle it
    }
  }

  Future<void> logout() async {
    print('[Auth] Logging out...');
    await _apiClient.clearAccessToken();
    await _storage.deleteRefreshToken();
    await _storage.deleteBusinessId();
    state = AuthState();
    print('[Auth] Logout complete');
  }

  Future<void> setAccessToken(String token, {String? refreshToken}) async {
    print('[Auth] Setting access token');
    await _storage.saveAccessToken(token);
    if (refreshToken != null) {
      await _storage.saveRefreshToken(refreshToken);
    }
    await _apiClient.setAccessToken(token);
    state = state.copyWith(accessToken: token);
  }
}

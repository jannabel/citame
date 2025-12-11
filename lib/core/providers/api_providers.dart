import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../network/api_client.dart';
import '../network/api_service.dart';
import '../storage/secure_storage_service.dart';
import '../config/app_config.dart';
import '../models/auth_models.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final client = ApiClient(storage: storage);
  
  // Set up refresh token callback - using direct HTTP call to avoid circular dependency
  client.setRefreshTokenCallback(() async {
    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        print('[ApiProviders] No refresh token available');
        return null;
      }

      // Make refresh token request directly
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.refreshTokenEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final refreshResponse = RefreshTokenResponse.fromJson(json);
        
        // Save refresh token
        await storage.saveRefreshToken(refreshResponse.refreshToken);
        
        return refreshResponse.accessToken;
      } else {
        print('[ApiProviders] Token refresh failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[ApiProviders] Error refreshing token: $e');
      return null;
    }
  });
  
  return client;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiService(client);
});

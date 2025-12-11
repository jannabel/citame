import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

  // Keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _businessIdKey = 'business_id';
  static const String _customerAccessTokenKey = 'customer_access_token';
  static const String _customerRefreshTokenKey = 'customer_refresh_token';
  static const String _customerIdKey = 'customer_id';

  // Token operations
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  // Refresh token operations
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  // Business ID operations
  Future<void> saveBusinessId(String businessId) async {
    await _storage.write(key: _businessIdKey, value: businessId);
  }

  Future<String?> getBusinessId() async {
    return await _storage.read(key: _businessIdKey);
  }

  Future<void> deleteBusinessId() async {
    await _storage.delete(key: _businessIdKey);
  }

  // Customer token operations
  Future<void> saveCustomerAccessToken(String token) async {
    await _storage.write(key: _customerAccessTokenKey, value: token);
  }

  Future<String?> getCustomerAccessToken() async {
    return await _storage.read(key: _customerAccessTokenKey);
  }

  Future<void> deleteCustomerAccessToken() async {
    await _storage.delete(key: _customerAccessTokenKey);
  }

  // Customer refresh token operations
  Future<void> saveCustomerRefreshToken(String token) async {
    await _storage.write(key: _customerRefreshTokenKey, value: token);
  }

  Future<String?> getCustomerRefreshToken() async {
    return await _storage.read(key: _customerRefreshTokenKey);
  }

  Future<void> deleteCustomerRefreshToken() async {
    await _storage.delete(key: _customerRefreshTokenKey);
  }

  // Customer ID operations
  Future<void> saveCustomerId(String customerId) async {
    await _storage.write(key: _customerIdKey, value: customerId);
  }

  Future<String?> getCustomerId() async {
    return await _storage.read(key: _customerIdKey);
  }

  Future<void> deleteCustomerId() async {
    await _storage.delete(key: _customerIdKey);
  }

  // Clear all auth data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  final String baseUrl;
  String? accessToken;
  String? customerAccessToken; // Separate token for customer auth
  final SecureStorageService _storage;
  bool _tokenLoaded = false;
  bool _customerTokenLoaded = false;
  bool _isRefreshing = false;
  Future<String?> Function()? _refreshTokenCallback;

  ApiClient({
    String? baseUrl,
    String? accessToken,
    required SecureStorageService storage,
    Future<String?> Function()? refreshTokenCallback,
  }) : baseUrl = baseUrl ?? AppConfig.baseUrl,
       _storage = storage,
       accessToken = accessToken,
       _refreshTokenCallback = refreshTokenCallback {
    // Mark as loaded if token is provided, otherwise will load on first request
    if (accessToken != null) {
      _tokenLoaded = true;
    }
  }

  void setRefreshTokenCallback(Future<String?> Function() callback) {
    _refreshTokenCallback = callback;
  }

  Future<void> _loadToken() async {
    if (!_tokenLoaded) {
      try {
        final token = await _storage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          accessToken = token;
        }
        _tokenLoaded = true;
      } catch (e) {
        print('[ApiClient] Error loading token: $e');
        _tokenLoaded = true;
      }
    }
  }

  Future<void> setAccessToken(String token) async {
    accessToken = token;
    await _storage.saveAccessToken(token);
    _tokenLoaded = true;
  }

  Future<void> clearAccessToken() async {
    accessToken = null;
    await _storage.deleteAccessToken();
  }

  Future<void> setRefreshToken(String token) async {
    await _storage.saveRefreshToken(token);
  }

  // Customer token methods
  Future<void> _loadCustomerToken() async {
    if (!_customerTokenLoaded) {
      try {
        final token = await _storage.getCustomerAccessToken();
        if (token != null && token.isNotEmpty) {
          customerAccessToken = token;
        }
        _customerTokenLoaded = true;
      } catch (e) {
        print('[ApiClient] Error loading customer token: $e');
        _customerTokenLoaded = true;
      }
    }
  }

  Future<void> setCustomerAccessToken(String token) async {
    customerAccessToken = token;
    await _storage.saveCustomerAccessToken(token);
    _customerTokenLoaded = true;
  }

  Future<void> clearCustomerAccessToken() async {
    customerAccessToken = null;
    await _storage.deleteCustomerAccessToken();
  }

  // Ensure token is loaded before making requests
  Future<void> ensureTokenLoaded() async {
    await _loadToken();
  }

  // Check if response is a 401 with jwt expired error
  bool _isTokenExpiredError(http.Response response) {
    if (response.statusCode != 401) {
      return false;
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final message = json['message'] as String? ?? '';
      return message.toLowerCase().contains('jwt expired') ||
          message.toLowerCase().contains('token expired');
    } catch (e) {
      // If we can't parse the response, assume it's a token error if it's 401
      return true;
    }
  }

  // Attempt to refresh the token
  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      // Wait for ongoing refresh to complete
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return accessToken != null;
    }

    if (_refreshTokenCallback == null) {
      print('[ApiClient] No refresh token callback available');
      return false;
    }

    _isRefreshing = true;
    try {
      print('[ApiClient] Attempting to refresh token...');
      final newAccessToken = await _refreshTokenCallback!();
      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        await setAccessToken(newAccessToken);
        print('[ApiClient] Token refreshed successfully');
        _isRefreshing = false;
        return true;
      } else {
        print('[ApiClient] Token refresh returned null or empty token');
        _isRefreshing = false;
        return false;
      }
    } catch (e) {
      print('[ApiClient] Token refresh failed: $e');
      _isRefreshing = false;
      return false;
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
  };

  Map<String, String> get _customerHeaders => {
    'Content-Type': 'application/json',
    if (customerAccessToken != null)
      'Authorization': 'Bearer $customerAccessToken',
  };

  Map<String, String> get _guestHeaders => {'Content-Type': 'application/json'};

  Future<http.Response> get(String endpoint) async {
    await ensureTokenLoaded();
    var response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );

    // Check if token expired and try to refresh (but not for auth endpoints)
    if (_isTokenExpiredError(response) && !endpoint.contains('/auth/')) {
      print('[ApiClient] Token expired, attempting refresh...');
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry the request with new token
        response = await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: _headers,
        );
      }
    }

    return response;
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool useCustomerToken = false,
    bool useGuestMode = false,
  }) async {
    if (!useGuestMode) {
      if (useCustomerToken) {
        await _loadCustomerToken();
      } else {
        await ensureTokenLoaded();
      }
    }
    final url = Uri.parse('$baseUrl$endpoint');
    final bodyJson = body != null ? jsonEncode(body) : null;

    final headers = useGuestMode
        ? _guestHeaders
        : useCustomerToken
        ? _customerHeaders
        : _headers;

    print('[ApiClient] POST to: $url');
    print('[ApiClient] Headers: $headers');
    print('[ApiClient] Body: $bodyJson');

    var response = await http.post(url, headers: headers, body: bodyJson);

    print('[ApiClient] Response status: ${response.statusCode}');
    print('[ApiClient] Response body: ${response.body}');

    // Check if token expired and try to refresh (but not for auth endpoints or guest mode)
    if (!useGuestMode &&
        !useCustomerToken &&
        _isTokenExpiredError(response) &&
        !endpoint.contains('/auth/')) {
      print('[ApiClient] Token expired, attempting refresh...');
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry the request with new token
        response = await http.post(url, headers: _headers, body: bodyJson);
        print('[ApiClient] Retry response status: ${response.statusCode}');
      }
    }

    return response;
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    await ensureTokenLoaded();
    final url = Uri.parse('$baseUrl$endpoint');
    final bodyJson = body != null ? jsonEncode(body) : null;

    var response = await http.patch(url, headers: _headers, body: bodyJson);

    // Check if token expired and try to refresh (but not for auth endpoints)
    if (_isTokenExpiredError(response) && !endpoint.contains('/auth/')) {
      print('[ApiClient] Token expired, attempting refresh...');
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry the request with new token
        response = await http.patch(url, headers: _headers, body: bodyJson);
      }
    }

    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    await ensureTokenLoaded();
    final url = Uri.parse('$baseUrl$endpoint');

    var response = await http.delete(url, headers: _headers);

    // Check if token expired and try to refresh (but not for auth endpoints)
    if (_isTokenExpiredError(response) && !endpoint.contains('/auth/')) {
      print('[ApiClient] Token expired, attempting refresh...');
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry the request with new token
        response = await http.delete(url, headers: _headers);
      }
    }

    return response;
  }
}

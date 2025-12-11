class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class LoginResponse {
  final String accessToken;
  final String? refreshToken;
  final String businessId;

  LoginResponse({
    required this.accessToken,
    this.refreshToken,
    required this.businessId,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    accessToken:
        json['access_token'] as String? ?? json['accessToken'] as String,
    refreshToken:
        json['refresh_token'] as String? ?? json['refreshToken'] as String?,
    businessId:
        json['businessId'] as String? ?? json['business_id'] as String? ?? '',
  );
}

class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {
        'refresh_token': refreshToken,
      };
}

class RefreshTokenResponse {
  final String accessToken;
  final String refreshToken;
  final String businessId;

  RefreshTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.businessId,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) =>
      RefreshTokenResponse(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        businessId: json['businessId'] as String? ??
            json['business_id'] as String? ??
            '',
      );
}

// Business Sign Up
class BusinessSignUpRequest {
  final String password;
  final String name;
  final String email;
  final String phone;

  BusinessSignUpRequest({
    required this.password,
    required this.name,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
    'password': password,
    'name': name,
    'email': email,
    'phone': phone,
  };
}

// Customer Sign Up
class CustomerSignUpRequest {
  final String name;
  final String phone;
  final String email;
  final String password;

  CustomerSignUpRequest({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'password': password,
  };
}

// Customer Login
class CustomerLoginRequest {
  final String email;
  final String password;

  CustomerLoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

// Customer Login Response
class CustomerLoginResponse {
  final String accessToken;
  final String? refreshToken;
  final String customerId;

  CustomerLoginResponse({
    required this.accessToken,
    this.refreshToken,
    required this.customerId,
  });

  factory CustomerLoginResponse.fromJson(Map<String, dynamic> json) =>
      CustomerLoginResponse(
        accessToken:
            json['access_token'] as String? ?? json['accessToken'] as String,
        refreshToken:
            json['refresh_token'] as String? ?? json['refreshToken'] as String?,
        customerId:
            json['customerId'] as String? ?? json['customer_id'] as String? ?? '',
      );
}

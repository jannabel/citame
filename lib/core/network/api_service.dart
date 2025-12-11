import 'dart:convert';
import '../config/app_config.dart';
import '../models/auth_models.dart';
import '../models/business_models.dart';
import '../models/schedule_models.dart';
import '../models/service_models.dart';
import '../models/employee_models.dart';
import '../models/customer_models.dart';
import '../models/appointment_models.dart';
import '../models/subscription_models.dart';
import 'api_client.dart';

class ApiService {
  final ApiClient _client;

  ApiService(this._client);

  // Auth
  Future<LoginResponse> businessSignUp(BusinessSignUpRequest request) async {
    print('[API] Business sign up request: ${request.toJson()}');
    print('[API] URL: ${AppConfig.baseUrl}${AppConfig.businessSignUpEndpoint}');

    final response = await _client.post(
      AppConfig.businessSignUpEndpoint,
      body: request.toJson(),
      useGuestMode: true,
    );

    print('[API] Business sign up response status: ${response.statusCode}');
    print('[API] Business sign up response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final loginResponse = LoginResponse.fromJson(json);
      await _client.setAccessToken(loginResponse.accessToken);
      return loginResponse;
    } else {
      String errorMessage = 'Sign up failed';
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorJson['message'] as String? ??
            errorJson['error'] as String? ??
            errorMessage;
      } catch (e) {
        errorMessage = 'Sign up failed: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  Future<LoginResponse> login(LoginRequest request) async {
    print('[API] Login request: ${request.toJson()}');
    print('[API] URL: ${AppConfig.baseUrl}${AppConfig.loginEndpoint}');

    final response = await _client.post(
      AppConfig.loginEndpoint,
      body: request.toJson(),
    );

    print('[API] Login response status: ${response.statusCode}');
    print('[API] Login response body: ${response.body}');

    // Accept both 200 (OK) and 201 (Created) status codes
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      print('[API] Parsed JSON: $json');
      final loginResponse = LoginResponse.fromJson(json);
      print(
        '[API] LoginResponse - accessToken: ${loginResponse.accessToken.isNotEmpty ? "***" : "EMPTY"}, businessId: ${loginResponse.businessId}',
      );
      await _client.setAccessToken(loginResponse.accessToken);
      print('[API] Access token saved to secure storage');
      return loginResponse;
    } else {
      String errorMessage = 'Login failed';
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorJson['message'] as String? ??
            errorJson['error'] as String? ??
            errorMessage;
        print('[API] Error message from response: $errorMessage');
      } catch (e) {
        errorMessage = 'Login failed: ${response.statusCode}';
        print('[API] Error parsing response body: $e');
      }
      throw Exception(errorMessage);
    }
  }

  // Customer Auth
  Future<CustomerLoginResponse> customerSignUp(
    CustomerSignUpRequest request,
  ) async {
    print('[API] Customer sign up request: ${request.toJson()}');
    print('[API] URL: ${AppConfig.baseUrl}${AppConfig.customerSignUpEndpoint}');

    final response = await _client.post(
      AppConfig.customerSignUpEndpoint,
      body: request.toJson(),
      useGuestMode: true,
    );

    print('[API] Customer sign up response status: ${response.statusCode}');
    print('[API] Customer sign up response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final loginResponse = CustomerLoginResponse.fromJson(json);
      await _client.setCustomerAccessToken(loginResponse.accessToken);
      return loginResponse;
    } else {
      String errorMessage = 'Customer sign up failed';
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorJson['message'] as String? ??
            errorJson['error'] as String? ??
            errorMessage;
      } catch (e) {
        errorMessage = 'Customer sign up failed: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  Future<CustomerLoginResponse> customerLogin(
    CustomerLoginRequest request,
  ) async {
    print('[API] Customer login request: ${request.toJson()}');
    print('[API] URL: ${AppConfig.baseUrl}${AppConfig.customerLoginEndpoint}');

    final response = await _client.post(
      AppConfig.customerLoginEndpoint,
      body: request.toJson(),
      useGuestMode: true,
    );

    print('[API] Customer login response status: ${response.statusCode}');
    print('[API] Customer login response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final loginResponse = CustomerLoginResponse.fromJson(json);
      await _client.setCustomerAccessToken(loginResponse.accessToken);
      return loginResponse;
    } else {
      String errorMessage = 'Customer login failed';
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorJson['message'] as String? ??
            errorJson['error'] as String? ??
            errorMessage;
      } catch (e) {
        errorMessage = 'Customer login failed: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  Future<RefreshTokenResponse> refreshToken(String refreshToken) async {
    print('[API] Refreshing token...');
    final response = await _client.post(
      AppConfig.refreshTokenEndpoint,
      body: RefreshTokenRequest(refreshToken: refreshToken).toJson(),
    );

    print('[API] Refresh token response status: ${response.statusCode}');
    print('[API] Refresh token response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final refreshResponse = RefreshTokenResponse.fromJson(json);
      await _client.setAccessToken(refreshResponse.accessToken);
      print('[API] Access token refreshed and saved');
      return refreshResponse;
    } else {
      String errorMessage = 'Token refresh failed';
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorJson['message'] as String? ??
            errorJson['error'] as String? ??
            errorMessage;
      } catch (e) {
        errorMessage = 'Token refresh failed: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  // Business
  Future<Business> createBusiness(Map<String, dynamic> businessData) async {
    final response = await _client.post(
      AppConfig.businessEndpoint,
      body: businessData,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Business.fromJson(json);
    } else {
      String errorMessage = 'Failed to create business';
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorJson['message'] as String? ??
            errorJson['error'] as String? ??
            errorMessage;
      } catch (e) {
        errorMessage = 'Failed to create business: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  Future<Business> getBusiness(String businessId) async {
    final response = await _client.get(
      '${AppConfig.businessEndpoint}/$businessId',
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Business.fromJson(json);
    } else {
      throw Exception('Failed to get business: ${response.statusCode}');
    }
  }

  Future<Business> updateBusiness(
    String businessId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _client.patch(
      '${AppConfig.businessEndpoint}/$businessId',
      body: updates,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Business.fromJson(json);
    } else {
      throw Exception('Failed to update business: ${response.statusCode}');
    }
  }

  // Schedule
  Future<List<Schedule>> getSchedules(String businessId) async {
    final response = await _client.get(
      AppConfig.scheduleEndpoint.replaceAll('{businessId}', businessId),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as List<dynamic>;
      return json
          .map((e) => Schedule.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to get schedules: ${response.statusCode}');
    }
  }

  Future<Schedule> createSchedule(String businessId, Schedule schedule) async {
    final response = await _client.post(
      AppConfig.scheduleEndpoint.replaceAll('{businessId}', businessId),
      body: schedule.toJson(),
    );
    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Schedule.fromJson(json);
    } else {
      throw Exception('Failed to create schedule: ${response.statusCode}');
    }
  }

  Future<Schedule> updateSchedule(
    String scheduleId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _client.patch(
      '/schedule/$scheduleId',
      body: updates,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Schedule.fromJson(json);
    } else {
      throw Exception('Failed to update schedule: ${response.statusCode}');
    }
  }

  // Schedule Exceptions
  Future<List<ScheduleException>> getExceptions(String businessId) async {
    final response = await _client.get(
      AppConfig.exceptionsEndpoint.replaceAll('{businessId}', businessId),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as List<dynamic>;
      return json
          .map((e) => ScheduleException.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to get exceptions: ${response.statusCode}');
    }
  }

  Future<ScheduleException> createException(
    String businessId,
    ScheduleException exception,
  ) async {
    final response = await _client.post(
      AppConfig.exceptionsEndpoint.replaceAll('{businessId}', businessId),
      body: exception.toJson(),
    );
    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ScheduleException.fromJson(json);
    } else {
      throw Exception('Failed to create exception: ${response.statusCode}');
    }
  }

  Future<void> deleteException(String exceptionId) async {
    final response = await _client.delete('/exceptions/$exceptionId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete exception: ${response.statusCode}');
    }
  }

  // Services
  Future<List<Service>> getServices(String businessId) async {
    final response = await _client.get(
      AppConfig.servicesEndpoint.replaceAll('{businessId}', businessId),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as List<dynamic>;
      return json
          .map((e) => Service.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to get services: ${response.statusCode}');
    }
  }

  Future<Service> createService(String businessId, Service service) async {
    final response = await _client.post(
      AppConfig.servicesEndpoint.replaceAll('{businessId}', businessId),
      body: service.toJson(),
    );
    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Service.fromJson(json);
    } else {
      throw Exception('Failed to create service: ${response.statusCode}');
    }
  }

  Future<Service> updateService(
    String serviceId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _client.patch('/services/$serviceId', body: updates);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Service.fromJson(json);
    } else {
      throw Exception('Failed to update service: ${response.statusCode}');
    }
  }

  // Employees
  Future<List<Employee>> getEmployees(String businessId) async {
    print('[API] Getting employees for business: $businessId');
    final response = await _client.get(
      AppConfig.employeesEndpoint.replaceAll('{businessId}', businessId),
    );
    print('[API] Get employees response status: ${response.statusCode}');
    print('[API] Get employees response body: ${response.body}');
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as List<dynamic>;
      final employees = json.map((e) {
        print('[API] Parsing employee: $e');
        return Employee.fromJson(e as Map<String, dynamic>);
      }).toList();
      print('[API] Parsed ${employees.length} employees');
      for (var emp in employees) {
        print(
          '[API] Employee ${emp.name} has ${emp.serviceIds.length} services: ${emp.serviceIds}',
        );
      }
      return employees;
    } else {
      throw Exception('Failed to get employees: ${response.statusCode}');
    }
  }

  Future<Employee> createEmployee(String businessId, Employee employee) async {
    final response = await _client.post(
      AppConfig.employeesEndpoint.replaceAll('{businessId}', businessId),
      body: employee.toJson(),
    );
    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Employee.fromJson(json);
    } else {
      throw Exception('Failed to create employee: ${response.statusCode}');
    }
  }

  Future<Employee> updateEmployee(
    String employeeId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _client.patch(
      '/employees/$employeeId',
      body: updates,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Employee.fromJson(json);
    } else {
      throw Exception('Failed to update employee: ${response.statusCode}');
    }
  }

  Future<void> assignServiceToEmployee(
    String employeeId,
    String serviceId,
  ) async {
    print('[API] Assigning service $serviceId to employee $employeeId');
    final response = await _client.post(
      '/employees/$employeeId/services',
      body: {'serviceId': serviceId},
    );
    print(
      '[API] Assign service response: ${response.statusCode} - ${response.body}',
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      String errorMessage = 'Failed to assign service';
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorJson['message'] as String? ??
            errorJson['error'] as String? ??
            errorMessage;
      } catch (e) {
        errorMessage = 'Failed to assign service: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
    print('[API] Service assigned successfully');
  }

  Future<void> unassignServiceFromEmployee(
    String employeeId,
    String serviceId,
  ) async {
    print('[API] Unassigning service $serviceId from employee $employeeId');
    final response = await _client.delete(
      '/employees/$employeeId/services/$serviceId',
    );
    print(
      '[API] Unassign service response: ${response.statusCode} - ${response.body}',
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      String errorMessage = 'Failed to unassign service';
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorJson['message'] as String? ??
            errorJson['error'] as String? ??
            errorMessage;
      } catch (e) {
        errorMessage = 'Failed to unassign service: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
    print('[API] Service unassigned successfully');
  }

  // Customers
  Future<Customer> createCustomer(Customer customer) async {
    final response = await _client.post(
      AppConfig.customersEndpoint,
      body: customer.toJson(),
    );
    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Customer.fromJson(json);
    } else {
      throw Exception('Failed to create customer: ${response.statusCode}');
    }
  }

  Future<Customer> getCustomer(String customerId) async {
    final response = await _client.get(
      '${AppConfig.customersEndpoint}/$customerId',
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Customer.fromJson(json);
    } else {
      throw Exception('Failed to get customer: ${response.statusCode}');
    }
  }

  // Appointments
  Future<Appointment> createAppointment(
    Map<String, dynamic> appointment, {
    bool useCustomerToken = false,
    bool useGuestMode = false,
  }) async {
    final response = await _client.post(
      AppConfig.appointmentsEndpoint,
      body: appointment,
      useCustomerToken: useCustomerToken,
      useGuestMode: useGuestMode,
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Appointment.fromJson(json);
    } else {
      String errorMessage = 'Failed to create appointment';
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorJson['message'] as String? ??
            errorJson['error'] as String? ??
            errorMessage;
      } catch (e) {
        errorMessage = 'Failed to create appointment: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  Future<Appointment> getAppointment(String appointmentId) async {
    final response = await _client.get(
      '${AppConfig.appointmentsEndpoint}/$appointmentId',
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Appointment.fromJson(json);
    } else {
      throw Exception('Failed to get appointment: ${response.statusCode}');
    }
  }

  Future<List<Appointment>> getUpcomingAppointments(String businessId) async {
    print('[API] Getting upcoming appointments for businessId: $businessId');
    final endpoint = AppConfig.upcomingAppointmentsEndpoint.replaceAll(
      '{businessId}',
      businessId,
    );
    print('[API] Endpoint: $endpoint');
    print('[API] Full URL: ${AppConfig.baseUrl}$endpoint');

    try {
      final response = await _client.get(endpoint);
      print(
        '[API] Upcoming appointments response status: ${response.statusCode}',
      );
      print('[API] Upcoming appointments response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;
        final appointments = json
            .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
            .toList();
        print('[API] Parsed ${appointments.length} upcoming appointments');
        return appointments;
      } else {
        String errorMessage =
            'Failed to get upcoming appointments: ${response.statusCode}';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage =
              errorJson['message'] as String? ??
              errorJson['error'] as String? ??
              errorMessage;
        } catch (e) {
          print('[API] Error parsing error response: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[API] Exception getting upcoming appointments: $e');
      rethrow;
    }
  }

  Future<List<String>> getAvailableTimeSlots({
    required String businessId,
    required String serviceId,
    required String date,
  }) async {
    final endpoint = AppConfig.availableSlotsEndpoint.replaceAll(
      '{businessId}',
      businessId,
    );
    final url = '$endpoint?date=$date';
    final response = await _client.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final slots = json['slots'] as List<dynamic>?;
      if (slots != null) {
        return slots.map((e) => e as String).toList();
      }
      return [];
    } else {
      throw Exception(
        'Failed to get available time slots: ${response.statusCode}',
      );
    }
  }

  Future<Appointment> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatusUpdate update,
  ) async {
    print('[API] Updating appointment status: $appointmentId');
    print('[API] Update data: ${update.toJson()}');
    final response = await _client.patch(
      '${AppConfig.appointmentsEndpoint}/$appointmentId/status',
      body: update.toJson(),
    );
    print('[API] Update status response: ${response.statusCode}');
    print('[API] Update status response body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Appointment.fromJson(json);
    } else {
      String errorMessage = 'Failed to update appointment status';
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorJson['message'] as String? ??
            errorJson['error'] as String? ??
            errorMessage;
      } catch (e) {
        errorMessage =
            'Failed to update appointment status: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  Future<Appointment> updateAppointment(
    String appointmentId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _client.patch(
      '${AppConfig.appointmentsEndpoint}/$appointmentId',
      body: updates,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Appointment.fromJson(json);
    } else {
      String errorMessage = 'Failed to update appointment';
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorJson['message'] as String? ??
            errorJson['error'] as String? ??
            errorMessage;
      } catch (e) {
        errorMessage = 'Failed to update appointment: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  Future<Appointment> rescheduleAppointment(
    String appointmentId,
    RescheduleAppointmentRequest request,
  ) async {
    print('[API] Rescheduling appointment: $appointmentId');
    print('[API] Reschedule data: ${request.toJson()}');
    final response = await _client.post(
      '${AppConfig.appointmentsEndpoint}/$appointmentId/reschedule',
      body: request.toJson(),
    );
    print('[API] Reschedule response: ${response.statusCode}');
    print('[API] Reschedule response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Appointment.fromJson(json);
    } else {
      String errorMessage = 'Failed to reschedule appointment';
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorJson['message'] as String? ??
            errorJson['error'] as String? ??
            errorMessage;
      } catch (e) {
        errorMessage =
            'Failed to reschedule appointment: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  // Subscriptions
  Future<List<Plan>> getPlans() async {
    final response = await _client.get(AppConfig.plansEndpoint);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as List<dynamic>;
      return json.map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get plans: ${response.statusCode}');
    }
  }

  Future<Subscription> getBusinessSubscription(String businessId) async {
    final endpoint = AppConfig.subscriptionEndpoint.replaceAll(
      '{businessId}',
      businessId,
    );
    final response = await _client.get(endpoint);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Subscription.fromJson(json);
    } else if (response.statusCode == 404) {
      throw Exception('Subscription not found');
    } else {
      throw Exception('Failed to get subscription: ${response.statusCode}');
    }
  }

  Future<CreateCheckoutResponse> createCheckout(
    String businessId,
    String planId,
  ) async {
    final endpoint = AppConfig.createCheckoutEndpoint.replaceAll(
      '{businessId}',
      businessId,
    );
    final response = await _client.post(
      endpoint,
      body: CreateCheckoutRequest(planId: planId).toJson(),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return CreateCheckoutResponse.fromJson(json);
    } else {
      String errorMessage = 'Failed to create checkout';
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorJson['message'] as String? ??
            errorJson['error'] as String? ??
            errorMessage;
      } catch (e) {
        errorMessage = 'Failed to create checkout: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }
}

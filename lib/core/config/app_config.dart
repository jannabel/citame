class AppConfig {
  static const String baseUrl =
      'https://appointment-backend-production-416d.up.railway.app';

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String businessSignUpEndpoint = '/auth/register';
  static const String customerSignUpEndpoint = '/auth/register';
  static const String customerLoginEndpoint = '/auth/login';
  static const String businessEndpoint = '/business';
  static const String scheduleEndpoint = '/business/{businessId}/schedule';
  static const String exceptionsEndpoint = '/business/{businessId}/exceptions';
  static const String employeesEndpoint = '/business/{businessId}/employees';
  static const String servicesEndpoint = '/business/{businessId}/services';
  static const String customersEndpoint = '/customers';
  static const String appointmentsEndpoint = '/appointments';
  static const String upcomingAppointmentsEndpoint =
      '/business/{businessId}/appointments/upcoming';
  static const String availableSlotsEndpoint = '/business/{businessId}/slots';

  // Subscription endpoints
  static const String plansEndpoint = '/plans';
  static const String subscriptionEndpoint =
      '/business/{businessId}/subscription';
  static const String createCheckoutEndpoint =
      '/business/{businessId}/create-checkout';
}

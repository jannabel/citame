import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/auth_providers.dart';
import '../../features/auth/business_signup_screen.dart';
import '../../features/auth/business_setup_screen.dart';
import '../../features/customer/customer_signup_screen.dart';
import '../../features/customer/customer_login_screen.dart';
import '../../features/navigation/main_navigation_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/business/business_settings_screen.dart';
import '../../features/business/profile_settings_screen.dart';
import '../../features/business/working_hours_settings_screen.dart';
import '../../features/business/exceptions_settings_screen.dart';
import '../../features/business/deposits_settings_screen.dart';
import '../../features/services/services_screen.dart';
import '../../features/employees/employees_screen.dart';
import '../../features/appointments/appointments_screen.dart';
import '../../features/customer/customer_booking_screen.dart';
import '../../features/subscriptions/subscription_plans_screen.dart';
import '../../features/subscriptions/subscription_success_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/signup/business',
    redirect: (context, state) {
      // Read auth state dynamically on each redirect
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState.isAuthenticated;
      final currentPath = state.uri.path;
      final matchedLocation = state.matchedLocation;
      final isLoggingIn =
          currentPath == '/login' || matchedLocation == '/login';

      // Public routes that don't require authentication
      // Check both uri.path and matchedLocation to catch routes with parameters
      final isPublicRoute =
          currentPath == '/login' ||
          matchedLocation == '/login' ||
          currentPath == '/signup/business' ||
          matchedLocation == '/signup/business' ||
          currentPath == '/signup/customer' ||
          matchedLocation == '/signup/customer' ||
          currentPath == '/login/customer' ||
          matchedLocation == '/login/customer' ||
          currentPath == '/business/setup' ||
          matchedLocation == '/business/setup' ||
          currentPath.startsWith('/book/') ||
          matchedLocation.startsWith('/book/') ||
          currentPath == '/subscription/success' ||
          matchedLocation == '/subscription/success';

      print(
        '[Router] Redirect check - uri.path: $currentPath, matchedLocation: $matchedLocation, isAuthenticated: $isAuthenticated, isPublicRoute: $isPublicRoute',
      );

      // Allow public routes without authentication
      if (isPublicRoute) {
        if (isAuthenticated && isLoggingIn) {
          print('[Router] Redirecting to /home (authenticated on login page)');
          return '/home';
        }
        print('[Router] No redirect needed (public route)');
        return null;
      }

      // Protected routes require authentication
      if (!isAuthenticated && !isLoggingIn) {
        print('[Router] Redirecting to /login (not authenticated)');
        return '/login';
      }
      if (isAuthenticated && isLoggingIn) {
        print('[Router] Redirecting to /home (authenticated on login page)');
        return '/home';
      }
      // Redirect /dashboard to /home for consistency
      if (isAuthenticated &&
          (currentPath == '/dashboard' || matchedLocation == '/dashboard')) {
        print('[Router] Redirecting /dashboard to /home');
        return '/home';
      }
      print('[Router] No redirect needed');
      return null;
    },
    routes: [
      // Public routes first
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup/business',
        builder: (context, state) => const BusinessSignUpScreen(),
      ),
      GoRoute(
        path: '/signup/customer',
        builder: (context, state) => const CustomerSignUpScreen(),
      ),
      GoRoute(
        path: '/login/customer',
        builder: (context, state) => const CustomerLoginScreen(),
      ),
      GoRoute(
        path: '/business/setup',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          // Get access token from auth state (should be set after signup)
          final authState = ref.read(authStateProvider);
          return BusinessSetupScreen(
            accessToken: authState.accessToken ?? '',
            userEmail: extra?['email'],
            userPhone: extra?['phone'],
          );
        },
      ),
      GoRoute(
        path: '/book/:businessId',
        builder: (context, state) {
          final businessId = state.pathParameters['businessId'] ?? '';
          return CustomerBookingScreen(businessId: businessId);
        },
      ),
      GoRoute(
        path: '/subscription/success',
        builder: (context, state) => const SubscriptionSuccessScreen(),
      ),
      // Protected routes
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      // Keep old routes for backwards compatibility
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/business-settings',
        builder: (context, state) => const BusinessSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/profile',
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/working-hours',
        builder: (context, state) => const WorkingHoursSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/exceptions',
        builder: (context, state) => const ExceptionsSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/deposits',
        builder: (context, state) => const DepositsSettingsScreen(),
      ),
      GoRoute(
        path: '/services',
        builder: (context, state) => const ServicesScreen(),
      ),
      GoRoute(
        path: '/employees',
        builder: (context, state) => const EmployeesScreen(),
      ),
      GoRoute(
        path: '/appointments',
        builder: (context, state) => const AppointmentsScreen(),
      ),
      GoRoute(
        path: '/subscription/plans',
        builder: (context, state) => const SubscriptionPlansScreen(),
      ),
    ],
  );

  // Listen to auth state changes and refresh router
  ref.listen<AuthState>(authStateProvider, (previous, next) {
    print(
      '[Router] Auth state changed - previous: ${previous?.isAuthenticated}, next: ${next.isAuthenticated}',
    );
    // When auth state changes, refresh the router
    router.refresh();
    print('[Router] Router refreshed after auth state change');
  });

  return router;
});

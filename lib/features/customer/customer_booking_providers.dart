import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/service_models.dart';
import '../../core/providers/api_providers.dart';
import '../services/services_providers.dart';
import '../employees/employees_providers.dart';

/// Provider for available services (public-facing, only active services)
final publicServicesProvider = FutureProvider.family<List<Service>, String>((
  ref,
  businessId,
) async {
  final services = await ref.watch(servicesProvider(businessId).future);
  return services.where((s) => s.active).toList();
});

/// Provider for available time slots for a given date and service
final availableTimeSlotsProvider = FutureProvider.family<List<TimeSlot>, AvailableTimeSlotsParams>((
  ref,
  params,
) async {
  final apiService = ref.watch(apiServiceProvider);
  
  print(
    '[BookingProvider] Fetching slots from API - Business: ${params.businessId}, Date: ${params.date}, Service: ${params.serviceId}',
  );

  try {
    // Use the backend endpoint to get available time slots
    final slotTimes = await apiService.getAvailableTimeSlots(
      businessId: params.businessId,
      serviceId: params.serviceId,
      date: params.date,
    );

    print('[BookingProvider] Received ${slotTimes.length} slots from API');

    // Get employees to assign slots (we'll use the first available employee for each slot)
    final employees = await ref.watch(
      employeesProvider(params.businessId).future,
    );
    final activeEmployees = employees.where((e) => e.active).toList();
    final employeesWithService = activeEmployees
        .where((e) => e.serviceIds.contains(params.serviceId))
        .toList();
    final availableEmployees = employeesWithService.isNotEmpty
        ? employeesWithService
        : activeEmployees;

    // Calculate end time based on service duration
    final durationMinutes = params.totalDurationMinutes;

    // Map the API response (array of time strings) to TimeSlot objects
    return slotTimes.map((startTime) {
      // Calculate end time
      final startParts = startTime.split(':');
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final startTotalMinutes = startHour * 60 + startMinute;
      final endTotalMinutes = startTotalMinutes + durationMinutes;
      final endHour = endTotalMinutes ~/ 60;
      final endMinute = endTotalMinutes % 60;
      final endTime = '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

      // Use first available employee (or empty if none)
      final employee = availableEmployees.isNotEmpty
          ? availableEmployees.first
          : null;

      return TimeSlot(
        startTime: startTime,
        endTime: endTime,
        employeeId: employee?.id ?? '',
        employeeName: employee?.name ?? '',
      );
    }).toList();
  } catch (e) {
    print('[BookingProvider] Error fetching slots from API: $e');
    // Fallback to empty list if API fails
    return [];
  }
});

/// Parameters for available time slots provider
class AvailableTimeSlotsParams {
  final String businessId;
  final String date; // Format: yyyy-MM-dd
  final String serviceId; // Used for employee filtering
  final int totalDurationMinutes; // Total duration of all selected services

  AvailableTimeSlotsParams({
    required this.businessId,
    required this.date,
    required this.serviceId,
    required this.totalDurationMinutes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailableTimeSlotsParams &&
          runtimeType == other.runtimeType &&
          businessId == other.businessId &&
          date == other.date &&
          serviceId == other.serviceId &&
          totalDurationMinutes == other.totalDurationMinutes;

  @override
  int get hashCode =>
      businessId.hashCode ^
      date.hashCode ^
      serviceId.hashCode ^
      totalDurationMinutes.hashCode;
}

/// Time slot model
class TimeSlot {
  final String startTime; // Format: HH:mm
  final String endTime; // Format: HH:mm
  final String employeeId;
  final String employeeName;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.employeeId,
    required this.employeeName,
  });
}

/// Provider for creating customer appointments (public-facing)
final customerAppointmentNotifierProvider =
    StateNotifierProvider<
      CustomerAppointmentNotifier,
      CustomerAppointmentState
    >((ref) {
      final apiService = ref.watch(apiServiceProvider);
      return CustomerAppointmentNotifier(apiService);
    });

class CustomerAppointmentState {
  final bool isLoading;
  final String? error;
  final bool success;

  CustomerAppointmentState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  CustomerAppointmentState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return CustomerAppointmentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
    );
  }
}

class CustomerAppointmentNotifier
    extends StateNotifier<CustomerAppointmentState> {
  final dynamic _apiService;

  CustomerAppointmentNotifier(this._apiService)
    : super(CustomerAppointmentState());

  Future<void> createCustomerAppointment(
    Map<String, dynamic> appointmentData, {
    bool useCustomerToken = false,
    bool useGuestMode = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      await _apiService.createAppointment(
        appointmentData,
        useCustomerToken: useCustomerToken,
        useGuestMode: useGuestMode,
      );
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMessage);
      rethrow;
    }
  }

  void reset() {
    state = CustomerAppointmentState();
  }
}

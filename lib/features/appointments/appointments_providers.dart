import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/appointment_models.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/api_providers.dart';

final appointmentsProvider = FutureProvider.family<List<Appointment>, String>((
  ref,
  businessId,
) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getUpcomingAppointments(businessId);
});

final appointmentsNotifierProvider =
    StateNotifierProvider<AppointmentsNotifier, AppointmentsState>((ref) {
      final apiService = ref.watch(apiServiceProvider);
      return AppointmentsNotifier(apiService);
    });

class AppointmentsState {
  final List<Appointment> appointments;
  final bool isLoading;
  final String? error;

  AppointmentsState({
    this.appointments = const [],
    this.isLoading = false,
    this.error,
  });

  AppointmentsState copyWith({
    List<Appointment>? appointments,
    bool? isLoading,
    String? error,
  }) {
    return AppointmentsState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AppointmentsNotifier extends StateNotifier<AppointmentsState> {
  final ApiService _apiService;

  AppointmentsNotifier(this._apiService) : super(AppointmentsState());

  Future<void> loadAppointments(String businessId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final appointments = await _apiService.getUpcomingAppointments(
        businessId,
      );
      state = state.copyWith(appointments: appointments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createAppointment(
    Map<String, dynamic> appointmentData,
    String businessId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.createAppointment(appointmentData);
      await loadAppointments(businessId);
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMessage);
      rethrow; // Re-throw so the UI can handle it
    }
  }

  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatusUpdate update,
    String businessId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.updateAppointmentStatus(appointmentId, update);
      await loadAppointments(businessId);
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMessage);
      rethrow; // Re-throw so the UI can handle it
    }
  }

  Future<void> updateAppointment(
    String appointmentId,
    Map<String, dynamic> updates,
    String businessId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.updateAppointment(appointmentId, updates);
      await loadAppointments(businessId);
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMessage);
      rethrow;
    }
  }

  Future<void> rescheduleAppointment(
    String appointmentId,
    RescheduleAppointmentRequest request,
    String businessId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.rescheduleAppointment(appointmentId, request);
      await loadAppointments(businessId);
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMessage);
      rethrow; // Re-throw so the UI can handle it
    }
  }
}

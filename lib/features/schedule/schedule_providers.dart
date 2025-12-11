import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/schedule_models.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/api_providers.dart';

final schedulesProvider = FutureProvider.family<List<Schedule>, String>((ref, businessId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getSchedules(businessId);
});

final scheduleNotifierProvider = StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ScheduleNotifier(apiService);
});

class ScheduleState {
  final List<Schedule> schedules;
  final bool isLoading;
  final String? error;

  ScheduleState({
    this.schedules = const [],
    this.isLoading = false,
    this.error,
  });

  ScheduleState copyWith({
    List<Schedule>? schedules,
    bool? isLoading,
    String? error,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final ApiService _apiService;

  ScheduleNotifier(this._apiService) : super(ScheduleState());

  Future<void> loadSchedules(String businessId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final schedules = await _apiService.getSchedules(businessId);
      state = state.copyWith(schedules: schedules, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createSchedule(String businessId, Schedule schedule) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.createSchedule(businessId, schedule);
      await loadSchedules(businessId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateSchedule(String scheduleId, Map<String, dynamic> updates) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.updateSchedule(scheduleId, updates);
      // Reload schedules if needed
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final exceptionsProvider = FutureProvider.family<List<ScheduleException>, String>((ref, businessId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getExceptions(businessId);
});

final exceptionsNotifierProvider = StateNotifierProvider<ExceptionsNotifier, ExceptionsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ExceptionsNotifier(apiService);
});

class ExceptionsState {
  final List<ScheduleException> exceptions;
  final bool isLoading;
  final String? error;

  ExceptionsState({
    this.exceptions = const [],
    this.isLoading = false,
    this.error,
  });

  ExceptionsState copyWith({
    List<ScheduleException>? exceptions,
    bool? isLoading,
    String? error,
  }) {
    return ExceptionsState(
      exceptions: exceptions ?? this.exceptions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ExceptionsNotifier extends StateNotifier<ExceptionsState> {
  final ApiService _apiService;

  ExceptionsNotifier(this._apiService) : super(ExceptionsState());

  Future<void> loadExceptions(String businessId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final exceptions = await _apiService.getExceptions(businessId);
      state = state.copyWith(exceptions: exceptions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createException(String businessId, ScheduleException exception) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.createException(businessId, exception);
      await loadExceptions(businessId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteException(String exceptionId, String businessId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.deleteException(exceptionId);
      await loadExceptions(businessId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/employee_models.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/api_providers.dart';

final employeesProvider = FutureProvider.family<List<Employee>, String>((ref, businessId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getEmployees(businessId);
});

final employeesNotifierProvider = StateNotifierProvider<EmployeesNotifier, EmployeesState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return EmployeesNotifier(apiService);
});

class EmployeesState {
  final List<Employee> employees;
  final bool isLoading;
  final String? error;

  EmployeesState({
    this.employees = const [],
    this.isLoading = false,
    this.error,
  });

  EmployeesState copyWith({
    List<Employee>? employees,
    bool? isLoading,
    String? error,
  }) {
    return EmployeesState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EmployeesNotifier extends StateNotifier<EmployeesState> {
  final ApiService _apiService;

  EmployeesNotifier(this._apiService) : super(EmployeesState());

  Future<void> loadEmployees(String businessId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final employees = await _apiService.getEmployees(businessId);
      state = state.copyWith(employees: employees, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createEmployee(String businessId, Employee employee) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.createEmployee(businessId, employee);
      await loadEmployees(businessId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateEmployee(String employeeId, Map<String, dynamic> updates, String businessId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.updateEmployee(employeeId, updates);
      await loadEmployees(businessId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> assignService(String employeeId, String serviceId, String businessId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.assignServiceToEmployee(employeeId, serviceId);
      await loadEmployees(businessId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> unassignService(String employeeId, String serviceId, String businessId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.unassignServiceFromEmployee(employeeId, serviceId);
      await loadEmployees(businessId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}


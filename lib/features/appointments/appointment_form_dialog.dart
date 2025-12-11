import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../employees/employees_providers.dart';
import '../services/services_providers.dart';
import 'appointments_providers.dart';
import '../../core/models/customer_models.dart';
import '../../core/models/employee_models.dart';
import '../../core/models/appointment_models.dart';
import '../../core/providers/api_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class AppointmentFormDialog extends ConsumerStatefulWidget {
  final String businessId;
  final Appointment? appointment;
  final DateTime? initialDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;

  const AppointmentFormDialog({
    super.key,
    required this.businessId,
    this.appointment,
    this.initialDate,
    this.initialStartTime,
    this.initialEndTime,
  });

  @override
  ConsumerState<AppointmentFormDialog> createState() =>
      _AppointmentFormDialogState();
}

class _AppointmentFormDialogState extends ConsumerState<AppointmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  Set<String> _selectedServiceIds = {};
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(
      text: widget.appointment?.customer?.name ?? '',
    );
    _customerPhoneController = TextEditingController(
      text: widget.appointment?.customer?.phone ?? '',
    );

    // Initialize with appointment data if editing
    if (widget.appointment != null) {
      _selectedServiceIds = {widget.appointment!.serviceId};
      try {
        _selectedDate = DateFormat(
          'yyyy-MM-dd',
        ).parse(widget.appointment!.date);
      } catch (e) {
        _selectedDate = null;
      }
      try {
        final timeParts = widget.appointment!.startTime.split(':');
        if (timeParts.length == 2) {
          _selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        }
      } catch (e) {
        _selectedTime = null;
      }
    } else {
      // Initialize with provided initial values for new appointments
      if (widget.initialDate != null) {
        _selectedDate = widget.initialDate;
      }
      if (widget.initialStartTime != null) {
        _selectedTime = widget.initialStartTime;
      }
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _saveAppointment() async {
    if (_formKey.currentState!.validate() &&
        _selectedServiceIds.isNotEmpty &&
        _selectedDate != null &&
        _selectedTime != null) {
      try {
        // If editing, update the appointment
        if (widget.appointment != null) {
          final serviceId = _selectedServiceIds.first;

          // Get employees to find who can perform the service
          final employees = await ref.read(
            employeesProvider(widget.businessId).future,
          );
          final activeEmployees = employees.where((e) => e.active).toList();

          final availableEmployee = activeEmployees.firstWhere(
            (e) => e.serviceIds.contains(serviceId),
            orElse: () => widget.appointment!.employeeId.isNotEmpty
                ? activeEmployees.firstWhere(
                    (e) => e.id == widget.appointment!.employeeId,
                    orElse: () => activeEmployees.isNotEmpty
                        ? activeEmployees.first
                        : Employee(
                            id: '',
                            name: '',
                            active: false,
                            serviceIds: [],
                          ),
                  )
                : activeEmployees.isNotEmpty
                ? activeEmployees.first
                : Employee(id: '', name: '', active: false, serviceIds: []),
          );

          final updates = {
            'serviceId': serviceId,
            'employeeId': availableEmployee.id,
            'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
            'startTime':
                '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
          };

          await ref
              .read(appointmentsNotifierProvider.notifier)
              .updateAppointment(
                widget.appointment!.id,
                updates,
                widget.businessId,
              );

          // Refresh appointments
          ref.invalidate(appointmentsProvider(widget.businessId));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Appointment updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
          return;
        }

        // Create or get customer
        final customer = Customer(
          id: '',
          name: _customerNameController.text.trim(),
          phone: _customerPhoneController.text.trim(),
        );

        final customerId = await _createOrGetCustomer(customer);

        // Get employees to find who can perform each service
        final employees = await ref.read(
          employeesProvider(widget.businessId).future,
        );
        final activeEmployees = employees.where((e) => e.active).toList();

        int successCount = 0;
        int errorCount = 0;
        String? lastError;

        // Create an appointment for each selected service
        for (final serviceId in _selectedServiceIds) {
          // Find an employee who can perform this service
          final availableEmployee = activeEmployees.firstWhere(
            (e) => e.serviceIds.contains(serviceId),
            orElse: () => activeEmployees.isNotEmpty
                ? activeEmployees.first
                : Employee(id: '', name: '', active: false, serviceIds: []),
          );

          if (availableEmployee.id.isEmpty) {
            errorCount++;
            lastError = 'No hay empleados disponibles para el servicio';
            continue;
          }

          final appointmentData = {
            'businessId': widget.businessId,
            'employeeId': availableEmployee.id,
            'customerId': customerId,
            'serviceId': serviceId,
            'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
            'startTime':
                '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
          };

          try {
            await ref
                .read(appointmentsNotifierProvider.notifier)
                .createAppointment(appointmentData, widget.businessId);
            successCount++;
          } catch (e) {
            errorCount++;
            lastError = e.toString().replaceAll('Exception: ', '');
          }
        }

        // Refresh appointments
        ref.invalidate(appointmentsProvider(widget.businessId));

        if (mounted) {
          final l10n = context.l10n;
          if (errorCount == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.confirmed),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          } else if (successCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${l10n.confirmed}: $successCount. ${l10n.error}: $errorCount - $lastError',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n.errorCreatingAppointments}: $lastError'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          final errorMessage = e.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pleaseSelectAtLeastOneService),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _createOrGetCustomer(Customer customer) async {
    // Create customer - API auto-creates if phone exists
    final apiService = ref.read(apiServiceProvider);
    final createdCustomer = await apiService.createCustomer(customer);
    return createdCustomer.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final servicesAsync = ref.watch(servicesProvider(widget.businessId));

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.cardBackground,
        appBar: AppBar(
          title: Text(
            widget.appointment != null
                ? 'Edit Appointment'
                : l10n.newAppointment,
            style: AppTheme.textStyleH2,
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: Row(
            children: [
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                flex: 2,
                child: AppTheme.primaryButton(
                  text: l10n.save,
                  onPressed: _saveAppointment,
                ),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.customer, style: AppTheme.textStyleH3),
                  const SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: _customerNameController,
                    decoration: InputDecoration(
                      labelText: l10n.customerName,
                      filled: true,
                      fillColor: AppTheme.indigoMain.withOpacity(0.04),
                    ),
                    style: AppTheme.textStyleBody,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterCustomerName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: _customerPhoneController,
                    decoration: InputDecoration(
                      labelText: l10n.phone,
                      filled: true,
                      fillColor: AppTheme.indigoMain.withOpacity(0.04),
                    ),
                    keyboardType: TextInputType.phone,
                    style: AppTheme.textStyleBody,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterPhone;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingLG),
                  Text(l10n.services, style: AppTheme.textStyleH3),
                  const SizedBox(height: AppTheme.spacingMD),
                  servicesAsync.when(
                    data: (services) {
                      final activeServices = services
                          .where((s) => s.active)
                          .toList();

                      if (activeServices.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingMD),
                          child: Text(
                            l10n.noServicesAvailable,
                            style: AppTheme.textStyleBodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      }

                      return Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: activeServices.map((service) {
                              final isSelected = _selectedServiceIds.contains(
                                service.id,
                              );

                              return CheckboxListTile(
                                title: Text(
                                  service.name,
                                  style: AppTheme.textStyleBody,
                                ),
                                subtitle: Text(
                                  '${service.durationMinutes} min • \$${service.price.toStringAsFixed(0)}',
                                  style: AppTheme.textStyleCaption,
                                ),
                                value: isSelected,
                                activeColor: AppTheme.indigoMain,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedServiceIds.add(service.id);
                                    } else {
                                      _selectedServiceIds.remove(service.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacingMD),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMD),
                      child: Text(
                        '${l10n.errorLoadingServices}: $error',
                        style: AppTheme.textStyleBodySmall.copyWith(
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ),
                  if (_selectedServiceIds.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingSM),
                    Text(
                      l10n.serviceSelected(_selectedServiceIds.length),
                      style: AppTheme.textStyleCaption.copyWith(
                        color: AppTheme.indigoMain,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingLG),
                  Text(
                    '${l10n.date} y ${l10n.time}',
                    style: AppTheme.textStyleH3,
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  AppTheme.card(
                    onTap: _selectDate,
                    padding: const EdgeInsets.all(AppTheme.spacingMD),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingSM),
                          decoration: BoxDecoration(
                            color: AppTheme.indigoMain.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            color: AppTheme.indigoMain,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.date, style: AppTheme.textStyleCaption),
                              const SizedBox(height: AppTheme.spacingXS),
                              Text(
                                _selectedDate != null
                                    ? DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_selectedDate!)
                                    : l10n.selectDatePlaceholder,
                                style: AppTheme.textStyleBody.copyWith(
                                  color: _selectedDate != null
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_outlined,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  AppTheme.card(
                    onTap: _selectTime,
                    padding: const EdgeInsets.all(AppTheme.spacingMD),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingSM),
                          decoration: BoxDecoration(
                            color: AppTheme.indigoMain.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                          child: const Icon(
                            Icons.access_time_outlined,
                            color: AppTheme.indigoMain,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.time, style: AppTheme.textStyleCaption),
                              const SizedBox(height: AppTheme.spacingXS),
                              Text(
                                _selectedTime != null
                                    ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                    : l10n.selectTimePlaceholder,
                                style: AppTheme.textStyleBody.copyWith(
                                  color: _selectedTime != null
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_outlined,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLG),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../employees/employees_providers.dart';
import '../services/services_providers.dart';
import '../schedule/schedule_providers.dart';
import '../customer/customer_booking_providers.dart';
import 'appointments_providers.dart';
import '../../core/models/appointment_models.dart';
import '../../core/models/schedule_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class RescheduleAppointmentDialog extends ConsumerStatefulWidget {
  final Appointment appointment;
  final String businessId;

  const RescheduleAppointmentDialog({
    super.key,
    required this.appointment,
    required this.businessId,
  });

  @override
  ConsumerState<RescheduleAppointmentDialog> createState() =>
      _RescheduleAppointmentDialogState();
}

class _RescheduleAppointmentDialogState
    extends ConsumerState<RescheduleAppointmentDialog> {
  DateTime? _selectedDate;
  TimeSlot? _selectedTimeSlot;
  Set<String> _selectedServiceIds = {};
  String? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    // Initialize with current appointment values
    _selectedServiceIds = {widget.appointment.serviceId};
    _selectedEmployeeId = widget.appointment.employeeId;
    try {
      _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.appointment.date);
    } catch (e) {
      _selectedDate = null;
    }
    try {
      final timeParts = widget.appointment.startTime.split(':');
      if (timeParts.length == 2) {
        _selectedTimeSlot = TimeSlot(
          startTime: widget.appointment.startTime,
          endTime: widget.appointment.endTime,
          employeeId: widget.appointment.employeeId,
          employeeName: widget.appointment.employee?.name ?? '',
        );
      }
    } catch (e) {
      _selectedTimeSlot = null;
    }
  }

  Future<void> _selectDate() async {
    // Get schedules and exceptions
    List<Schedule> schedules = [];
    List<ScheduleException> exceptions = [];

    await ref
        .read(schedulesProvider(widget.businessId).future)
        .then((value) {
          schedules = value;
        })
        .catchError((e) {
          schedules = [];
        });

    await ref
        .read(exceptionsProvider(widget.businessId).future)
        .then((value) {
          exceptions = value;
        })
        .catchError((e) {
          exceptions = [];
        });

    final exceptionDates = exceptions.map((e) => e.date).toSet();

    // Calculate available dates
    final now = DateTime.now();
    final minBookingTime = now.add(const Duration(minutes: 30));
    final firstDate = DateTime(now.year, now.month, now.day);
    final canBookToday =
        minBookingTime.day == now.day &&
        minBookingTime.month == now.month &&
        minBookingTime.year == now.year;
    final actualFirstDate = canBookToday
        ? firstDate
        : firstDate.add(const Duration(days: 1));

    List<DateTime> availableDates = [];
    DateTime currentDate = actualFirstDate;
    int attempts = 0;

    while (availableDates.length < 60 && attempts < 120) {
      if (_isDateAvailable(currentDate, schedules, exceptionDates, now)) {
        availableDates.add(currentDate);
      }
      currentDate = currentDate.add(const Duration(days: 1));
      attempts++;
    }

    if (availableDates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No hay fechas disponibles'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    // Show custom date picker with only available dates
    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.selectDate),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: availableDates.length,
            itemBuilder: (context, index) {
              final date = availableDates[index];
              final isSelected =
                  _selectedDate != null &&
                  _selectedDate!.year == date.year &&
                  _selectedDate!.month == date.month &&
                  _selectedDate!.day == date.day;
              final isToday =
                  date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;

              return ListTile(
                title: Text(
                  DateFormat('EEEE, MMMM d', 'es').format(date),
                  style: AppTheme.textStyleBody.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                subtitle: isToday ? Text('Hoy') : null,
                selected: isSelected,
                onTap: () => Navigator.pop(context, date),
                selectedTileColor: AppTheme.indigoMain.withOpacity(0.1),
              );
            },
          ),
        ),
      ),
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
        _selectedTimeSlot = null; // Reset time when date changes
      });
    }
  }

  bool _isDateAvailable(
    DateTime date,
    List<Schedule> schedules,
    Set<String> exceptionDates,
    DateTime now,
  ) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(now.year, now.month, now.day);
    if (dateOnly.isBefore(todayOnly)) {
      return false;
    }
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    if (exceptionDates.contains(dateStr)) {
      return false;
    }
    final dayOfWeek = date.weekday == 7 ? 0 : date.weekday;
    final daySchedule = schedules.firstWhere(
      (s) => s.dayOfWeek == dayOfWeek,
      orElse: () => Schedule(id: '', dayOfWeek: dayOfWeek, isClosed: true),
    );
    if (daySchedule.isClosed ||
        daySchedule.startTime == null ||
        daySchedule.endTime == null) {
      return false;
    }
    return true;
  }

  int _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return hour * 60 + minute;
  }

  String _formatTime12Hour(String time24h) {
    final parts = time24h.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  Map<String, List<TimeSlot>> _groupSlotsByTimeOfDay(List<TimeSlot> slots) {
    final Map<String, List<TimeSlot>> grouped = {
      'morning': [],
      'afternoon': [],
      'evening': [],
    };

    for (final slot in slots) {
      final hour = int.parse(slot.startTime.split(':')[0]);
      if (hour >= 6 && hour < 12) {
        grouped['morning']!.add(slot);
      } else if (hour >= 12 && hour < 18) {
        grouped['afternoon']!.add(slot);
      } else if (hour >= 18 || hour < 6) {
        grouped['evening']!.add(slot);
      }
    }

    return grouped;
  }

  Widget _buildTimeSection(String title, List<TimeSlot> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.textStyleBody.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Wrap(
          spacing: AppTheme.spacingSM,
          runSpacing: AppTheme.spacingSM,
          children: slots.map((slot) {
            final isSelected = _selectedTimeSlot?.startTime == slot.startTime;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedTimeSlot = slot;
                  // Auto-select employee if available
                  if (slot.employeeId.isNotEmpty) {
                    _selectedEmployeeId = slot.employeeId;
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMD,
                  vertical: AppTheme.spacingSM,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.indigoMain
                      : AppTheme.backgroundMain,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.indigoMain
                        : AppTheme.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  _formatTime12Hour(slot.startTime),
                  style: AppTheme.textStyleBodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSelection() {
    if (_selectedServiceIds.isEmpty || _selectedDate == null) {
      return const SizedBox.shrink();
    }

    final servicesAsync = ref.watch(servicesProvider(widget.businessId));

    return servicesAsync.when(
      data: (services) {
        final selectedServices = services
            .where((s) => _selectedServiceIds.contains(s.id))
            .toList();

        if (selectedServices.isEmpty) {
          return const SizedBox.shrink();
        }

        final totalDurationMinutes = selectedServices.fold<int>(
          0,
          (sum, service) => sum + service.durationMinutes,
        );

        final firstService = selectedServices.first;
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        final params = AvailableTimeSlotsParams(
          businessId: widget.businessId,
          date: dateStr,
          serviceId: firstService.id,
          totalDurationMinutes: totalDurationMinutes,
        );

        final timeSlotsAsync = ref.watch(availableTimeSlotsProvider(params));

        return timeSlotsAsync.when(
          data: (slots) {
            // Filter out past times if date is today
            final now = DateTime.now();
            final isToday =
                _selectedDate!.year == now.year &&
                _selectedDate!.month == now.month &&
                _selectedDate!.day == now.day;

            final filteredSlots = isToday
                ? slots.where((slot) {
                    final slotTime = _parseTime(slot.startTime);
                    final currentTime = now.hour * 60 + now.minute;
                    // Add 30 minutes buffer
                    return slotTime >= (currentTime + 30);
                  }).toList()
                : slots;

            if (filteredSlots.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppTheme.spacingLG),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.selectTime,
                      style: AppTheme.textStyleH2.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMD),
                    Text(
                      context.l10n.noTimeSlotsAvailable,
                      style: AppTheme.textStyleBody.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            final groupedSlots = _groupSlotsByTimeOfDay(filteredSlots);

            return Container(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.selectTime,
                    style: AppTheme.textStyleH2.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLG),
                  // Morning section
                  if (groupedSlots['morning'] != null &&
                      groupedSlots['morning']!.isNotEmpty) ...[
                    _buildTimeSection('Mañana', groupedSlots['morning']!),
                    const SizedBox(height: AppTheme.spacingMD),
                  ],
                  // Afternoon section
                  if (groupedSlots['afternoon'] != null &&
                      groupedSlots['afternoon']!.isNotEmpty) ...[
                    _buildTimeSection('Tarde', groupedSlots['afternoon']!),
                    const SizedBox(height: AppTheme.spacingMD),
                  ],
                  // Evening section
                  if (groupedSlots['evening'] != null &&
                      groupedSlots['evening']!.isNotEmpty) ...[
                    _buildTimeSection('Noche', groupedSlots['evening']!),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text(context.l10n.errorLoadingTimeSlots),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _rescheduleAppointment() async {
    final l10n = context.l10n;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectDate),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectTime),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectService),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectEmployee),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    try {
      // Use the first selected service for rescheduling
      // Note: The API currently only supports rescheduling with one service
      final serviceId = _selectedServiceIds.first;

      // Note: The API currently only supports rescheduling with one service
      // If multiple services are selected, we use the first one
      // The user can see which service will be used from the selection

      final request = RescheduleAppointmentRequest(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        startTime: _selectedTimeSlot!.startTime,
        employeeId: _selectedTimeSlot!.employeeId.isNotEmpty
            ? _selectedTimeSlot!.employeeId
            : _selectedEmployeeId!,
        serviceId: serviceId,
      );

      await ref
          .read(appointmentsNotifierProvider.notifier)
          .rescheduleAppointment(
            widget.appointment.id,
            request,
            widget.businessId,
          );

      if (mounted) {
        ref.invalidate(appointmentsProvider(widget.businessId));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.appointmentRescheduledSuccessfully),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.errorReschedulingAppointment}: $errorMessage',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final servicesAsync = ref.watch(servicesProvider(widget.businessId));
    final employeesAsync = ref.watch(employeesProvider(widget.businessId));

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.cardBackground,
        appBar: AppBar(
          title: Text(l10n.rescheduleAppointment, style: AppTheme.textStyleH2),
          centerTitle: true,
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingMD,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                  ),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                flex: 2,
                child: AppTheme.primaryButton(
                  text: l10n.reschedule,
                  onPressed: _rescheduleAppointment,
                ),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Selection
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
                                    // Reset employee selection if no services selected
                                    if (_selectedServiceIds.isEmpty) {
                                      _selectedEmployeeId = null;
                                    }
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
                // Employee Selection
                Text(l10n.employees, style: AppTheme.textStyleH3),
                const SizedBox(height: AppTheme.spacingMD),
                employeesAsync.when(
                  data: (employees) {
                    // Filter employees by selected services
                    // Show employees who can perform at least one of the selected services
                    final availableEmployees = _selectedServiceIds.isNotEmpty
                        ? employees
                              .where(
                                (e) =>
                                    e.active &&
                                    _selectedServiceIds.any(
                                      (serviceId) =>
                                          e.serviceIds.contains(serviceId),
                                    ),
                              )
                              .toList()
                        : employees.where((e) => e.active).toList();

                    if (availableEmployees.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMD),
                        child: Text(
                          _selectedServiceIds.isEmpty
                              ? l10n.pleaseSelectService
                              : l10n.errorNoEmployeeAvailable,
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
                          children: availableEmployees.map((employee) {
                            return RadioListTile<String>(
                              title: Text(
                                employee.name,
                                style: AppTheme.textStyleBody,
                              ),
                              value: employee.id,
                              groupValue: _selectedEmployeeId,
                              activeColor: AppTheme.indigoMain,
                              onChanged: (value) {
                                setState(() {
                                  _selectedEmployeeId = value;
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
                      'Error loading employees: $error',
                      style: AppTheme.textStyleBodySmall.copyWith(
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLG),
                // Date Selection
                Text(l10n.date, style: AppTheme.textStyleH3),
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
                      Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLG),
                // Time Selection (only shows when date and services are selected)
                _buildTimeSelection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

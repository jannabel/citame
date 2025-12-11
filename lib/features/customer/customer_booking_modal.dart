import 'dart:io' if (dart.library.html) '../customer/file_stub.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart' show isSameDay;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/models/service_models.dart';
import '../../core/theme/app_theme.dart';
import 'customer_booking_providers.dart';
import '../../core/models/customer_models.dart';
import '../schedule/schedule_providers.dart';
import '../../core/models/schedule_models.dart';
import '../../core/models/business_models.dart';
import '../employees/employees_providers.dart';
import '../../core/models/employee_models.dart';
import 'customer_auth_providers.dart';
import 'package:go_router/go_router.dart';

class BookingModalFullScreen extends ConsumerStatefulWidget {
  final Business business;
  final List<Service> services;
  final List<Schedule> schedules;
  final String businessId;
  final dynamic l10n;

  const BookingModalFullScreen({
    super.key,
    required this.business,
    required this.services,
    required this.schedules,
    required this.businessId,
    required this.l10n,
  });

  @override
  ConsumerState<BookingModalFullScreen> createState() =>
      _BookingModalFullScreenState();
}

class _BookingModalFullScreenState
    extends ConsumerState<BookingModalFullScreen> {
  int _currentStepIndex = 0; // Explicit step index
  final List<Service> _selectedServices = [];
  DateTime? _selectedDate;
  TimeSlot? _selectedTimeSlot;
  Customer? _customer;
  String? _selectedEmployeeId;
  final TextEditingController _serviceSearchController =
      TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final _customerFormKey = GlobalKey<FormState>();
  bool _showTicket = false;
  List<Map<String, dynamic>>? _createdAppointments;
  bool _isBookingInProgress = false; // Prevent duplicate booking requests

  @override
  void initState() {
    super.initState();
    _serviceSearchController.addListener(() => setState(() {}));
    _customerNameController.addListener(_updateCustomer);
    _customerPhoneController.addListener(_updateCustomer);
  }

  @override
  void dispose() {
    _serviceSearchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  void _updateCustomer() {
    final name = _customerNameController.text.trim();
    final phone = _customerPhoneController.text.trim();
    if (name.isNotEmpty && phone.isNotEmpty) {
      setState(() {
        _customer = Customer(id: _customer?.id ?? '', name: name, phone: phone);
      });
    } else {
      setState(() {
        _customer = null;
      });
    }
  }

  /// Converts technical error messages to user-friendly messages in Spanish
  String _getUserFriendlyError(String errorMessage) {
    final errorLower = errorMessage.toLowerCase();

    if (errorLower.contains('customer already has an appointment') ||
        errorLower.contains('already has an appointment at this time')) {
      return widget.l10n.errorAppointmentConflict;
    }

    if (errorLower.contains('no employee available') ||
        errorLower.contains('employee available')) {
      return widget.l10n.errorNoEmployeeAvailable;
    }

    if (errorLower.contains('no longer available') ||
        errorLower.contains('slot') && errorLower.contains('available')) {
      return widget.l10n.errorSlotNoLongerAvailable;
    }

    // Default to generic error message
    return widget.l10n.errorGenericBooking;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: AppTheme.backgroundMain,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppTheme.spacingSM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLG,
              vertical: AppTheme.spacingMD,
            ),
            child: Row(
              children: [
                Text(
                  widget.l10n.bookAppointment,
                  style: AppTheme.textStyleH2.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          // Content
          Expanded(child: _buildBookingFlow()),
          // Bottom Navbar
          _buildBottomNavbar(),
        ],
      ),
    );
  }

  Widget _buildBookingFlow() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step Indicator
          _buildStepIndicator(),
          const SizedBox(height: AppTheme.spacingXL),
          // Show only current step
          if (_showTicket) ...[
            _buildTicket(),
          ] else if (_currentStepIndex == 0) ...[
            _buildServiceSelection(),
          ] else if (_currentStepIndex == 1) ...[
            _buildDateAndTimeSelection(),
          ] else if (_currentStepIndex == 2) ...[
            _buildCustomerInfo(),
          ] else if (_currentStepIndex == 3) ...[
            _buildConfirmationSummary(),
          ],
          const SizedBox(height: 100), // Space for bottom navbar
        ],
      ),
    );
  }

  Widget _buildBottomNavbar() {
    if (_showTicket) {
      return const SizedBox.shrink();
    }

    final customerAuthState = ref.watch(customerAuthStateProvider);
    final isLoggedIn = customerAuthState.isAuthenticated;

    final canContinue =
        (_currentStepIndex == 0 && _selectedServices.isNotEmpty) ||
        (_currentStepIndex == 1 &&
            _selectedDate != null &&
            _selectedTimeSlot != null) ||
        (_currentStepIndex == 2 &&
            (isLoggedIn ||
                (_customer != null &&
                    _customerFormKey.currentState?.validate() == true))) ||
        (_currentStepIndex == 3);

    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.spacingLG,
        right: AppTheme.spacingLG,
        top: AppTheme.spacingMD,
        bottom: MediaQuery.of(context).padding.bottom + AppTheme.spacingMD,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStepIndex > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStepIndex--;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingMD + 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(widget.l10n.back),
                ),
              ),
            if (_currentStepIndex > 0)
              const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              flex: _currentStepIndex > 0 ? 2 : 1,
              child: _currentStepIndex == 3
                  ? Consumer(
                      builder: (context, ref, child) {
                        final appointmentState = ref.watch(
                          customerAppointmentNotifierProvider,
                        );
                        return _buildConfirmButton(appointmentState);
                      },
                    )
                  : ElevatedButton(
                      onPressed: canContinue
                          ? () {
                              if (_currentStepIndex == 2) {
                                // Validate form before continuing
                                if (_customerFormKey.currentState?.validate() ??
                                    false) {
                                  setState(() {
                                    _updateCustomer();
                                    _currentStepIndex = 3;
                                  });
                                }
                              } else {
                                setState(() {
                                  if (_currentStepIndex < 3) {
                                    _currentStepIndex++;
                                  }
                                });
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.indigoMain,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingMD + 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: AppTheme.borderLight,
                      ),
                      child: Text(
                        'Continuar',
                        style: AppTheme.textStyleBody.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      {
        'label': 'Servicios',
        'completed': _selectedServices.isNotEmpty,
        'icon': Icons.spa,
      },
      {
        'label': 'Fecha y Hora',
        'completed': _selectedDate != null && _selectedTimeSlot != null,
        'icon': Icons.calendar_today,
      },
      {
        'label': 'Información',
        'completed': _customer != null,
        'icon': Icons.person,
      },
      {
        'label': 'Confirmar',
        'completed': _showTicket,
        'icon': Icons.check_circle,
      },
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingXL),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingLG,
      ),
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
      child: Row(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isActive = index == _currentStepIndex;
          final isCompleted = step['completed'] as bool;
          final isLast = index == steps.length - 1;
          final label = step['label'] as String;
          final icon = step['icon'] as IconData;
          final prevStepCompleted = index > 0
              ? (steps[index - 1]['completed'] as bool)
              : false;

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Step circle and connector line row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Step circle
                    Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppTheme.indigoMain
                                : isActive
                                ? AppTheme.indigoMain.withOpacity(0.1)
                                : AppTheme.backgroundMain,
                            border: Border.all(
                              color: isCompleted || isActive
                                  ? AppTheme.indigoMain
                                  : AppTheme.borderLight,
                              width: isActive ? 3 : 2,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppTheme.indigoMain.withOpacity(
                                        0.25,
                                      ),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isCompleted
                              ? const Icon(
                                  Icons.check_circle,
                                  size: 24,
                                  color: Colors.white,
                                )
                              : Icon(
                                  icon,
                                  size: 22,
                                  color: isActive
                                      ? AppTheme.indigoMain
                                      : AppTheme.textSecondary,
                                ),
                        ),
                        const SizedBox(height: AppTheme.spacingSM),
                        Text(
                          label,
                          style: AppTheme.textStyleBodySmall.copyWith(
                            fontWeight: isActive || isCompleted
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isCompleted
                                ? AppTheme.indigoMain
                                : isActive
                                ? AppTheme.indigoMain
                                : AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Connector line
                  ],
                ),

                // Step label
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDateAndTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date Selection
        _buildDateSelection(),
        // Time Selection (only if date is selected)
        if (_selectedDate != null) ...[
          const SizedBox(height: AppTheme.spacingXL),
          _buildTimeSelection(),
        ],
      ],
    );
  }

  Widget _buildServiceSelection() {
    final searchQuery = _serviceSearchController.text.toLowerCase();
    final filteredServices = searchQuery.isEmpty
        ? widget.services
        : widget.services.where((service) {
            return service.name.toLowerCase().contains(searchQuery) ||
                (service.description != null &&
                    service.description!.toLowerCase().contains(searchQuery));
          }).toList();

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
            widget.l10n.selectService,
            style: AppTheme.textStyleH2.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          // Search
          TextField(
            controller: _serviceSearchController,
            decoration: InputDecoration(
              hintText: 'Buscar servicios...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _serviceSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _serviceSearchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.backgroundMain,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          // Services List
          ...filteredServices.map((service) {
            final isSelected = _selectedServices.any((s) => s.id == service.id);
            return _buildServiceItem(service, isSelected);
          }),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Service service, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedServices.removeWhere((s) => s.id == service.id);
          } else {
            _selectedServices.add(service);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.indigoMain.withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: isSelected ? AppTheme.indigoMain : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.indigoMain : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.indigoMain
                      : AppTheme.borderLight,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: AppTheme.textStyleBody.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppTheme.indigoMain
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${service.durationMinutes} ${widget.l10n.minutes}',
                        style: AppTheme.textStyleBodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '\$${service.price.toStringAsFixed(2)}',
              style: AppTheme.textStyleH3.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.indigoMain,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    final schedulesAsync = ref.watch(schedulesProvider(widget.businessId));
    final exceptionsAsync = ref.watch(exceptionsProvider(widget.businessId));

    return schedulesAsync.when(
      data: (schedules) => exceptionsAsync.when(
        data: (exceptions) => _buildDateSelectorChips(schedules, exceptions),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildDateError(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildDateError(),
    );
  }

  Widget _buildDateSelectorChips(
    List<Schedule> schedules,
    List<ScheduleException> exceptions,
  ) {
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
    final exceptionDates = exceptions.map((e) => e.date).toSet();

    List<DateTime> availableDates = [];
    DateTime currentDate = actualFirstDate;
    int attempts = 0;

    while (availableDates.length < 14 && attempts < 60) {
      if (_isDateAvailable(currentDate, schedules, exceptionDates, now)) {
        availableDates.add(currentDate);
      }
      currentDate = currentDate.add(const Duration(days: 1));
      attempts++;
    }

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
            widget.l10n.selectDate,
            style: AppTheme.textStyleH2.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availableDates.length,
              itemBuilder: (context, index) {
                final date = availableDates[index];
                final isSelected =
                    _selectedDate != null && isSameDay(_selectedDate!, date);
                final isToday = isSameDay(date, now);

                return Padding(
                  padding: EdgeInsets.only(
                    right: index < availableDates.length - 1
                        ? AppTheme.spacingSM
                        : 0,
                  ),
                  child: _buildDateChip(date, isSelected, isToday),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(DateTime date, bool isSelected, bool isToday) {
    final dayName = DateFormat('EEE', 'es').format(date);
    final dayNumber = date.day;
    final monthName = DateFormat('MMM', 'es').format(date);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _selectedTimeSlot = null;
          _selectedEmployeeId = null;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.indigoMain
              : isToday
              ? AppTheme.indigoMain.withOpacity(0.1)
              : AppTheme.backgroundMain,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.indigoMain
                : isToday
                ? AppTheme.indigoMain.withOpacity(0.3)
                : AppTheme.borderLight.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName.toUpperCase(),
              style: AppTheme.textStyleCaption.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$dayNumber',
              style: AppTheme.textStyleH3.copyWith(
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontSize: 24,
              ),
            ),
            Text(
              monthName,
              style: AppTheme.textStyleCaption.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white.withOpacity(0.8)
                    : AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildDateError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.l10n.selectDate,
          style: AppTheme.textStyleH2.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppTheme.spacingMD),
        Text(widget.l10n.errorLoadingDates),
      ],
    );
  }

  Widget _buildTimeSelection() {
    if (_selectedServices.isEmpty || _selectedDate == null) {
      return const SizedBox.shrink();
    }

    final totalDurationMinutes = _selectedServices.fold<int>(
      0,
      (sum, service) => sum + service.durationMinutes,
    );

    final firstService = _selectedServices.first;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final params = AvailableTimeSlotsParams(
      businessId: widget.businessId,
      date: dateStr,
      serviceId: firstService.id,
      totalDurationMinutes: totalDurationMinutes,
    );

    // Use ref.watch to automatically update when appointments change
    // Also use ref.refresh to ensure fresh data when this widget becomes visible
    // Use key to force rebuild when appointments change
    final timeSlotsAsync = ref.watch(availableTimeSlotsProvider(params));

    return timeSlotsAsync.when(
      data: (slots) {
        // Filter out past times if date is today
        final now = DateTime.now();
        final isToday =
            _selectedDate != null &&
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
                  widget.l10n.selectTime,
                  style: AppTheme.textStyleH2.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD),
                Text(
                  widget.l10n.noTimeSlotsAvailable,
                  style: AppTheme.textStyleBody.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // Group slots by time of day
        final groupedSlots = _groupSlotsByTimeOfDay(filteredSlots);

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
                widget.l10n.selectTime,
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
      error: (_, __) => Text(widget.l10n.errorLoadingTimeSlots),
    );
  }

  int _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return hour * 60 + minute;
  }

  /// Formats minutes since midnight to HH:mm
  String _formatTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
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

  Widget _buildCustomerInfo() {
    final customerAuthState = ref.watch(customerAuthStateProvider);
    final isLoggedIn = customerAuthState.isAuthenticated;

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
      child: Form(
        key: _customerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tu información',
                  style: AppTheme.textStyleH2.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isLoggedIn)
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to customer login screen
                      context.push('/login/customer').then((result) {
                        if (result == true && mounted) {
                          // Refresh the UI to show logged in state
                          setState(() {});
                        }
                      });
                    },
                    icon: const Icon(Icons.login, size: 18),
                    label: const Text('Iniciar sesión'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.indigoMain,
                    ),
                  ),
              ],
            ),
            if (isLoggedIn) ...[
              const SizedBox(height: AppTheme.spacingMD),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                    const SizedBox(width: AppTheme.spacingSM),
                    Expanded(
                      child: Text(
                        'Sesión iniciada',
                        style: AppTheme.textStyleBodySmall.copyWith(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.read(customerAuthStateProvider.notifier).logout(),
                      child: const Text(
                        'Cerrar sesión',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingLG),
            // Name field (required for guests, optional for logged customers)
            TextFormField(
              controller: _customerNameController,
              enabled: !isLoggedIn, // Disable if logged in
              decoration: InputDecoration(
                labelText: widget.l10n.customerName,
                hintText: widget.l10n.enterCustomerName,
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: isLoggedIn
                    ? AppTheme.backgroundMain.withOpacity(0.5)
                    : AppTheme.backgroundMain,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.indigoMain, width: 2),
                ),
              ),
              validator: (value) {
                // Only validate if not logged in (guest mode)
                if (!isLoggedIn && (value == null || value.trim().isEmpty)) {
                  return widget.l10n.pleaseEnterCustomerName;
                }
                return null;
              },
              onChanged: (_) => _updateCustomer(),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            // Phone field (required for guests, optional for logged customers)
            TextFormField(
              controller: _customerPhoneController,
              enabled: !isLoggedIn, // Disable if logged in
              decoration: InputDecoration(
                labelText: widget.l10n.customerPhone,
                hintText: widget.l10n.enterCustomerPhone,
                prefixIcon: const Icon(Icons.phone_outlined),
                filled: true,
                fillColor: isLoggedIn
                    ? AppTheme.backgroundMain.withOpacity(0.5)
                    : AppTheme.backgroundMain,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.indigoMain, width: 2),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                // Only validate if not logged in (guest mode)
                if (!isLoggedIn && (value == null || value.trim().isEmpty)) {
                  return widget.l10n.pleaseEnterCustomerPhone;
                }
                return null;
              },
              onChanged: (_) => _updateCustomer(),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _bookAppointment() async {
    // Prevent duplicate requests
    if (_isBookingInProgress) {
      return;
    }

    final customerAuthState = ref.read(customerAuthStateProvider);
    final isLoggedIn = customerAuthState.isAuthenticated;

    if (_selectedServices.isEmpty ||
        _selectedDate == null ||
        _selectedTimeSlot == null) {
      return;
    }

    // For guest mode, customer info is required
    if (!isLoggedIn && _customer == null) {
      return;
    }

    // Set booking in progress flag
    setState(() {
      _isBookingInProgress = true;
    });

    int successCount = 0;
    int errorCount = 0;
    String? lastError;
    List<Map<String, dynamic>> createdAppointments = [];

    // Calculate sequential start times for each service
    int currentStartTimeMinutes = _parseTime(_selectedTimeSlot!.startTime);

    for (final service in _selectedServices) {
      final employeesAsync = await ref.read(
        employeesProvider(widget.businessId).future,
      );
      final activeEmployees = employeesAsync.where((e) => e.active).toList();

      final availableEmployee = activeEmployees.firstWhere(
        (e) => e.serviceIds.contains(service.id),
        orElse: () => activeEmployees.firstWhere(
          (e) => e.id == _selectedTimeSlot!.employeeId,
          orElse: () => activeEmployees.isNotEmpty
              ? activeEmployees.first
              : Employee(id: '', name: '', active: false, serviceIds: []),
        ),
      );

      if (availableEmployee.id.isEmpty) {
        errorCount++;
        lastError = widget.l10n.errorNoEmployeeAvailable;
        continue;
      }

      // Calculate start time for this service
      final serviceStartTime = _formatTime(currentStartTimeMinutes);

      // Build appointment data based on auth state
      Map<String, dynamic> appointmentData;

      if (isLoggedIn) {
        // Logged customer: use businessUserId (employeeId), customerName/Phone/Email optional
        appointmentData = {
          'businessId': widget.businessId,
          'businessUserId': availableEmployee.id,
          'serviceId': service.id,
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
          'startTime': serviceStartTime,
          // Optional fields for logged customers
          if (_customerNameController.text.trim().isNotEmpty)
            'customerName': _customerNameController.text.trim(),
          if (_customerPhoneController.text.trim().isNotEmpty)
            'customerPhone': _customerPhoneController.text.trim(),
        };
      } else {
        // Guest: customerName and customerPhone are required
        appointmentData = {
          'businessId': widget.businessId,
          'businessUserId': availableEmployee.id,
          'serviceId': service.id,
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
          'startTime': serviceStartTime,
          'customerName': _customer!.name, // Required for guests
          'customerPhone': _customer!.phone, // Required for guests
        };
      }

      try {
        await ref
            .read(customerAppointmentNotifierProvider.notifier)
            .createCustomerAppointment(
              appointmentData,
              useCustomerToken: isLoggedIn,
              useGuestMode: !isLoggedIn,
            );
        createdAppointments.add({
          'service': service,
          'employee': availableEmployee,
          'date': _selectedDate!,
          'time': serviceStartTime,
        });
        successCount++;

        // Update start time for next service (add duration of current service)
        currentStartTimeMinutes += service.durationMinutes;
      } catch (e) {
        errorCount++;
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        lastError = _getUserFriendlyError(errorMessage);
      }
    }

    // Invalidate time slots provider to refresh available slots from API
    if (successCount > 0) {
      // Invalidate time slots provider for the selected date
      // This will force a fresh API call to get updated slots
      if (_selectedDate != null && _selectedServices.isNotEmpty) {
        final totalDurationMinutes = _selectedServices.fold<int>(
          0,
          (sum, service) => sum + service.durationMinutes,
        );
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        final firstService = _selectedServices.first;
        final params = AvailableTimeSlotsParams(
          businessId: widget.businessId,
          date: dateStr,
          serviceId: firstService.id,
          totalDurationMinutes: totalDurationMinutes,
        );
        // Invalidate the specific time slots provider to force fresh API call
        ref.invalidate(availableTimeSlotsProvider(params));
      }
    }

    if (mounted) {
      if (errorCount == 0) {
        setState(() {
          _createdAppointments = createdAppointments;
          _showTicket = true;
          _currentStepIndex = 3;
          _isBookingInProgress = false;
        });
        ref.read(customerAppointmentNotifierProvider.notifier).reset();
      } else {
        setState(() {
          _isBookingInProgress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successCount > 0
                  ? widget.l10n.errorBookingSomeAppointments(successCount)
                  : '${widget.l10n.errorBookingAppointments}: $lastError',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } else {
      // Reset flag if widget is unmounted
      _isBookingInProgress = false;
    }
  }

  Widget _buildConfirmationSummary() {
    final totalAmount = _selectedServices.fold<double>(
      0,
      (sum, service) => sum + service.price,
    );

    final dateFormatter = DateFormat('d MMM yyyy', 'es');

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
          Row(
            children: [
              Icon(Icons.summarize, color: AppTheme.indigoMain, size: 28),
              const SizedBox(width: AppTheme.spacingMD),
              Text(
                'Resumen de tu cita',
                style: AppTheme.textStyleH2.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXL),
          // Business Info
          _buildSummarySection('Negocio', widget.business.name, Icons.business),
          const SizedBox(height: AppTheme.spacingLG),
          // Customer Info
          _buildSummarySection(
            'Cliente',
            '${_customer?.name ?? ""}\n${_customer?.phone ?? ""}',
            Icons.person,
          ),
          const SizedBox(height: AppTheme.spacingLG),
          // Date & Time
          _buildSummarySection(
            'Fecha y Hora',
            '${dateFormatter.format(_selectedDate!)}\n${_formatTime12Hour(_selectedTimeSlot!.startTime)}',
            Icons.calendar_today,
          ),
          const SizedBox(height: AppTheme.spacingLG),
          // Services
          Text(
            'Servicios',
            style: AppTheme.textStyleH3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          ..._selectedServices.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: AppTheme.textStyleBody.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${service.durationMinutes} ${widget.l10n.minutes}',
                          style: AppTheme.textStyleBodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${service.price.toStringAsFixed(2)}',
                    style: AppTheme.textStyleBody.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.indigoMain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: AppTheme.spacingXL),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Est.',
                style: AppTheme.textStyleH3.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: AppTheme.textStyleH2.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.indigoMain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String title, String content, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.textStyleBodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: AppTheme.textStyleBody.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(CustomerAppointmentState appointmentState) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (appointmentState.isLoading || _isBookingInProgress)
            ? null
            : _bookAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.indigoMain,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD + 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: (appointmentState.isLoading || _isBookingInProgress)
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Confirmar',
                    style: AppTheme.textStyleBody.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTicket() {
    if (_createdAppointments == null || _createdAppointments!.isEmpty) {
      return Center(child: Text(widget.l10n.noAppointmentInfo));
    }

    final dateFormatter = DateFormat('d MMM yyyy', 'es');
    final totalAmount = _selectedServices.fold<double>(
      0,
      (sum, service) => sum + service.price,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.success.withOpacity(0.1),
            ),
            child: Icon(Icons.check_circle, size: 50, color: AppTheme.success),
          ),
          const SizedBox(height: AppTheme.spacingLG),
          Text(
            '¡Cita confirmada!',
            style: AppTheme.textStyleH1.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            'Tu cita ha sido agendada exitosamente',
            style: AppTheme.textStyleBody.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXL),
          // Ticket Container
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXL),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.indigoMain.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.business.name,
                          style: AppTheme.textStyleH2.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Ticket de Cita',
                          style: AppTheme.textStyleBodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.confirmation_number,
                      size: 40,
                      color: AppTheme.indigoMain,
                    ),
                  ],
                ),
                const Divider(height: AppTheme.spacingXL),
                // Customer Info
                _buildTicketRow('Cliente', _customer?.name ?? ''),
                _buildTicketRow('Teléfono', _customer?.phone ?? ''),
                const SizedBox(height: AppTheme.spacingMD),
                // Date & Time
                _buildTicketRow('Fecha', dateFormatter.format(_selectedDate!)),
                _buildTicketRow(
                  'Hora',
                  _formatTime12Hour(_selectedTimeSlot!.startTime),
                ),
                const SizedBox(height: AppTheme.spacingMD),
                // Services
                Text(
                  'Servicios:',
                  style: AppTheme.textStyleBody.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                ..._selectedServices.map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingXS),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '• ${service.name}',
                            style: AppTheme.textStyleBodySmall,
                          ),
                        ),
                        Text(
                          '\$${service.price.toStringAsFixed(2)}',
                          style: AppTheme.textStyleBodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: AppTheme.spacingXL),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: AppTheme.textStyleH3.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '\$${totalAmount.toStringAsFixed(2)}',
                      style: AppTheme.textStyleH2.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.indigoMain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXL),
                // Download Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadTicket(),
                    icon: const Icon(Icons.download),
                    label: Text(widget.l10n.downloadTicket),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacingMD,
                      ),
                      side: BorderSide(color: AppTheme.indigoMain, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.indigoMain,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingMD + 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Cerrar',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.textStyleBodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Text(
              value,
              style: AppTheme.textStyleBody.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadTicket() async {
    if (_selectedServices.isEmpty ||
        _selectedDate == null ||
        _selectedTimeSlot == null ||
        _customer == null) {
      return;
    }

    try {
      final dateFormatter = DateFormat('d MMM yyyy', 'es');
      final totalAmount = _selectedServices.fold<double>(
        0,
        (sum, service) => sum + service.price,
      );

      // Build ticket text
      final ticketText = StringBuffer();
      ticketText.writeln('═══════════════════════════════════');
      ticketText.writeln('        TICKET DE CITA');
      ticketText.writeln('═══════════════════════════════════');
      ticketText.writeln('');
      ticketText.writeln('Negocio: ${widget.business.name}');
      ticketText.writeln('');
      ticketText.writeln('Cliente: ${_customer!.name}');
      ticketText.writeln('Teléfono: ${_customer!.phone}');
      ticketText.writeln('');
      ticketText.writeln('Fecha: ${dateFormatter.format(_selectedDate!)}');
      ticketText.writeln(
        'Hora: ${_formatTime12Hour(_selectedTimeSlot!.startTime)}',
      );
      ticketText.writeln('');
      ticketText.writeln('Servicios:');
      for (final service in _selectedServices) {
        ticketText.writeln(
          '  • ${service.name} - \$${service.price.toStringAsFixed(2)}',
        );
      }
      ticketText.writeln('');
      ticketText.writeln('Total: \$${totalAmount.toStringAsFixed(2)}');
      ticketText.writeln('');
      ticketText.writeln('═══════════════════════════════════');
      ticketText.writeln(
        'Fecha de emisión: ${DateFormat('d MMM yyyy, HH:mm').format(DateTime.now())}',
      );
      ticketText.writeln('═══════════════════════════════════');

      // Share the ticket
      if (kIsWeb) {
        // For web, use text sharing
        await Share.share(
          ticketText.toString(),
          subject: 'Ticket de Cita - ${widget.business.name}',
        );
      } else {
        // For mobile platforms, try to share as file first, fallback to text sharing
        try {
          // Get temporary directory
          final directory = await getTemporaryDirectory();
          final fileName =
              'ticket_cita_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';
          final filePath = '${directory.path}/$fileName';

          // Write ticket content to file using dart:io
          // Import dart:io dynamically to avoid web compilation issues
          // ignore: avoid_web_libraries_in_flutter
          final file = File(filePath);
          await file.writeAsString(ticketText.toString());

          // Share the file
          await Share.shareXFiles(
            [XFile(file.path)],
            subject: 'Ticket de Cita - ${widget.business.name}',
            text: 'Ticket de cita adjunto',
          );
        } catch (fileError) {
          // Fallback to text sharing if file creation fails
          await Share.share(
            ticketText.toString(),
            subject: 'Ticket de Cita - ${widget.business.name}',
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.l10n.ticketSharedSuccessfully),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.l10n.errorSharingTicket}: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}


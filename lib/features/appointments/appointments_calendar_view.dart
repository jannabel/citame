import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cupertino_modal_sheet/cupertino_modal_sheet.dart';
import '../../core/models/appointment_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';
import 'appointments_providers.dart';
import 'appointment_form_dialog.dart';
import 'reschedule_appointment_dialog.dart';

class AppointmentsCalendarView extends ConsumerStatefulWidget {
  final List<Appointment> appointments;
  final String businessId;

  const AppointmentsCalendarView({
    super.key,
    required this.appointments,
    required this.businessId,
  });

  @override
  ConsumerState<AppointmentsCalendarView> createState() =>
      _AppointmentsCalendarViewState();
}

class _AppointmentsCalendarViewState
    extends ConsumerState<AppointmentsCalendarView> {
  late ValueNotifier<List<Appointment>> _selectedAppointments;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final Set<AppointmentStatus> _selectedStatuses = {
    AppointmentStatus.pending,
    AppointmentStatus.confirmed,
    AppointmentStatus.completed,
    AppointmentStatus.cancelled,
  };

  @override
  void initState() {
    super.initState();
    // Normalize initial selected day
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _focusedDay = _selectedDay;
    _selectedAppointments = ValueNotifier(_getAppointmentsForDay(_selectedDay));
  }

  @override
  void didUpdateWidget(AppointmentsCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update when appointments list changes
    if (oldWidget.appointments != widget.appointments) {
      final updatedAppointments = _getAppointmentsForDay(_selectedDay);
      _selectedAppointments.value = updatedAppointments;
    }
  }

  @override
  void dispose() {
    _selectedAppointments.dispose();
    super.dispose();
  }

  List<Appointment> _getAppointmentsForDay(DateTime day) {
    // Normalize the selected day to avoid timezone issues
    final selectedDateOnly = DateTime(day.year, day.month, day.day);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDateOnly);

    return widget.appointments.where((apt) {
      // Filter by status first
      if (!_selectedStatuses.contains(apt.status)) {
        return false;
      }

      try {
        // Try to parse the appointment date and compare only the date part
        final aptDate = DateTime.parse(apt.date);
        final aptDateOnly = DateTime(aptDate.year, aptDate.month, aptDate.day);

        // Compare year, month, and day directly
        return aptDateOnly.year == selectedDateOnly.year &&
            aptDateOnly.month == selectedDateOnly.month &&
            aptDateOnly.day == selectedDateOnly.day;
      } catch (e) {
        // If parsing fails, try string comparison as fallback
        return apt.date == dateStr || apt.date.startsWith(dateStr);
      }
    }).toList();
  }

  Map<DateTime, List<Appointment>> _getAppointmentsByDate() {
    final Map<DateTime, List<Appointment>> appointmentsByDate = {};

    for (final appointment in widget.appointments) {
      // Filter by status
      if (!_selectedStatuses.contains(appointment.status)) {
        continue;
      }

      try {
        final date = DateTime.parse(appointment.date);
        // Normalize to date only (no time, no timezone)
        final dateOnly = DateTime(date.year, date.month, date.day);

        if (appointmentsByDate.containsKey(dateOnly)) {
          appointmentsByDate[dateOnly]!.add(appointment);
        } else {
          appointmentsByDate[dateOnly] = [appointment];
        }
      } catch (e) {
        // Skip invalid dates
        continue;
      }
    }

    return appointmentsByDate;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appointmentsByDate = _getAppointmentsByDate();

    // Update selected appointments when widget rebuilds (e.g., when appointments list changes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final updatedAppointments = _getAppointmentsForDay(_selectedDay);
        if (_selectedAppointments.value.length != updatedAppointments.length ||
            _selectedAppointments.value != updatedAppointments) {
          _selectedAppointments.value = updatedAppointments;
        }
      }
    });

    final selectedAppointments = _selectedAppointments.value;

    return CustomScrollView(
      slivers: [
        // Calendar Card
        SliverToBoxAdapter(
          child: AppTheme.card(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMD,
              ),
              child: TableCalendar<Appointment>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                eventLoader: (day) {
                  final dateOnly = DateTime(day.year, day.month, day.day);
                  return appointmentsByDate[dateOnly] ?? [];
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    // Normalize to date only to avoid timezone issues
                    _selectedDay = DateTime(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                    );
                    _focusedDay = focusedDay;
                  });
                  // Update appointments list
                  final appointments = _getAppointmentsForDay(_selectedDay);
                  _selectedAppointments.value = appointments;
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: AppTheme.textStyleBody.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  defaultTextStyle: AppTheme.textStyleBody,
                  selectedTextStyle: AppTheme.textStyleBody.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  todayTextStyle: AppTheme.textStyleBody.copyWith(
                    color: AppTheme.indigoMain,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppTheme.indigoMain,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppTheme.indigoMain.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.indigoMain, width: 2),
                  ),
                  markerDecoration: BoxDecoration(
                    color: AppTheme.indigoMain,
                    shape: BoxShape.circle,
                  ),
                  markerSize: 6,
                  canMarkersOverflow: true,
                  markersMaxCount: 3,
                  markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: AppTheme.textStyleH3,
                  leftChevronIcon: Icon(
                    Icons.chevron_left_outlined,
                    color: AppTheme.indigoMain,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right_outlined,
                    color: AppTheme.indigoMain,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: AppTheme.textStyleBodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  weekendStyle: AppTheme.textStyleBodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Selected Day Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMD,
              vertical: AppTheme.spacingMD,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppTheme.indigoMain,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Text(
                  DateFormat(
                        'EEEE, MMMM d',
                        Localizations.localeOf(context).toString(),
                      )
                      .format(_selectedDay)
                      .split(' ')
                      .map(
                        (word) => word.isEmpty
                            ? word
                            : word[0].toUpperCase() + word.substring(1),
                      )
                      .join(' '),
                  style: AppTheme.textStyleH3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.indigoMain.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    '${selectedAppointments.length} ${selectedAppointments.length == 1 ? (l10n.appointments.toLowerCase()) : (l10n.appointments.toLowerCase())}',
                    style: AppTheme.textStyleBodySmall.copyWith(
                      color: AppTheme.indigoMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: const SizedBox(height: AppTheme.spacingMD)),
        // Appointments List
        if (selectedAppointments.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingLG),
                      decoration: BoxDecoration(
                        color: AppTheme.indigoMain.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.event_busy_outlined,
                        size: 64,
                        color: AppTheme.indigoMain.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLG),
                    Text(
                      l10n.noAppointmentsForDay,
                      style: AppTheme.textStyleBody.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index.isOdd) {
                  return const SizedBox(height: AppTheme.spacingMD);
                }
                final appointmentIndex = index ~/ 2;
                if (appointmentIndex >= selectedAppointments.length) {
                  return null;
                }
                final appointment = selectedAppointments[appointmentIndex];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMD,
                  ),
                  child: AppointmentCard(
                    appointment: appointment,
                    businessId: widget.businessId,
                  ),
                );
              },
              childCount: selectedAppointments.isEmpty
                  ? 0
                  : selectedAppointments.length * 2 - 1,
            ),
          ),
      ],
    );
  }
}

class AppointmentCard extends ConsumerWidget {
  final Appointment appointment;
  final String businessId;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.businessId,
  });

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return AppTheme.warning;
      case AppointmentStatus.confirmed:
        return AppTheme.success;
      case AppointmentStatus.cancelled:
        return AppTheme.error;
      case AppointmentStatus.completed:
        return AppTheme.indigoMain;
    }
  }

  String _getStatusLabel(AppointmentStatus status, BuildContext context) {
    final l10n = context.l10n;
    switch (status) {
      case AppointmentStatus.pending:
        return l10n.pending;
      case AppointmentStatus.confirmed:
        return l10n.confirmed;
      case AppointmentStatus.cancelled:
        return l10n.cancelled;
      case AppointmentStatus.completed:
        return l10n.completed;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statusColor = _getStatusColor(appointment.status);

    return GestureDetector(
      onTap: () {
        // Show appointment details or actions
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => _AppointmentDetailsSheet(
            appointment: appointment,
            businessId: businessId,
            statusColor: statusColor,
          ),
        );
      },
      child: AppTheme.card(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First Row: Customer Name and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    appointment.customer?.name ?? l10n.customer,
                    style: AppTheme.textStyleBody.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    _getStatusLabel(appointment.status, context),
                    style: AppTheme.textStyleCaption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            // Phone (if available)
            if (appointment.customer?.phone != null) ...[
              const SizedBox(height: AppTheme.spacingXS),
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacingXS),
                  Text(
                    appointment.customer!.phone,
                    style: AppTheme.textStyleBodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            // Time Row (gray style)
            const SizedBox(height: AppTheme.spacingMD),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMD,
                vertical: AppTheme.spacingSM,
              ),
              decoration: BoxDecoration(
                color: AppTheme.backgroundMain,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.textPrimary,
                  ),
                  const SizedBox(width: AppTheme.spacingXS),
                  Text(
                    '${appointment.startTime} - ${appointment.endTime}',
                    style: AppTheme.textStyleBodySmall.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentDetailsSheet extends ConsumerWidget {
  final Appointment appointment;
  final String businessId;
  final Color statusColor;

  const _AppointmentDetailsSheet({
    required this.appointment,
    required this.businessId,
    required this.statusColor,
  });

  String _getStatusLabel(AppointmentStatus status, BuildContext context) {
    final l10n = context.l10n;
    switch (status) {
      case AppointmentStatus.pending:
        return l10n.pending;
      case AppointmentStatus.confirmed:
        return l10n.confirmed;
      case AppointmentStatus.cancelled:
        return l10n.cancelled;
      case AppointmentStatus.completed:
        return l10n.completed;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSM),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.appointments, style: AppTheme.textStyleH3),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    _getStatusLabel(appointment.status, context),
                    style: AppTheme.textStyleBodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Consumer(
                  builder: (context, ref, child) {
                    return IconButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await showCupertinoModalSheet(
                          context: context,
                          builder: (context) => AppointmentFormDialog(
                            businessId: businessId,
                            appointment: appointment,
                          ),
                        );
                        if (context.mounted) {
                          ref.invalidate(appointmentsProvider(businessId));
                        }
                      },
                      icon: const Icon(Icons.edit_outlined),
                      color: AppTheme.indigoMain,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLG),
          // Scrollable Details
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMD,
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: l10n.customer,
                    value: appointment.customer?.name ?? l10n.customer,
                  ),
                  if (appointment.customer?.phone != null)
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      label: l10n.phone,
                      value: appointment.customer!.phone,
                    ),
                  _DetailRow(
                    icon: Icons.access_time_outlined,
                    label: l10n.time,
                    value: '${appointment.startTime} - ${appointment.endTime}',
                  ),
                  _DetailRow(
                    icon: Icons.content_cut_outlined,
                    label: l10n.services,
                    value: appointment.service?.name ?? l10n.services,
                  ),
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: l10n.employees,
                    value: appointment.employee?.name ?? l10n.employees,
                  ),
                  if (appointment.depositPaid == true)
                    _DetailRow(
                      icon: Icons.payment_outlined,
                      label: l10n.depositPaid,
                      value: l10n.depositPaid,
                      iconColor: AppTheme.success,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLG),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: _AppointmentActions(
              appointment: appointment,
              businessId: businessId,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? AppTheme.textSecondary),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.textStyleCaption.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(value, style: AppTheme.textStyleBody),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentActions extends ConsumerWidget {
  final Appointment appointment;
  final String businessId;

  const _AppointmentActions({
    required this.appointment,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    if (appointment.status == AppointmentStatus.pending) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await ref
                          .read(appointmentsNotifierProvider.notifier)
                          .updateAppointmentStatus(
                            appointment.id,
                            AppointmentStatusUpdate(
                              status: AppointmentStatus.confirmed,
                            ),
                            businessId,
                          );
                      if (context.mounted) {
                        ref.invalidate(appointmentsProvider(businessId));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.appointmentConfirmedSuccessfully,
                            ),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error: ${e.toString().replaceAll('Exception: ', '')}',
                            ),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check, size: 20),
                  label: Text(l10n.confirm),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.cancelAppointmentTitle),
                        content: Text(l10n.cancelAppointmentMessage),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.no),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.error,
                            ),
                            child: Text(l10n.yesCancel),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      try {
                        await ref
                            .read(appointmentsNotifierProvider.notifier)
                            .updateAppointmentStatus(
                              appointment.id,
                              AppointmentStatusUpdate(
                                status: AppointmentStatus.cancelled,
                              ),
                              businessId,
                            );
                        if (context.mounted) {
                          ref.invalidate(appointmentsProvider(businessId));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.appointmentCancelledSuccessfully,
                              ),
                              backgroundColor: AppTheme.warning,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: ${e.toString().replaceAll('Exception: ', '')}',
                              ),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 20),
                  label: Text(l10n.cancelAppointment),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSM),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await showCupertinoModalSheet(
                  context: context,
                  builder: (context) => RescheduleAppointmentDialog(
                    appointment: appointment,
                    businessId: businessId,
                  ),
                );
                if (context.mounted) {
                  ref.invalidate(appointmentsProvider(businessId));
                }
              },
              icon: const Icon(Icons.schedule_outlined, size: 20),
              label: Text(l10n.reschedule),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.indigoMain,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (appointment.status == AppointmentStatus.confirmed) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await ref
                          .read(appointmentsNotifierProvider.notifier)
                          .updateAppointmentStatus(
                            appointment.id,
                            AppointmentStatusUpdate(
                              status: AppointmentStatus.completed,
                            ),
                            businessId,
                          );
                      if (context.mounted) {
                        ref.invalidate(appointmentsProvider(businessId));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.appointmentCompletedSuccessfully,
                            ),
                            backgroundColor: AppTheme.indigoMain,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error: ${e.toString().replaceAll('Exception: ', '')}',
                            ),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(l10n.completeAppointment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.indigoMain,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.cancelAppointmentTitle),
                        content: Text(l10n.cancelAppointmentMessage),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.no),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.error,
                            ),
                            child: Text(l10n.yesCancel),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      try {
                        await ref
                            .read(appointmentsNotifierProvider.notifier)
                            .updateAppointmentStatus(
                              appointment.id,
                              AppointmentStatusUpdate(
                                status: AppointmentStatus.cancelled,
                              ),
                              businessId,
                            );
                        if (context.mounted) {
                          ref.invalidate(appointmentsProvider(businessId));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.appointmentCancelledSuccessfully,
                              ),
                              backgroundColor: AppTheme.warning,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: ${e.toString().replaceAll('Exception: ', '')}',
                              ),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 20),
                  label: Text(l10n.cancelAppointment),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSM),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await showCupertinoModalSheet(
                  context: context,
                  builder: (context) => RescheduleAppointmentDialog(
                    appointment: appointment,
                    businessId: businessId,
                  ),
                );
                if (context.mounted) {
                  ref.invalidate(appointmentsProvider(businessId));
                }
              },
              icon: const Icon(Icons.schedule_outlined, size: 20),
              label: Text(l10n.reschedule),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.indigoMain,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

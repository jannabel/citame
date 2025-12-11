import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cupertino_modal_sheet/cupertino_modal_sheet.dart';
import '../../core/models/appointment_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';
import 'appointments_providers.dart';
import 'appointment_form_dialog.dart';
import 'reschedule_appointment_dialog.dart';

class AppointmentsDayView extends ConsumerStatefulWidget {
  final List<Appointment> appointments;
  final String businessId;

  const AppointmentsDayView({
    super.key,
    required this.appointments,
    required this.businessId,
  });

  @override
  ConsumerState<AppointmentsDayView> createState() =>
      _AppointmentsDayViewState();
}

class _AppointmentsDayViewState extends ConsumerState<AppointmentsDayView> {
  DateTime _selectedDate = DateTime.now();
  final Set<AppointmentStatus> _selectedStatuses = {
    AppointmentStatus.pending,
    AppointmentStatus.confirmed,
    AppointmentStatus.completed,
  };

  // Drag state
  bool _isDragging = false;
  double? _dragStartY;
  double? _dragEndY;
  final GlobalKey _timelineKey = GlobalKey();

  // Business hours configuration (8 AM to 8 PM)
  static const int startHour = 8;
  static const int endHour = 20;
  static const double hourHeight = 80.0; // Height of each hour slot

  List<Appointment> _getAppointmentsForDay(DateTime day) {
    final selectedDateOnly = DateTime(day.year, day.month, day.day);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDateOnly);

    return widget.appointments.where((apt) {
      if (!_selectedStatuses.contains(apt.status)) {
        return false;
      }

      try {
        final aptDate = DateTime.parse(apt.date);
        final aptDateOnly = DateTime(aptDate.year, aptDate.month, aptDate.day);

        return aptDateOnly.year == selectedDateOnly.year &&
            aptDateOnly.month == selectedDateOnly.month &&
            aptDateOnly.day == selectedDateOnly.day;
      } catch (e) {
        return apt.date == dateStr || apt.date.startsWith(dateStr);
      }
    }).toList();
  }

  double _getTopPosition(String time) {
    try {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final totalMinutes = (hour - startHour) * 60 + minute;
      return (totalMinutes / 60) * hourHeight;
    } catch (e) {
      return 0;
    }
  }

  double _getHeight(String startTime, String endTime) {
    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');

      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      final startTotalMinutes = startHour * 60 + startMinute;
      final endTotalMinutes = endHour * 60 + endMinute;

      final durationMinutes = endTotalMinutes - startTotalMinutes;
      return (durationMinutes / 60) * hourHeight;
    } catch (e) {
      return hourHeight * 0.5; // Default to 30 minutes
    }
  }

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

  void _previousDay() {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day - 1,
      );
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + 1,
      );
    });
  }

  void _goToToday() {
    setState(() {
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  // Convert Y position to time string
  String _yPositionToTime(double y) {
    final totalHours = y / hourHeight;
    final hoursFromStart = startHour + totalHours;
    final hour = hoursFromStart.floor();
    final minute = ((hoursFromStart - hour) * 60).round();

    // Ensure hour is within valid range
    final clampedHour = hour.clamp(startHour, endHour - 1);
    final clampedMinute = minute.clamp(0, 59);

    // Round to nearest 15 minutes for better UX
    final roundedMinute = (clampedMinute / 15).round() * 15;
    final finalMinute = roundedMinute >= 60 ? 0 : roundedMinute;
    final finalHour = roundedMinute >= 60 ? clampedHour + 1 : clampedHour;

    return '${finalHour.clamp(startHour, endHour).toString().padLeft(2, '0')}:${finalMinute.toString().padLeft(2, '0')}';
  }

  void _handleDragStart(DragStartDetails details) {
    final renderBox =
        _timelineKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final y = localPosition.dy;

    setState(() {
      _isDragging = true;
      _dragStartY = y;
      _dragEndY = y;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _dragStartY == null) return;

    final renderBox =
        _timelineKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final y = localPosition.dy;

    setState(() {
      _dragEndY = y;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging || _dragStartY == null || _dragEndY == null) {
      setState(() {
        _isDragging = false;
        _dragStartY = null;
        _dragEndY = null;
      });
      return;
    }

    final startY = _dragStartY! < _dragEndY! ? _dragStartY! : _dragEndY!;
    final endY = _dragStartY! > _dragEndY! ? _dragStartY! : _dragEndY!;

    // Ensure minimum height (at least 15 minutes)
    final minHeight = (15 / 60) * hourHeight; // 15 minutes in pixels
    if ((endY - startY).abs() < minHeight) {
      // If drag is too small, extend to minimum duration
      final centerY = (startY + endY) / 2;
      final adjustedStartY = centerY - minHeight / 2;
      final adjustedEndY = centerY + minHeight / 2;

      final startTime = _yPositionToTime(
        adjustedStartY.clamp(0, (endHour - startHour) * hourHeight),
      );
      final endTime = _yPositionToTime(
        adjustedEndY.clamp(0, (endHour - startHour) * hourHeight),
      );

      _openAppointmentDialog(startTime, endTime);
    } else {
      final startTime = _yPositionToTime(
        startY.clamp(0, (endHour - startHour) * hourHeight),
      );
      final endTime = _yPositionToTime(
        endY.clamp(0, (endHour - startHour) * hourHeight),
      );

      _openAppointmentDialog(startTime, endTime);
    }

    setState(() {
      _isDragging = false;
      _dragStartY = null;
      _dragEndY = null;
    });
  }

  void _openAppointmentDialog(String startTime, String endTime) {
    final startTimeOfDay = TimeOfDay(
      hour: int.parse(startTime.split(':')[0]),
      minute: int.parse(startTime.split(':')[1]),
    );

    final endTimeOfDay = TimeOfDay(
      hour: int.parse(endTime.split(':')[0]),
      minute: int.parse(endTime.split(':')[1]),
    );

    showCupertinoModalSheet(
      context: context,
      builder: (context) => AppointmentFormDialog(
        businessId: widget.businessId,
        initialDate: _selectedDate,
        initialStartTime: startTimeOfDay,
        initialEndTime: endTimeOfDay,
      ),
    ).then((_) {
      if (context.mounted) {
        ref.invalidate(appointmentsProvider(widget.businessId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appointmentsForDay = _getAppointmentsForDay(_selectedDate);

    // Sort appointments by start time
    appointmentsForDay.sort((a, b) {
      try {
        final aParts = a.startTime.split(':');
        final bParts = b.startTime.split(':');
        final aTime = int.parse(aParts[0]) * 60 + int.parse(aParts[1]);
        final bTime = int.parse(bParts[0]) * 60 + int.parse(bParts[1]);
        return aTime.compareTo(bTime);
      } catch (e) {
        return 0;
      }
    });

    return Column(
      children: [
        // Date Header
        AppTheme.card(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          margin: const EdgeInsets.all(AppTheme.spacingMD),
          child: Row(
            children: [
              IconButton(
                onPressed: _previousDay,
                icon: const Icon(Icons.chevron_left_outlined),
                color: AppTheme.indigoMain,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      DateFormat(
                            'EEEE, MMMM d',
                            Localizations.localeOf(context).toString(),
                          )
                          .format(_selectedDate)
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
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      DateFormat('yyyy').format(_selectedDate),
                      style: AppTheme.textStyleBodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _nextDay,
                icon: const Icon(Icons.chevron_right_outlined),
                color: AppTheme.indigoMain,
              ),
              if (!_isToday)
                TextButton(
                  onPressed: _goToToday,
                  child: Text(
                    'Today',
                    style: AppTheme.textStyleBodySmall.copyWith(
                      color: AppTheme.indigoMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Timeline View
        Expanded(
          child: SingleChildScrollView(
            child: GestureDetector(
              onPanStart: _handleDragStart,
              onPanUpdate: _handleDragUpdate,
              onPanEnd: _handleDragEnd,
              child: Stack(
                key: _timelineKey,
                children: [
                  // Time slots background
                  Column(
                    children: List.generate(endHour - startHour, (index) {
                      final hour = startHour + index;
                      return Container(
                        height: hourHeight,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppTheme.borderLight.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Time label column
                            SizedBox(
                              width: 80,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: AppTheme.spacingMD,
                                  top: AppTheme.spacingXS,
                                ),
                                child: Text(
                                  '${hour.toString().padLeft(2, '0')}:00',
                                  style: AppTheme.textStyleBodySmall.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            // Content area
                            Expanded(child: Container()),
                          ],
                        ),
                      );
                    }),
                  ),
                  // Drag selection indicator
                  if (_isDragging && _dragStartY != null && _dragEndY != null)
                    Positioned(
                      left: 90,
                      right: AppTheme.spacingMD,
                      top: _dragStartY! < _dragEndY!
                          ? _dragStartY!
                          : _dragEndY!,
                      height: (_dragEndY! - _dragStartY!).abs(),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.indigoMain.withOpacity(0.2),
                          border: Border.all(
                            color: AppTheme.indigoMain,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMD,
                              vertical: AppTheme.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.indigoMain,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSmall,
                              ),
                            ),
                            child: Text(
                              _dragStartY! < _dragEndY!
                                  ? '${_yPositionToTime(_dragStartY!)} - ${_yPositionToTime(_dragEndY!)}'
                                  : '${_yPositionToTime(_dragEndY!)} - ${_yPositionToTime(_dragStartY!)}',
                              style: AppTheme.textStyleBodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Appointments positioned on timeline
                  ...appointmentsForDay.map((appointment) {
                    final top = _getTopPosition(appointment.startTime);
                    final height = _getHeight(
                      appointment.startTime,
                      appointment.endTime,
                    );
                    final statusColor = _getStatusColor(appointment.status);

                    return Positioned(
                      left: 90,
                      right: AppTheme.spacingMD,
                      top: top,
                      height: height,
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => _AppointmentDetailsSheet(
                              appointment: appointment,
                              businessId: widget.businessId,
                              statusColor: statusColor,
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingXS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            border: Border.all(color: statusColor, width: 2),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                              height < 40
                                  ? AppTheme.spacingXS
                                  : AppTheme.spacingSM,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    height - 4, // Account for vertical margin
                              ),
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // Time and Status
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '${appointment.startTime} - ${appointment.endTime}',
                                            style: AppTheme.textStyleCaption
                                                .copyWith(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: height < 40
                                                      ? 10
                                                      : 12,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        if (height >= 40)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppTheme.spacingXS,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusSmall,
                                                  ),
                                            ),
                                            child: Text(
                                              _getStatusLabel(
                                                appointment.status,
                                                context,
                                              ),
                                              style: AppTheme.textStyleCaption
                                                  .copyWith(
                                                    color: statusColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 10,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (height > 50) ...[
                                      SizedBox(
                                        height: height < 60
                                            ? 2
                                            : AppTheme.spacingXS,
                                      ),
                                      // Customer name
                                      Text(
                                        appointment.customer?.name ??
                                            l10n.customer,
                                        style: AppTheme.textStyleBodySmall
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                              fontSize: height < 60 ? 11 : 14,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
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

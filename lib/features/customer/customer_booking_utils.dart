import '../../core/models/schedule_models.dart';
import '../../core/models/appointment_models.dart';
import '../../core/models/employee_models.dart';
import 'customer_booking_providers.dart';

/// Calculates available time slots for a given date and service
List<TimeSlot> calculateAvailableTimeSlots({
  required String date, // Format: yyyy-MM-dd
  required List<Schedule> schedules,
  required List<ScheduleException> exceptions,
  required List<Appointment> appointments,
  required int serviceDuration, // in minutes
  required List<Employee> availableEmployees,
  DateTime?
  currentDateTime, // Optional: current date/time for filtering past slots
}) {
  // Parse the date
  final selectedDate = DateTime.parse(date);
  // Convert DateTime.weekday (1-7, Monday=1, Sunday=7) to 0-6 format (Sunday=0)
  // DateTime.weekday: Monday=1, Tuesday=2, ..., Sunday=7
  // Target format: Sunday=0, Monday=1, ..., Saturday=6
  final dayOfWeek = selectedDate.weekday == 7 ? 0 : selectedDate.weekday;

  print(
    '[TimeSlots] Calculating for date: $date, weekday: ${selectedDate.weekday}, dayOfWeek: $dayOfWeek',
  );
  print(
    '[TimeSlots] Service duration: $serviceDuration minutes (${serviceDuration / 60} hours)',
  );

  // Check if there's an exception for this date
  final dateExceptions = exceptions.where((ex) => ex.date == date).toList();

  // Check if entire day is closed
  final fullDayException = dateExceptions.any(
    (ex) => ex.isClosed == true && ex.startTime == null && ex.endTime == null,
  );

  if (fullDayException) {
    print('[TimeSlots] Business is closed due to exception on $date');
    return []; // Business is closed on this date
  }

  // Find schedule for this day of week
  final daySchedule = schedules.firstWhere(
    (s) => s.dayOfWeek == dayOfWeek,
    orElse: () {
      print(
        '[TimeSlots] No schedule found for dayOfWeek $dayOfWeek, defaulting to closed',
      );
      return Schedule(id: '', dayOfWeek: dayOfWeek, isClosed: true);
    },
  );

  print(
    '[TimeSlots] Day schedule: isClosed=${daySchedule.isClosed}, startTime=${daySchedule.startTime}, endTime=${daySchedule.endTime}',
  );

  if (daySchedule.isClosed) {
    print('[TimeSlots] Business is closed on this day');
    return []; // Business is closed on this day
  }

  if (daySchedule.startTime == null || daySchedule.endTime == null) {
    print('[TimeSlots] No working hours defined for this day');
    return []; // No working hours defined
  }

  // Parse working hours
  final startTime = _parseTime(daySchedule.startTime!);
  final endTime = _parseTime(daySchedule.endTime!);

  // Generate time slots for each available employee
  final List<TimeSlot> allSlots = [];

  print('[TimeSlots] Service duration: $serviceDuration minutes');
  print(
    '[TimeSlots] Working hours: ${daySchedule.startTime} - ${daySchedule.endTime}',
  );
  print(
    '[TimeSlots] Existing appointments for this date: ${appointments.length}',
  );

  // Calculate minimum allowed time (30 minutes from now if booking today)
  int? minAllowedTimeMinutes;
  if (currentDateTime != null) {
    final selectedDateOnly = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final todayOnly = DateTime(
      currentDateTime.year,
      currentDateTime.month,
      currentDateTime.day,
    );

    if (selectedDateOnly.year == todayOnly.year &&
        selectedDateOnly.month == todayOnly.month &&
        selectedDateOnly.day == todayOnly.day) {
      // Booking today - need at least 30 minutes from now
      final minBookingTime = currentDateTime.add(const Duration(minutes: 30));
      minAllowedTimeMinutes = minBookingTime.hour * 60 + minBookingTime.minute;
      print(
        '[TimeSlots] Booking today, minimum time: ${minBookingTime.hour.toString().padLeft(2, '0')}:${minBookingTime.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  for (final employee in availableEmployees) {
    final employeeAppointments = appointments
        .where(
          (apt) =>
              apt.employeeId == employee.id &&
              apt.status != AppointmentStatus.cancelled,
        )
        .toList();
    print(
      '[TimeSlots] Employee ${employee.name} has ${employeeAppointments.length} appointments on this date',
    );

    final employeeSlots = _generateTimeSlots(
      startTime: startTime,
      endTime: endTime,
      serviceDuration: serviceDuration,
      employeeId: employee.id,
      employeeName: employee.name,
      existingAppointments: employeeAppointments,
      exceptions: exceptions,
      date: date,
      minAllowedTimeMinutes: minAllowedTimeMinutes,
    );
    print(
      '[TimeSlots] Generated ${employeeSlots.length} slots for ${employee.name}',
    );
    allSlots.addAll(employeeSlots);
  }

  // Sort by start time
  allSlots.sort((a, b) => a.startTime.compareTo(b.startTime));

  print('[TimeSlots] Generated ${allSlots.length} time slots');

  return allSlots;
}

/// Parses a time string (HH:mm) to minutes since midnight
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

/// Generates available time slots for an employee
List<TimeSlot> _generateTimeSlots({
  required int startTime, // minutes since midnight
  required int endTime, // minutes since midnight
  required int serviceDuration, // in minutes
  required String employeeId,
  required String employeeName,
  required List<Appointment> existingAppointments,
  required List<ScheduleException> exceptions,
  required String date,
  int?
  minAllowedTimeMinutes, // Minimum allowed time in minutes since midnight (for today's bookings)
}) {
  final List<TimeSlot> slots = [];
  final slotInterval = 15; // 15-minute intervals between slots

  // Get time range exceptions for this date
  final dateExceptions = exceptions
      .where(
        (ex) =>
            ex.date == date &&
            ex.isClosed == true &&
            ex.startTime != null &&
            ex.endTime != null,
      )
      .toList();

  int currentTime = startTime;

  while (currentTime + serviceDuration <= endTime) {
    final slotStart = _formatTime(currentTime);
    final slotEnd = _formatTime(currentTime + serviceDuration);

    // Check if this slot is in the past or too soon (minimum 30 minutes)
    if (minAllowedTimeMinutes != null && currentTime < minAllowedTimeMinutes) {
      // Skip slots that are too soon
      currentTime += slotInterval;
      continue;
    }

    // Check if this slot conflicts with time range exceptions
    final blockedByException = dateExceptions.any((ex) {
      final exStart = _parseTime(ex.startTime!);
      final exEnd = _parseTime(ex.endTime!);
      // Check if slot overlaps with exception time range
      return (currentTime < exEnd && currentTime + serviceDuration > exStart);
    });

    if (blockedByException) {
      print('[TimeSlots] Slot blocked by exception: $slotStart - $slotEnd');
      currentTime += slotInterval;
      continue;
    }

    // Check if this slot conflicts with existing appointments
    final hasConflict = existingAppointments.any((apt) {
      final aptStart = _parseTime(apt.startTime);
      final aptEnd = _parseTime(apt.endTime);

      // Check for overlap
      return (currentTime < aptEnd && currentTime + serviceDuration > aptStart);
    });

    if (!hasConflict) {
      print(
        '[TimeSlots] Adding slot: $slotStart - $slotEnd (duration: $serviceDuration minutes)',
      );
      slots.add(
        TimeSlot(
          startTime: slotStart,
          endTime: slotEnd,
          employeeId: employeeId,
          employeeName: employeeName,
        ),
      );
    }

    currentTime += slotInterval;
  }

  return slots;
}

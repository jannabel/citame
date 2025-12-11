class Schedule {
  final String id;
  final int dayOfWeek;
  final bool isClosed;
  final String? startTime;
  final String? endTime;

  Schedule({
    required this.id,
    required this.dayOfWeek,
    required this.isClosed,
    this.startTime,
    this.endTime,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
    id: json['id'] as String,
    dayOfWeek: json['dayOfWeek'] as int,
    isClosed: json['isClosed'] as bool? ?? false,
    startTime: json['startTime'] as String?,
    endTime: json['endTime'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'isClosed': isClosed,
    'startTime': startTime,
    'endTime': endTime,
  };
}

class ScheduleException {
  final String id;
  final String date;
  final String? reason;
  final bool? isClosed;
  final String? startTime;
  final String? endTime;

  ScheduleException({
    required this.id,
    required this.date,
    this.reason,
    this.isClosed,
    this.startTime,
    this.endTime,
  });

  factory ScheduleException.fromJson(Map<String, dynamic> json) =>
      ScheduleException(
        id: json['id'] as String,
        date: json['date'] as String,
        reason: json['reason'] as String?,
        isClosed: json['isClosed'] as bool?,
        startTime: json['startTime'] as String?,
        endTime: json['endTime'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'date': date,
    if (reason != null) 'reason': reason,
    if (isClosed != null) 'isClosed': isClosed,
    if (startTime != null) 'startTime': startTime,
    if (endTime != null) 'endTime': endTime,
  };

  // Helper to check if this exception blocks a specific time range
  bool blocksTimeRange(String timeStart, String timeEnd) {
    // If isClosed is true and no time range specified, blocks entire day
    if (isClosed == true && startTime == null && endTime == null) {
      return true;
    }

    // If time range specified, check overlap
    if (startTime != null && endTime != null) {
      return _timeRangesOverlap(timeStart, timeEnd, startTime!, endTime!);
    }

    // If no time range specified but isClosed is false or null, doesn't block
    return false;
  }

  bool _timeRangesOverlap(
    String start1,
    String end1,
    String start2,
    String end2,
  ) {
    final start1Minutes = _parseTime(start1);
    final end1Minutes = _parseTime(end1);
    final start2Minutes = _parseTime(start2);
    final end2Minutes = _parseTime(end2);

    return start1Minutes < end2Minutes && end1Minutes > start2Minutes;
  }

  int _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return hour * 60 + minute;
  }
}

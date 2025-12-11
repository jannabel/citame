import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../schedule/schedule_providers.dart';
import '../../core/models/schedule_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class WorkingHoursTab extends ConsumerStatefulWidget {
  final String businessId;

  const WorkingHoursTab({super.key, required this.businessId});

  @override
  ConsumerState<WorkingHoursTab> createState() => _WorkingHoursTabState();
}

class _WorkingHoursTabState extends ConsumerState<WorkingHoursTab> {
  List<String> _getDays(BuildContext context) {
    final l10n = context.l10n;
    return [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final days = _getDays(context);
    final schedulesAsync = ref.watch(schedulesProvider(widget.businessId));

    return schedulesAsync.when(
      data: (schedules) => ListView.builder(
        itemCount: 7,
        itemBuilder: (context, index) {
          final dayOfWeek = (index + 1) % 7; // Monday = 1, Sunday = 0
          final schedule = schedules.firstWhere(
            (s) => s.dayOfWeek == dayOfWeek,
            orElse: () =>
                Schedule(id: '', dayOfWeek: dayOfWeek, isClosed: true),
          );

          return _DayScheduleTile(
            day: days[index],
            schedule: schedule,
            businessId: widget.businessId,
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
    );
  }
}

class _DayScheduleTile extends ConsumerStatefulWidget {
  final String day;
  final Schedule schedule;
  final String businessId;

  const _DayScheduleTile({
    required this.day,
    required this.schedule,
    required this.businessId,
  });

  @override
  ConsumerState<_DayScheduleTile> createState() => _DayScheduleTileState();
}

class _DayScheduleTileState extends ConsumerState<_DayScheduleTile> {
  Future<void> _editSchedule() async {
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    bool isClosed = widget.schedule.isClosed;

    if (!isClosed && widget.schedule.startTime != null) {
      final parts = widget.schedule.startTime!.split(':');
      startTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    if (!isClosed && widget.schedule.endTime != null) {
      final parts = widget.schedule.endTime!.split(':');
      endTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ScheduleEditDialog(
        day: widget.day,
        isClosed: isClosed,
        startTime: startTime,
        endTime: endTime,
      ),
    );

    if (result != null) {
      final updates = {
        'isClosed': result['isClosed'] as bool,
        'startTime': result['startTime'] as String?,
        'endTime': result['endTime'] as String?,
      };

      if (widget.schedule.id.isEmpty) {
        // Create new schedule
        final newSchedule = Schedule(
          id: '',
          dayOfWeek: widget.schedule.dayOfWeek,
          isClosed: result['isClosed'] as bool,
          startTime: result['startTime'] as String?,
          endTime: result['endTime'] as String?,
        );
        await ref
            .read(scheduleNotifierProvider.notifier)
            .createSchedule(widget.businessId, newSchedule);
      } else {
        // Update existing schedule
        await ref
            .read(scheduleNotifierProvider.notifier)
            .updateSchedule(widget.schedule.id, updates);
      }

      if (mounted) {
        ref.invalidate(schedulesProvider(widget.businessId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = widget.schedule.isClosed
        ? l10n.closed
        : '${widget.schedule.startTime} - ${widget.schedule.endTime}';

    return AppTheme.card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingXS,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingSM,
        ),
        title: Text(
          widget.day,
          style: AppTheme.textStyleBody.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(status, style: AppTheme.textStyleBodySmall),
        trailing: IconButton(
          onPressed: _editSchedule,
          icon: const Icon(Icons.edit_outlined, size: 20),
          color: AppTheme.indigoMain,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ),
    );
  }
}

class _ScheduleEditDialog extends StatefulWidget {
  final String day;
  final bool isClosed;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  const _ScheduleEditDialog({
    required this.day,
    required this.isClosed,
    this.startTime,
    this.endTime,
  });

  @override
  State<_ScheduleEditDialog> createState() => _ScheduleEditDialogState();
}

class _ScheduleEditDialogState extends State<_ScheduleEditDialog> {
  late bool _isClosed;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _isClosed = widget.isClosed;
    _startTime = widget.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime = widget.endTime ?? const TimeOfDay(hour: 18, minute: 0);
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime!,
    );
    if (time != null) {
      setState(() => _startTime = time);
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(context: context, initialTime: _endTime!);
    if (time != null) {
      setState(() => _endTime = time);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text('${l10n.edit} ${widget.day}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: Text(l10n.open),
            value: !_isClosed,
            onChanged: (value) => setState(() => _isClosed = !value),
          ),
          if (!_isClosed) ...[
            ListTile(
              title: Text(l10n.startTime),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(_startTime!),
                    style: AppTheme.textStyleBodySmall.copyWith(
                      color: AppTheme.indigoMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: _selectStartTime,
                    icon: const Icon(Icons.access_time, size: 18),
                    color: AppTheme.indigoMain,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(l10n.endTime),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(_endTime!),
                    style: AppTheme.textStyleBodySmall.copyWith(
                      color: AppTheme.indigoMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: _selectEndTime,
                    icon: const Icon(Icons.access_time, size: 18),
                    color: AppTheme.indigoMain,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, {
              'isClosed': _isClosed,
              'startTime': _isClosed ? null : _formatTime(_startTime!),
              'endTime': _isClosed ? null : _formatTime(_endTime!),
            });
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

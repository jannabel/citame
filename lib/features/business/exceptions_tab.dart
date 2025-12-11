import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../schedule/schedule_providers.dart';
import '../../core/models/schedule_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class ExceptionsTab extends ConsumerWidget {
  final String businessId;

  const ExceptionsTab({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final exceptionsAsync = ref.watch(exceptionsProvider(businessId));

    return exceptionsAsync.when(
      data: (exceptions) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: AppTheme.primaryButton(
              text: l10n.addException,
              onPressed: () => _showAddExceptionDialog(context, ref),
              icon: Icons.add,
            ),
          ),
          Expanded(
            child: exceptions.isEmpty
                ? Center(child: Text(l10n.noExceptionsScheduled))
                : ListView.builder(
                    itemCount: exceptions.length,
                    itemBuilder: (context, index) {
                      final exception = exceptions[index];
                      return Slidable(
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) =>
                                  _deleteException(ref, exception.id),
                              backgroundColor: AppTheme.error,
                              icon: Icons.delete,
                              label: l10n.delete,
                            ),
                          ],
                        ),
                        child: AppTheme.card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMD,
                            vertical: AppTheme.spacingXS,
                          ),
                          child: ListTile(
                            leading: Icon(Icons.block, color: AppTheme.warning),
                            title: Text(
                              _formatDate(exception.date),
                              style: AppTheme.textStyleBody,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (exception.isClosed == true &&
                                    exception.startTime != null &&
                                    exception.endTime != null)
                                  Text(
                                    '${exception.startTime} - ${exception.endTime}',
                                    style: AppTheme.textStyleBodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (exception.reason != null)
                                  Text(
                                    exception.reason!,
                                    style: AppTheme.textStyleBodySmall,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        final l10n = context.l10n;
        return Center(child: Text('${l10n.error}: $error'));
      },
    );
  }

  String _formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('MMM d').format(dateTime);
    } catch (e) {
      return date;
    }
  }

  Future<void> _showAddExceptionDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    DateTime? selectedDate;
    final reasonController = TextEditingController();
    bool isClosed = true;
    bool useTimeRange = false;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dialogL10n = context.l10n;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(dialogL10n.addException),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: Text(dialogL10n.date),
                    subtitle: Text(
                      selectedDate != null
                          ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                          : dialogL10n.selectDatePlaceholder,
                    ),
                    trailing: const SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(Icons.calendar_today, size: 20),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Cerrado'),
                    value: isClosed,
                    onChanged: (value) {
                      setState(() {
                        isClosed = value;
                        if (!value) {
                          useTimeRange = false;
                          startTime = null;
                          endTime = null;
                        }
                      });
                    },
                  ),
                  if (isClosed)
                    SwitchListTile(
                      title: const Text('Rango de horas'),
                      subtitle: Text(
                        useTimeRange && startTime != null && endTime != null
                            ? '${startTime!.format(context)} - ${endTime!.format(context)}'
                            : 'Todo el día',
                      ),
                      value: useTimeRange,
                      onChanged: (value) {
                        setState(() {
                          useTimeRange = value;
                          if (!value) {
                            startTime = null;
                            endTime = null;
                          }
                        });
                      },
                    ),
                  if (isClosed && useTimeRange) ...[
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      title: Text('Hora inicio'),
                      subtitle: Text(
                        startTime != null
                            ? startTime!.format(context)
                            : 'Seleccionar hora',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: startTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            startTime = time;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      title: Text('Hora fin'),
                      subtitle: Text(
                        endTime != null
                            ? endTime!.format(context)
                            : 'Seleccionar hora',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: endTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            endTime = time;
                          });
                        }
                      },
                    ),
                  ],
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: dialogL10n.reasonOptional,
                      filled: true,
                      fillColor: AppTheme.indigoMain.withOpacity(0.04),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(dialogL10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  if (selectedDate != null) {
                    if (isClosed && useTimeRange) {
                      if (startTime != null && endTime != null) {
                        Navigator.pop(context, true);
                      }
                    } else {
                      Navigator.pop(context, true);
                    }
                  }
                },
                child: Text(dialogL10n.addException),
              ),
            ],
          ),
        );
      },
    );

    if (result == true && selectedDate != null) {
      final exception = ScheduleException(
        id: '',
        date: DateFormat('yyyy-MM-dd').format(selectedDate!),
        reason: reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim(),
        isClosed: isClosed ? true : null,
        startTime: isClosed && useTimeRange && startTime != null
            ? '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}'
            : null,
        endTime: isClosed && useTimeRange && endTime != null
            ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}'
            : null,
      );

      await ref
          .read(exceptionsNotifierProvider.notifier)
          .createException(businessId, exception);

      if (context.mounted) {
        ref.invalidate(exceptionsProvider(businessId));
      }
    }
  }

  Future<void> _deleteException(WidgetRef ref, String exceptionId) async {
    await ref
        .read(exceptionsNotifierProvider.notifier)
        .deleteException(exceptionId, businessId);

    if (ref.context.mounted) {
      ref.invalidate(exceptionsProvider(businessId));
    }
  }
}

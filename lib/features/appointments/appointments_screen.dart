import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupertino_modal_sheet/cupertino_modal_sheet.dart';
import '../auth/auth_providers.dart';
import 'appointments_providers.dart';
import 'appointment_form_dialog.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';
import 'appointments_calendar_view.dart';
import 'appointments_list_view.dart';
import 'appointments_day_view.dart';

enum AppointmentsViewType { calendar, list, day }

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  AppointmentsViewType _viewType = AppointmentsViewType.calendar;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final businessId = authState.businessId;
    final l10n = context.l10n;

    if (businessId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final appointmentsAsync = ref.watch(appointmentsProvider(businessId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        title: Text(l10n.appointments),
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
      ),
      body: appointmentsAsync.when(
        data: (appointments) => Column(
          children: [
            // View Type Toggle
            AppTheme.card(
              margin: const EdgeInsets.all(AppTheme.spacingMD),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSM,
                vertical: AppTheme.spacingSM,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ViewTypeToggle(
                      viewType: _viewType,
                      onChanged: (type) {
                        setState(() => _viewType = type);
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _viewType == AppointmentsViewType.calendar
                  ? AppointmentsCalendarView(
                      key: ValueKey('calendar_${appointments.length}_${appointments.hashCode}'),
                      appointments: appointments,
                      businessId: businessId,
                    )
                  : _viewType == AppointmentsViewType.list
                  ? AppointmentsListView(
                      key: ValueKey('list_${appointments.length}_${appointments.hashCode}'),
                      appointments: appointments,
                      businessId: businessId,
                    )
                  : AppointmentsDayView(
                      key: ValueKey('day_${appointments.length}_${appointments.hashCode}'),
                      appointments: appointments,
                      businessId: businessId,
                    ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'appointments_fab',
        onPressed: () => _showAddAppointmentDialog(context, ref, businessId),
        backgroundColor: AppTheme.indigoMain,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showAddAppointmentDialog(
    BuildContext context,
    WidgetRef ref,
    String businessId,
  ) async {
    await showCupertinoModalSheet(
      context: context,
      builder: (context) => AppointmentFormDialog(businessId: businessId),
    );
    if (context.mounted) {
      ref.invalidate(appointmentsProvider(businessId));
    }
  }
}

class _ViewTypeToggle extends StatelessWidget {
  final AppointmentsViewType viewType;
  final Function(AppointmentsViewType) onChanged;

  const _ViewTypeToggle({required this.viewType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _ToggleButton(
            label: l10n.calendar,
            icon: Icons.calendar_today_outlined,
            isSelected: viewType == AppointmentsViewType.calendar,
            onTap: () => onChanged(AppointmentsViewType.calendar),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSM),
        Expanded(
          child: _ToggleButton(
            label: 'List',
            icon: Icons.list_outlined,
            isSelected: viewType == AppointmentsViewType.list,
            onTap: () => onChanged(AppointmentsViewType.list),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSM),
        Expanded(
          child: _ToggleButton(
            label: 'Day',
            icon: Icons.schedule_outlined,
            isSelected: viewType == AppointmentsViewType.day,
            onTap: () => onChanged(AppointmentsViewType.day),
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingSM,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.indigoMain : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.indigoMain : AppTheme.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: AppTheme.spacingXS),
            Text(
              label,
              style: AppTheme.textStyleBodySmall.copyWith(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

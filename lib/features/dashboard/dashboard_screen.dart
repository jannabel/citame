import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../auth/auth_providers.dart';
import '../appointments/appointments_providers.dart';
import '../services/services_providers.dart';
import '../employees/employees_providers.dart';
import '../../core/models/appointment_models.dart';
import '../../core/models/service_models.dart';
import '../../core/models/employee_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final businessId = authState.businessId;

    if (businessId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final appointmentsAsync = ref.watch(appointmentsProvider(businessId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,

      body: SafeArea(
        child: appointmentsAsync.when(
          data: (appointments) {
            final servicesAsync = ref.watch(servicesProvider(businessId));
            final employeesAsync = ref.watch(employeesProvider(businessId));
            return servicesAsync.when(
              data: (services) {
                return employeesAsync.when(
                  data: (employees) => _buildContent(
                    context,
                    ref,
                    appointments,
                    services,
                    employees,
                    businessId,
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Center(child: Text('${context.l10n.error}: $error')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('${context.l10n.error}: $error')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('${context.l10n.error}: $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboard_fab',
        onPressed: () => context.push('/appointments'),
        backgroundColor: AppTheme.indigoMain,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Appointment> appointments,
    List<Service> services,
    List<Employee> employees,
    String businessId,
  ) {
    final l10n = context.l10n;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final now = DateTime.now();
    final thisMonth = now.month;
    final thisYear = now.year;

    // Calculate statistics
    final todayAppointments = appointments
        .where((apt) => apt.date == today)
        .toList();

    final monthAppointments = appointments.where((apt) {
      try {
        final aptDate = DateTime.parse(apt.date);
        return aptDate.month == thisMonth && aptDate.year == thisYear;
      } catch (e) {
        return false;
      }
    }).toList();

    final pending = appointments
        .where((apt) => apt.status == AppointmentStatus.pending)
        .length;
    final confirmed = appointments
        .where((apt) => apt.status == AppointmentStatus.confirmed)
        .length;
    final cancelled = appointments
        .where((apt) => apt.status == AppointmentStatus.cancelled)
        .length;
    final completedToday = todayAppointments
        .where((apt) => apt.status == AppointmentStatus.completed)
        .length;

    // Calculate estimated revenue
    double estimatedRevenue = 0;
    for (final apt in monthAppointments) {
      if (apt.status != AppointmentStatus.cancelled && apt.service != null) {
        estimatedRevenue += apt.service!.price;
      }
    }

    // Get upcoming appointments (next 3 days)
    final upcomingAppointments =
        appointments.where((apt) {
          try {
            final aptDate = DateTime.parse(apt.date);
            final todayOnly = DateTime(now.year, now.month, now.day);
            final aptDateOnly = DateTime(
              aptDate.year,
              aptDate.month,
              aptDate.day,
            );
            final daysDiff = aptDateOnly.difference(todayOnly).inDays;
            return daysDiff >= 0 &&
                daysDiff <= 3 &&
                apt.status != AppointmentStatus.cancelled;
          } catch (e) {
            return false;
          }
        }).toList()..sort((a, b) {
          try {
            return DateTime.parse(a.date).compareTo(DateTime.parse(b.date));
          } catch (e) {
            return 0;
          }
        });

    // Most popular services
    final serviceCounts = <String, int>{};
    for (final apt in monthAppointments) {
      if (apt.serviceId.isNotEmpty) {
        serviceCounts[apt.serviceId] = (serviceCounts[apt.serviceId] ?? 0) + 1;
      }
    }
    final popularServices = serviceCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topServices = popularServices.take(3).toList();

    // Most booked employees
    final employeeCounts = <String, int>{};
    for (final apt in monthAppointments) {
      if (apt.employeeId.isNotEmpty) {
        employeeCounts[apt.employeeId] =
            (employeeCounts[apt.employeeId] ?? 0) + 1;
      }
    }
    final busyEmployees = employeeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEmployees = busyEmployees.take(3).toList();

    // Status distribution
    final total = appointments.length;
    final statusCounts = {
      AppointmentStatus.pending: appointments
          .where((apt) => apt.status == AppointmentStatus.pending)
          .length,
      AppointmentStatus.confirmed: appointments
          .where((apt) => apt.status == AppointmentStatus.confirmed)
          .length,
      AppointmentStatus.completed: appointments
          .where((apt) => apt.status == AppointmentStatus.completed)
          .length,
      AppointmentStatus.cancelled: appointments
          .where((apt) => apt.status == AppointmentStatus.cancelled)
          .length,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section with Quick Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()},',
                    style: AppTheme.textStyleBody.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.dashboard, style: AppTheme.textStyleH2),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSM),
                decoration: BoxDecoration(
                  color: AppTheme.indigoMain.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: AppTheme.indigoMain,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLG),

          // Quick Actions Section - Moved to top for quick access
          Text(l10n.quickActions, style: AppTheme.textStyleH3),
          const SizedBox(height: AppTheme.spacingMD),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppTheme.spacingMD,
            mainAxisSpacing: AppTheme.spacingMD,
            childAspectRatio: 1.2,
            children: [
              _QuickActionCard(
                title: l10n.addAppointment,
                icon: Icons.add_circle_outline,
                color: AppTheme.indigoMain,
                onTap: () => context.push('/appointments'),
              ),
              _QuickActionCard(
                title: l10n.createService,
                icon: Icons.content_cut,
                color: AppTheme.indigoMain,
                onTap: () => context.push('/services'),
              ),
              _QuickActionCard(
                title: l10n.addEmployee,
                icon: Icons.person_add_outlined,
                color: AppTheme.indigoMain,
                onTap: () => context.push('/employees'),
              ),
              _QuickActionCard(
                title: l10n.settings,
                icon: Icons.settings_outlined,
                color: AppTheme.indigoMain,
                onTap: () => context.push('/business-settings'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLG),

          // Key Metrics Row
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Hoy',
                  value: todayAppointments.length.toString(),
                  subtitle: '$completedToday completadas',
                  color: AppTheme.indigoMain,
                  icon: Icons.today,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: _MetricCard(
                  title: 'Este mes',
                  value: monthAppointments.length.toString(),
                  subtitle: 'citas',
                  color: AppTheme.success,
                  icon: Icons.calendar_month,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD),

          // Revenue Card
          _RevenueCard(estimatedRevenue: estimatedRevenue),
          const SizedBox(height: AppTheme.spacingLG),

          // Summary Section
          Text(l10n.summary, style: AppTheme.textStyleH3),
          const SizedBox(height: AppTheme.spacingMD),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: l10n.pending,
                  count: pending,
                  color: AppTheme.warning,
                  icon: Icons.pending_outlined,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: _SummaryCard(
                  title: l10n.confirmed,
                  count: confirmed,
                  color: AppTheme.success,
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: l10n.cancelled,
                  count: cancelled,
                  color: AppTheme.error,
                  icon: Icons.cancel_outlined,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: _SummaryCard(
                  title: l10n.completedToday,
                  count: completedToday,
                  color: AppTheme.indigoMain,
                  icon: Icons.done_all_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLG),

          // Status Distribution Chart
          _StatusDistributionChart(statusCounts: statusCounts, total: total),
          const SizedBox(height: AppTheme.spacingLG),

          // Upcoming Appointments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Próximas citas', style: AppTheme.textStyleH3),
              TextButton(
                onPressed: () => context.push('/appointments'),
                child: Text(l10n.viewAll),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD),
          if (upcomingAppointments.isEmpty)
            AppTheme.card(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 48,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: AppTheme.spacingMD),
                    Text(
                      'No hay citas próximas',
                      style: AppTheme.textStyleBody.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...upcomingAppointments
                .take(3)
                .map(
                  (appointment) => _AppointmentCard(
                    appointment: appointment,
                    onTap: () => context.push('/appointments'),
                  ),
                ),
          const SizedBox(height: AppTheme.spacingLG),

          // Insights Section
          Text('Insights', style: AppTheme.textStyleH3),
          const SizedBox(height: AppTheme.spacingMD),

          // Popular Services
          _InsightCard(
            title: 'Servicios más populares',
            icon: Icons.trending_up,
            children: topServices.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMD),
                      child: Text(
                        'No hay datos suficientes',
                        style: AppTheme.textStyleBodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ]
                : topServices.map((entry) {
                    final service = services.firstWhere(
                      (s) => s.id == entry.key,
                      orElse: () => Service(
                        id: entry.key,
                        name: 'Servicio desconocido',
                        durationMinutes: 0,
                        price: 0,
                        active: true,
                      ),
                    );
                    return _InsightItem(
                      label: service.name,
                      value: '${entry.value} citas',
                      color: AppTheme.indigoMain,
                    );
                  }).toList(),
          ),
          const SizedBox(height: AppTheme.spacingMD),

          // Busy Employees
          _InsightCard(
            title: 'Empleados más ocupados',
            icon: Icons.people,
            children: topEmployees.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMD),
                      child: Text(
                        'No hay datos suficientes',
                        style: AppTheme.textStyleBodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ]
                : topEmployees.map((entry) {
                    final employee = employees.firstWhere(
                      (e) => e.id == entry.key,
                      orElse: () => Employee(
                        id: entry.key,
                        name: 'Empleado desconocido',
                        active: true,
                      ),
                    );
                    return _InsightItem(
                      label: employee.name,
                      value: '${entry.value} citas',
                      color: AppTheme.success,
                    );
                  }).toList(),
          ),
          const SizedBox(height: AppTheme.spacingLG),

          // Today's Appointments Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.todaysAppointments, style: AppTheme.textStyleH3),
              TextButton(
                onPressed: () => context.push('/appointments'),
                child: Text(l10n.viewAll),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD),
          if (todayAppointments.isEmpty)
            AppTheme.card(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: AppTheme.spacingMD),
                    Text(
                      l10n.noAppointmentsToday,
                      style: AppTheme.textStyleBody.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...todayAppointments
                .take(5)
                .map(
                  (appointment) => _AppointmentCard(
                    appointment: appointment,
                    onTap: () => context.push('/appointments'),
                  ),
                ),
          const SizedBox(height: AppTheme.spacingXL),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Buenos días';
    } else if (hour < 18) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppTheme.card(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            count.toString(),
            style: AppTheme.textStyleH1.copyWith(color: color, fontSize: 32),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            title,
            style: AppTheme.textStyleCaption.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;

  const _AppointmentCard({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusColor = _getStatusColor(appointment.status);

    return AppTheme.listTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(
          _getStatusIcon(appointment.status),
          color: statusColor,
          size: 20,
        ),
      ),
      title: appointment.customer?.name ?? l10n.customer,
      subtitle:
          '${appointment.service?.name ?? l10n.services} - ${appointment.startTime}',
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSM,
          vertical: AppTheme.spacingXS,
        ),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Text(
          appointment.status.toString().split('.').last.toUpperCase(),
          style: AppTheme.textStyleCaption.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: onTap,
    );
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

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.pending_outlined;
      case AppointmentStatus.confirmed:
        return Icons.check_circle_outline;
      case AppointmentStatus.cancelled:
        return Icons.cancel_outlined;
      case AppointmentStatus.completed:
        return Icons.done_all_outlined;
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTheme.card(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.textStyleBodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppTheme.card(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingXS),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                title,
                style: AppTheme.textStyleCaption.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            value,
            style: AppTheme.textStyleH1.copyWith(color: color, fontSize: 28),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTheme.textStyleCaption.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final double estimatedRevenue;

  const _RevenueCard({required this.estimatedRevenue});

  @override
  Widget build(BuildContext context) {
    final formattedRevenue = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    ).format(estimatedRevenue);

    return AppTheme.card(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXS),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      Icons.attach_money,
                      color: AppTheme.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Text(
                    'Ingresos estimados',
                    style: AppTheme.textStyleBodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                formattedRevenue,
                style: AppTheme.textStyleH1.copyWith(
                  color: AppTheme.success,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Este mes',
                style: AppTheme.textStyleCaption.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(Icons.trending_up, color: AppTheme.success, size: 32),
          ),
        ],
      ),
    );
  }
}

class _StatusDistributionChart extends StatelessWidget {
  final Map<AppointmentStatus, int> statusCounts;
  final int total;

  const _StatusDistributionChart({
    required this.statusCounts,
    required this.total,
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
  Widget build(BuildContext context) {
    if (total == 0) {
      return AppTheme.card(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Center(
          child: Text(
            'No hay datos para mostrar',
            style: AppTheme.textStyleBody.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }

    return AppTheme.card(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución de estados',
            style: AppTheme.textStyleH3.copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          ...AppointmentStatus.values.map((status) {
            final count = statusCounts[status] ?? 0;
            final percentage = total > 0 ? (count / total * 100) : 0.0;
            final color = _getStatusColor(status);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSM),
                          Text(
                            _getStatusLabel(status, context),
                            style: AppTheme.textStyleBodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$count (${percentage.toStringAsFixed(0)}%)',
                        style: AppTheme.textStyleBodySmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: AppTheme.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InsightCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppTheme.card(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.indigoMain, size: 20),
              const SizedBox(width: AppTheme.spacingSM),
              Text(title, style: AppTheme.textStyleH3.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD),
          ...children,
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InsightItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Text(
                    label,
                    style: AppTheme.textStyleBodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSM,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              value,
              style: AppTheme.textStyleCaption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/appointment_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';
import '../services/services_providers.dart';
import '../employees/employees_providers.dart';
import '../../core/models/service_models.dart';
import '../../core/models/employee_models.dart';
import 'appointments_calendar_view.dart';

class AppointmentsListView extends ConsumerStatefulWidget {
  final List<Appointment> appointments;
  final String businessId;

  const AppointmentsListView({
    super.key,
    required this.appointments,
    required this.businessId,
  });

  @override
  ConsumerState<AppointmentsListView> createState() =>
      _AppointmentsListViewState();
}

class _AppointmentsListViewState extends ConsumerState<AppointmentsListView> {
  Set<AppointmentStatus> _selectedStatuses = {
    AppointmentStatus.pending,
    AppointmentStatus.confirmed,
    AppointmentStatus.completed,
    AppointmentStatus.cancelled,
  };
  final Set<String> _selectedServiceIds = {};
  final Set<String> _selectedEmployeeIds = {};
  String _clientNameFilter = '';
  bool _showAdvancedFilters = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filteredAppointments = _getFilteredAppointments();
    final appointmentsByDate = _groupAppointmentsByDate(filteredAppointments);

    return Column(
      children: [
        // Filters Section
        AppTheme.card(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Name Filter with Filter Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l10n.searchByCustomerName,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _clientNameFilter.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _clientNameFilter = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          borderSide: BorderSide(color: AppTheme.borderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          borderSide: BorderSide(color: AppTheme.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          borderSide: BorderSide(color: AppTheme.indigoMain),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _clientNameFilter = value.toLowerCase().trim();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  IconButton(
                    icon: Icon(
                      _showAdvancedFilters
                          ? Icons.filter_list
                          : Icons.filter_list_outlined,
                    ),
                    color: _showAdvancedFilters
                        ? AppTheme.indigoMain
                        : AppTheme.textSecondary,
                    onPressed: () {
                      setState(() {
                        _showAdvancedFilters = !_showAdvancedFilters;
                      });
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: _showAdvancedFilters
                          ? AppTheme.indigoMain.withOpacity(0.1)
                          : AppTheme.cardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        side: BorderSide(
                          color: _showAdvancedFilters
                              ? AppTheme.indigoMain
                              : AppTheme.borderLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMD),
              // Status Filters
              Text(
                l10n.filterByStatus,
                style: AppTheme.textStyleBodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Wrap(
                spacing: AppTheme.spacingSM,
                runSpacing: AppTheme.spacingSM,
                children: [
                  // "All" filter chip
                  FilterChip(
                    selected:
                        _selectedStatuses.length ==
                        AppointmentStatus.values.length,
                    label: Text(l10n.all),
                    backgroundColor: AppTheme.cardBackground,
                    selectedColor: AppTheme.indigoMain,
                    labelStyle: AppTheme.textStyleBodySmall.copyWith(
                      color:
                          _selectedStatuses.length ==
                              AppointmentStatus.values.length
                          ? Colors.white
                          : AppTheme.textSecondary,
                      fontWeight:
                          _selectedStatuses.length ==
                              AppointmentStatus.values.length
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedStatuses = Set.from(
                            AppointmentStatus.values,
                          );
                        } else {
                          _selectedStatuses.clear();
                        }
                      });
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMD,
                      vertical: AppTheme.spacingSM,
                    ),
                    side: BorderSide(
                      color:
                          _selectedStatuses.length ==
                              AppointmentStatus.values.length
                          ? AppTheme.indigoMain
                          : AppTheme.borderLight,
                      width:
                          _selectedStatuses.length ==
                              AppointmentStatus.values.length
                          ? 2
                          : 1,
                    ),
                  ),
                  // Status filter chips
                  ...AppointmentStatus.values.map((status) {
                    final isSelected = _selectedStatuses.contains(status);
                    final statusLabel = _getStatusLabel(status, context);
                    // Don't show as selected if "All" is selected (all statuses are selected)
                    final isAllSelected =
                        _selectedStatuses.length ==
                        AppointmentStatus.values.length;
                    final showAsSelected = isSelected && !isAllSelected;

                    return FilterChip(
                      selected: showAsSelected,
                      label: Text(statusLabel),
                      backgroundColor: AppTheme.cardBackground,
                      selectedColor: AppTheme.indigoMain,
                      labelStyle: AppTheme.textStyleBodySmall.copyWith(
                        color: showAsSelected
                            ? Colors.white
                            : AppTheme.textSecondary,
                        fontWeight: showAsSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          final wasAllSelected =
                              _selectedStatuses.length ==
                              AppointmentStatus.values.length;

                          if (selected) {
                            // If "All" was selected and user clicks a specific status,
                            // deselect all and select only this one
                            if (wasAllSelected) {
                              _selectedStatuses = {status};
                            } else {
                              _selectedStatuses.add(status);
                              // If all statuses are now selected, keep them all selected
                              if (_selectedStatuses.length ==
                                  AppointmentStatus.values.length) {
                                // All are selected, which means "All" will be shown as selected
                              }
                            }
                          } else {
                            _selectedStatuses.remove(status);
                          }
                        });
                      },
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMD,
                        vertical: AppTheme.spacingSM,
                      ),
                      side: BorderSide(
                        color: showAsSelected
                            ? AppTheme.indigoMain
                            : AppTheme.borderLight,
                        width: showAsSelected ? 2 : 1,
                      ),
                    );
                  }),
                ],
              ),
              // Advanced Filters (only shown when _showAdvancedFilters is true)
              if (_showAdvancedFilters) ...[
                const SizedBox(height: AppTheme.spacingMD),
                // Date Filter
                Text(
                  l10n.date,
                  style: AppTheme.textStyleBodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() {
                              _startDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMD),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderLight),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: AppTheme.spacingSM),
                              Expanded(
                                child: Text(
                                  _startDate != null
                                      ? DateFormat(
                                          'dd/MM/yyyy',
                                          Localizations.localeOf(
                                            context,
                                          ).toString(),
                                        ).format(_startDate!)
                                      : l10n.selectDatePlaceholder,
                                  style: AppTheme.textStyleBodySmall.copyWith(
                                    color: _startDate != null
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSM),
                    Text(
                      '-',
                      style: AppTheme.textStyleBody.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSM),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() {
                              _endDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMD),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderLight),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: AppTheme.spacingSM),
                              Expanded(
                                child: Text(
                                  _endDate != null
                                      ? DateFormat(
                                          'dd/MM/yyyy',
                                          Localizations.localeOf(
                                            context,
                                          ).toString(),
                                        ).format(_endDate!)
                                      : l10n.selectDatePlaceholder,
                                  style: AppTheme.textStyleBodySmall.copyWith(
                                    color: _endDate != null
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_startDate != null || _endDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        color: AppTheme.textSecondary,
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMD),
                // Service Filters
                Text(
                  l10n.services,
                  style: AppTheme.textStyleBodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                FutureBuilder<List<Service>>(
                  future: ref.read(servicesProvider(widget.businessId).future),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final services = snapshot.data!;
                    if (services.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Wrap(
                      spacing: AppTheme.spacingSM,
                      runSpacing: AppTheme.spacingSM,
                      children: services.map((service) {
                        final isSelected = _selectedServiceIds.contains(
                          service.id,
                        );
                        return FilterChip(
                          selected: isSelected,
                          label: Text(service.name),
                          backgroundColor: AppTheme.cardBackground,
                          selectedColor: AppTheme.indigoMain,
                          labelStyle: AppTheme.textStyleBodySmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedServiceIds.add(service.id);
                              } else {
                                _selectedServiceIds.remove(service.id);
                              }
                            });
                          },
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMD,
                            vertical: AppTheme.spacingSM,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.indigoMain
                                : AppTheme.borderLight,
                            width: isSelected ? 2 : 1,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: AppTheme.spacingMD),
                // Employee Filters
                Text(
                  l10n.employees,
                  style: AppTheme.textStyleBodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                FutureBuilder<List<Employee>>(
                  future: ref.read(employeesProvider(widget.businessId).future),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final employees = snapshot.data!;
                    if (employees.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Wrap(
                      spacing: AppTheme.spacingSM,
                      runSpacing: AppTheme.spacingSM,
                      children: employees.map((employee) {
                        final isSelected = _selectedEmployeeIds.contains(
                          employee.id,
                        );
                        return FilterChip(
                          selected: isSelected,
                          label: Text(employee.name),
                          backgroundColor: AppTheme.cardBackground,
                          selectedColor: AppTheme.indigoMain,
                          labelStyle: AppTheme.textStyleBodySmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedEmployeeIds.add(employee.id);
                              } else {
                                _selectedEmployeeIds.remove(employee.id);
                              }
                            });
                          },
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMD,
                            vertical: AppTheme.spacingSM,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.indigoMain
                                : AppTheme.borderLight,
                            width: isSelected ? 2 : 1,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),
        // Appointments List
        Expanded(
          child: appointmentsByDate.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: AppTheme.spacingMD),
                      Text(
                        l10n.noItems,
                        style: AppTheme.textStyleBody.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  itemCount: appointmentsByDate.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppTheme.spacingMD),
                  itemBuilder: (context, index) {
                    final dateEntry = appointmentsByDate[index];
                    final date = dateEntry['date'] as DateTime;
                    final appointments =
                        dateEntry['appointments'] as List<Appointment>;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingMD,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: AppTheme.indigoMain,
                                  ),
                                  const SizedBox(width: AppTheme.spacingSM),
                                  Text(
                                    DateFormat(
                                          'EEEE, MMMM d',
                                          Localizations.localeOf(
                                            context,
                                          ).toString(),
                                        )
                                        .format(date)
                                        .split(' ')
                                        .map(
                                          (word) => word.isEmpty
                                              ? word
                                              : word[0].toUpperCase() +
                                                    word.substring(1),
                                        )
                                        .join(' '),
                                    style: AppTheme.textStyleH3.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: AppTheme.spacingSM),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingSM,
                                  vertical: AppTheme.spacingXS,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.indigoMain.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall,
                                  ),
                                ),
                                child: Text(
                                  '${appointments.length} ${appointments.length == 1 ? (l10n.appointments.toLowerCase()) : (l10n.appointments.toLowerCase())}',
                                  style: AppTheme.textStyleBodySmall.copyWith(
                                    color: AppTheme.indigoMain,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...appointments.map((appointment) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spacingMD,
                            ),
                            child: AppointmentCard(
                              appointment: appointment,
                              businessId: widget.businessId,
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<Appointment> _getFilteredAppointments() {
    return widget.appointments.where((apt) {
      // Status filter
      if (!_selectedStatuses.contains(apt.status)) {
        return false;
      }

      // Date filter
      if (_startDate != null || _endDate != null) {
        try {
          final aptDate = DateTime.parse(apt.date);
          final aptDateOnly = DateTime(
            aptDate.year,
            aptDate.month,
            aptDate.day,
          );

          if (_startDate != null) {
            final startDateOnly = DateTime(
              _startDate!.year,
              _startDate!.month,
              _startDate!.day,
            );
            if (aptDateOnly.isBefore(startDateOnly)) {
              return false;
            }
          }

          if (_endDate != null) {
            final endDateOnly = DateTime(
              _endDate!.year,
              _endDate!.month,
              _endDate!.day,
            );
            if (aptDateOnly.isAfter(endDateOnly)) {
              return false;
            }
          }
        } catch (e) {
          // Skip invalid dates
          return false;
        }
      }

      // Service filter
      if (_selectedServiceIds.isNotEmpty &&
          !_selectedServiceIds.contains(apt.serviceId)) {
        return false;
      }

      // Employee filter
      if (_selectedEmployeeIds.isNotEmpty &&
          !_selectedEmployeeIds.contains(apt.employeeId)) {
        return false;
      }

      // Client name filter
      if (_clientNameFilter.isNotEmpty) {
        final customerName = apt.customer?.name.toLowerCase() ?? '';
        if (!customerName.contains(_clientNameFilter)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _groupAppointmentsByDate(
    List<Appointment> appointments,
  ) {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final appointment in appointments) {
      try {
        final date = DateTime.parse(appointment.date);
        final dateOnly = DateTime(date.year, date.month, date.day);
        final dateKey = DateFormat('yyyy-MM-dd').format(dateOnly);

        if (grouped.containsKey(dateKey)) {
          (grouped[dateKey]!['appointments'] as List<Appointment>).add(
            appointment,
          );
        } else {
          grouped[dateKey] = {
            'date': dateOnly,
            'appointments': <Appointment>[appointment],
          };
        }
      } catch (e) {
        continue;
      }
    }

    // Sort by date (newest first) and sort appointments within each date by time
    final sortedEntries = grouped.values.toList();
    sortedEntries.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return dateB.compareTo(dateA);
    });

    // Sort appointments within each date by start time
    for (final entry in sortedEntries) {
      final appointments = entry['appointments'] as List<Appointment>;
      appointments.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return sortedEntries;
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
}

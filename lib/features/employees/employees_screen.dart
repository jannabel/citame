import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupertino_modal_sheet/cupertino_modal_sheet.dart';
import '../auth/auth_providers.dart';
import 'employees_providers.dart';
import '../services/services_providers.dart';
import '../../core/models/employee_models.dart';
import 'employee_form_dialog.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  String _nameFilter = '';
  Set<bool> _selectedStatuses = {
    true,
    false,
  }; // Both active and inactive by default

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final businessId = authState.businessId;
    final l10n = context.l10n;

    if (businessId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final employeesAsync = ref.watch(employeesProvider(businessId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        title: Text(l10n.employees),
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
      ),
      body: employeesAsync.when(
        data: (employees) {
          final filteredEmployees = _getFilteredEmployees(employees);
          return Column(
            children: [
              // Filters Section
              AppTheme.card(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMD,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Filter
                    TextField(
                      decoration: InputDecoration(
                        hintText: l10n.searchByEmployeeName,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _nameFilter.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _nameFilter = '';
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
                          _nameFilter = value.toLowerCase().trim();
                        });
                      },
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
                          selected: _selectedStatuses.length == 2,
                          label: Text(l10n.all),
                          backgroundColor: AppTheme.cardBackground,
                          selectedColor: AppTheme.indigoMain,
                          labelStyle: AppTheme.textStyleBodySmall.copyWith(
                            color: _selectedStatuses.length == 2
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight: _selectedStatuses.length == 2
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedStatuses = {true, false};
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
                            color: _selectedStatuses.length == 2
                                ? AppTheme.indigoMain
                                : AppTheme.borderLight,
                            width: _selectedStatuses.length == 2 ? 2 : 1,
                          ),
                        ),
                        // Active filter chip
                        FilterChip(
                          selected:
                              _selectedStatuses.contains(true) &&
                              _selectedStatuses.length != 2,
                          label: Text(l10n.active),
                          backgroundColor: AppTheme.cardBackground,
                          selectedColor: AppTheme.indigoMain,
                          labelStyle: AppTheme.textStyleBodySmall.copyWith(
                            color:
                                _selectedStatuses.contains(true) &&
                                    _selectedStatuses.length != 2
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight:
                                _selectedStatuses.contains(true) &&
                                    _selectedStatuses.length != 2
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                // If both are currently selected (All), remove false to show only Active
                                if (_selectedStatuses.length == 2) {
                                  _selectedStatuses = {true};
                                } else {
                                  _selectedStatuses.add(true);
                                  // If both are now selected, that's fine (equivalent to All)
                                  if (_selectedStatuses.length == 2) {
                                    _selectedStatuses = {true, false};
                                  }
                                }
                              } else {
                                _selectedStatuses.remove(true);
                                // If none are selected, select both (can't have empty filter)
                                if (_selectedStatuses.isEmpty) {
                                  _selectedStatuses = {true, false};
                                }
                              }
                            });
                          },
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMD,
                            vertical: AppTheme.spacingSM,
                          ),
                          side: BorderSide(
                            color:
                                _selectedStatuses.contains(true) &&
                                    _selectedStatuses.length != 2
                                ? AppTheme.indigoMain
                                : AppTheme.borderLight,
                            width:
                                _selectedStatuses.contains(true) &&
                                    _selectedStatuses.length != 2
                                ? 2
                                : 1,
                          ),
                        ),
                        // Inactive filter chip
                        FilterChip(
                          selected:
                              _selectedStatuses.contains(false) &&
                              _selectedStatuses.length != 2,
                          label: Text(l10n.inactive),
                          backgroundColor: AppTheme.cardBackground,
                          selectedColor: AppTheme.indigoMain,
                          labelStyle: AppTheme.textStyleBodySmall.copyWith(
                            color:
                                _selectedStatuses.contains(false) &&
                                    _selectedStatuses.length != 2
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight:
                                _selectedStatuses.contains(false) &&
                                    _selectedStatuses.length != 2
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                // If both are currently selected (All), remove true to show only Inactive
                                if (_selectedStatuses.length == 2) {
                                  _selectedStatuses = {false};
                                } else {
                                  _selectedStatuses.add(false);
                                  // If both are now selected, that's fine (equivalent to All)
                                  if (_selectedStatuses.length == 2) {
                                    _selectedStatuses = {true, false};
                                  }
                                }
                              } else {
                                _selectedStatuses.remove(false);
                                // If none are selected, select both (can't have empty filter)
                                if (_selectedStatuses.isEmpty) {
                                  _selectedStatuses = {true, false};
                                }
                              }
                            });
                          },
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMD,
                            vertical: AppTheme.spacingSM,
                          ),
                          side: BorderSide(
                            color:
                                _selectedStatuses.contains(false) &&
                                    _selectedStatuses.length != 2
                                ? AppTheme.indigoMain
                                : AppTheme.borderLight,
                            width:
                                _selectedStatuses.contains(false) &&
                                    _selectedStatuses.length != 2
                                ? 2
                                : 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMD),
              // Employees List
              Expanded(
                child: filteredEmployees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
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
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMD,
                        ),
                        itemCount: filteredEmployees.length,
                        itemBuilder: (context, index) {
                          final employee = filteredEmployees[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spacingMD,
                            ),
                            child: _EmployeeCard(
                              employee: employee,
                              businessId: businessId,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            '${l10n.error}: $error',
            style: AppTheme.textStyleBody.copyWith(color: AppTheme.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'employees_fab',
        onPressed: () => _showAddEmployeeDialog(context, ref, businessId),
        backgroundColor: AppTheme.indigoMain,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Employee> _getFilteredEmployees(List<Employee> employees) {
    return employees.where((employee) {
      // Name filter
      if (_nameFilter.isNotEmpty) {
        final employeeName = employee.name.toLowerCase();
        if (!employeeName.contains(_nameFilter)) {
          return false;
        }
      }

      // Status filter
      if (!_selectedStatuses.contains(employee.active)) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _showAddEmployeeDialog(
    BuildContext context,
    WidgetRef ref,
    String businessId,
  ) async {
    await showCupertinoModalSheet(
      context: context,
      builder: (context) => EmployeeFormDialog(businessId: businessId),
    );
    if (context.mounted) {
      ref.invalidate(employeesProvider(businessId));
    }
  }
}

class _EmployeeCard extends ConsumerWidget {
  final Employee employee;
  final String businessId;

  const _EmployeeCard({required this.employee, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AppTheme.listTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: employee.photoUrl != null
            ? NetworkImage(employee.photoUrl!)
            : null,
        backgroundColor: AppTheme.indigoMain.withOpacity(0.1),
        child: employee.photoUrl == null
            ? Text(
                employee.name[0].toUpperCase(),
                style: AppTheme.textStyleBody.copyWith(
                  color: AppTheme.indigoMain,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      title: employee.name,
      subtitle: employee.active ? l10n.active : l10n.inactive,

      trailing: PopupMenuButton(
        icon: Icon(Icons.more_vert_outlined, color: AppTheme.textSecondary),
        itemBuilder: (context) => [
          PopupMenuItem(
            child: Text(employee.active ? l10n.deactivate : l10n.activate),
            onTap: () {
              ref.read(employeesNotifierProvider.notifier).updateEmployee(
                employee.id,
                {'active': !employee.active},
                businessId,
              );
              Future.delayed(const Duration(milliseconds: 300), () {
                ref.invalidate(employeesProvider(businessId));
              });
            },
          ),
          PopupMenuItem(child: Text(l10n.edit)),
          const PopupMenuItem(
            child: Text('Manage Services'),
          ), // TODO: Add to l10n
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmployeeDetailsScreen(
              employee: employee,
              businessId: businessId,
            ),
          ),
        );
      },
    );
  }
}

class EmployeeDetailsScreen extends ConsumerWidget {
  final Employee employee;
  final String businessId;

  const EmployeeDetailsScreen({
    super.key,
    required this.employee,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider(businessId));
    final employeesAsync = ref.watch(employeesProvider(businessId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        title: Text(employee.name),
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
      ),
      body: employeesAsync.when(
        data: (employees) {
          // Get the current employee data from the provider to reflect service assignments
          final currentEmployee = employees.firstWhere(
            (e) => e.id == employee.id,
            orElse: () => employee,
          );

          return servicesAsync.when(
            data: (services) {
              // Filter to show only active services
              final activeServices = services.where((s) => s.active).toList();

              print('[EmployeeDetails] Total services: ${services.length}');
              print(
                '[EmployeeDetails] Active services: ${activeServices.length}',
              );
              print(
                '[EmployeeDetails] Current employee serviceIds: ${currentEmployee.serviceIds}',
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.indigoMain.withOpacity(0.1),
                        backgroundImage: currentEmployee.photoUrl != null
                            ? NetworkImage(currentEmployee.photoUrl!)
                            : null,
                        child: currentEmployee.photoUrl == null
                            ? Text(
                                currentEmployee.name[0].toUpperCase(),
                                style: AppTheme.textStyleH1.copyWith(
                                  fontSize: 40,
                                  color: AppTheme.indigoMain,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLG),
                    AppTheme.card(
                      padding: const EdgeInsets.all(AppTheme.spacingMD),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Servicios Asignados',
                            style: AppTheme.textStyleH3,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMD,
                              vertical: AppTheme.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.indigoMain.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSmall,
                              ),
                            ),
                            child: Text(
                              '${currentEmployee.serviceIds.length}/${activeServices.length}',
                              style: AppTheme.textStyleBodySmall.copyWith(
                                color: AppTheme.indigoMain,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMD),
                    if (activeServices.isEmpty)
                      AppTheme.card(
                        padding: const EdgeInsets.all(AppTheme.spacingLG),
                        child: Center(
                          child: Text(
                            'No hay servicios disponibles',
                            style: AppTheme.textStyleBody.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ...activeServices.map((service) {
                        final isAssigned = currentEmployee.serviceIds.contains(
                          service.id,
                        );
                        print(
                          '[EmployeeDetails] Service ${service.name} (${service.id}) is ${isAssigned ? "assigned" : "not assigned"}',
                        );
                        print(
                          '[EmployeeDetails] Current serviceIds: ${currentEmployee.serviceIds}',
                        );

                        return AppTheme.card(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMD,
                            vertical: AppTheme.spacingSM,
                          ),
                          margin: const EdgeInsets.only(
                            bottom: AppTheme.spacingSM,
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              service.name,
                              style: AppTheme.textStyleBody,
                            ),
                            subtitle: Text(
                              '${service.durationMinutes} min • \$${service.price}',
                              style: AppTheme.textStyleCaption,
                            ),
                            value: isAssigned,
                            activeColor: AppTheme.indigoMain,
                            onChanged: (value) async {
                              print(
                                '[EmployeeDetails] Checkbox changed for ${service.name} to $value',
                              );
                              try {
                                if (value == true) {
                                  print(
                                    '[EmployeeDetails] Assigning service ${service.id} to employee ${employee.id}',
                                  );
                                  await ref
                                      .read(employeesNotifierProvider.notifier)
                                      .assignService(
                                        employee.id,
                                        service.id,
                                        businessId,
                                      );
                                } else {
                                  print(
                                    '[EmployeeDetails] Unassigning service ${service.id} from employee ${employee.id}',
                                  );
                                  await ref
                                      .read(employeesNotifierProvider.notifier)
                                      .unassignService(
                                        employee.id,
                                        service.id,
                                        businessId,
                                      );
                                }
                                // Wait a bit for the API to process
                                await Future.delayed(
                                  const Duration(milliseconds: 300),
                                );

                                // Refresh employees to get updated service assignments
                                print(
                                  '[EmployeeDetails] Invalidating employees provider',
                                );
                                ref.invalidate(employeesProvider(businessId));

                                // Also refresh services to ensure they're up to date
                                ref.invalidate(servicesProvider(businessId));

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        value == true
                                            ? 'Servicio asignado exitosamente'
                                            : 'Servicio desasignado exitosamente',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('[EmployeeDetails] Error: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error al ${value == true ? "asignar" : "desasignar"} servicio: ${e.toString().replaceAll('Exception: ', '')}',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                // Refresh anyway to sync state
                                ref.invalidate(employeesProvider(businessId));
                                ref.invalidate(servicesProvider(businessId));
                              }
                            },
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Error loading services: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading employee: $error')),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupertino_modal_sheet/cupertino_modal_sheet.dart';
import '../auth/auth_providers.dart';
import 'services_providers.dart';
import '../../core/models/service_models.dart';
import 'service_form_dialog.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
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

    final servicesAsync = ref.watch(servicesProvider(businessId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        title: Text(l10n.services),
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
      ),
      body: servicesAsync.when(
        data: (services) {
          final filteredServices = _getFilteredServices(services);
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
                        hintText: l10n.searchByServiceName,
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
              // Services List
              Expanded(
                child: filteredServices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.content_cut_outlined,
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
                        itemCount: filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = filteredServices[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spacingMD,
                            ),
                            child: _ServiceCard(
                              service: service,
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
        heroTag: 'services_fab',
        onPressed: () => _showAddServiceDialog(context, ref, businessId),
        backgroundColor: AppTheme.indigoMain,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Service> _getFilteredServices(List<Service> services) {
    return services.where((service) {
      // Name filter
      if (_nameFilter.isNotEmpty) {
        final serviceName = service.name.toLowerCase();
        if (!serviceName.contains(_nameFilter)) {
          return false;
        }
      }

      // Status filter
      if (!_selectedStatuses.contains(service.active)) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _showAddServiceDialog(
    BuildContext context,
    WidgetRef ref,
    String businessId,
  ) async {
    await showCupertinoModalSheet(
      context: context,
      builder: (context) => ServiceFormDialog(businessId: businessId),
    );
    if (context.mounted) {
      ref.invalidate(servicesProvider(businessId));
    }
  }
}

class _ServiceCard extends ConsumerWidget {
  final Service service;
  final String businessId;

  const _ServiceCard({required this.service, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statusColor = service.active
        ? AppTheme.success
        : AppTheme.textSecondary;
    return AppTheme.listTile(
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.spacingSM),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Icon(
          service.active ? Icons.check_circle_outline : Icons.block_outlined,
          color: statusColor,
          size: 24,
        ),
      ),
      title: service.name,
      subtitle: service.description,

      trailing: PopupMenuButton(
        icon: Icon(Icons.more_vert_outlined, color: AppTheme.textSecondary),
        itemBuilder: (context) => [
          PopupMenuItem(
            child: Text(service.active ? l10n.deactivate : l10n.activate),
            onTap: () {
              ref.read(servicesNotifierProvider.notifier).updateService(
                service.id,
                {'active': !service.active},
                businessId,
              );
              Future.delayed(const Duration(milliseconds: 300), () {
                ref.invalidate(servicesProvider(businessId));
              });
            },
          ),
          PopupMenuItem(child: Text(l10n.edit)),
        ],
      ),
    );
  }
}

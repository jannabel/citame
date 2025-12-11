import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services_providers.dart';
import '../../core/models/service_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class ServiceFormDialog extends ConsumerStatefulWidget {
  final String businessId;
  final Service? service;

  const ServiceFormDialog({super.key, required this.businessId, this.service});

  @override
  ConsumerState<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends ConsumerState<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late TextEditingController _priceController;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.service?.description ?? '',
    );
    _durationController = TextEditingController(
      text: widget.service?.durationMinutes.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.service?.price.toString() ?? '',
    );
    _active = widget.service?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (_formKey.currentState!.validate()) {
      final service = Service(
        id: widget.service?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        durationMinutes: int.parse(_durationController.text),
        price: double.parse(_priceController.text),
        active: _active,
      );

      if (widget.service != null) {
        await ref
            .read(servicesNotifierProvider.notifier)
            .updateService(service.id, {
              'name': service.name,
              'description': service.description,
              'durationMinutes': service.durationMinutes,
              'price': service.price,
              'active': service.active,
            }, widget.businessId);
      } else {
        await ref
            .read(servicesNotifierProvider.notifier)
            .createService(widget.businessId, service);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.cardBackground,
        appBar: AppBar(
          title: Text(
            widget.service != null ? l10n.editService : l10n.addService,
            style: AppTheme.textStyleH2,
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: Row(
            children: [
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                flex: 2,
                child: AppTheme.primaryButton(
                  text: l10n.save,
                  onPressed: _saveService,
                ),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.name,
                      filled: true,
                      fillColor: AppTheme.indigoMain.withOpacity(0.04),
                    ),
                    style: AppTheme.textStyleBody,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterServiceName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: l10n.descriptionOptional,
                      filled: true,
                      fillColor: AppTheme.indigoMain.withOpacity(0.04),
                    ),
                    style: AppTheme.textStyleBody,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: l10n.durationMinutes,
                      filled: true,
                      fillColor: AppTheme.indigoMain.withOpacity(0.04),
                    ),
                    style: AppTheme.textStyleBody,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterDuration;
                      }
                      if (int.tryParse(value) == null) {
                        return l10n.pleaseEnterValidNumber;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: l10n.price,
                      prefixText: '\$',
                      filled: true,
                      fillColor: AppTheme.indigoMain.withOpacity(0.04),
                    ),
                    style: AppTheme.textStyleBody,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterPrice;
                      }
                      if (double.tryParse(value) == null) {
                        return l10n.pleaseEnterValidNumber;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.indigoMain.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: SwitchListTile(
                      title: Text(l10n.active, style: AppTheme.textStyleBody),
                      value: _active,
                      activeThumbColor: AppTheme.indigoMain,
                      onChanged: (value) => setState(() => _active = value),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLG),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

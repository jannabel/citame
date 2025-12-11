import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'employees_providers.dart';
import '../../core/models/employee_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class EmployeeFormDialog extends ConsumerStatefulWidget {
  final String businessId;
  final Employee? employee;

  const EmployeeFormDialog({
    super.key,
    required this.businessId,
    this.employee,
  });

  @override
  ConsumerState<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends ConsumerState<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late bool _active;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name ?? '');
    _active = widget.employee?.active ?? true;
    _photoUrl = widget.employee?.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // In a real app, you would upload the image to a server
      setState(() {
        _photoUrl = image.path;
      });
    }
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      final employee = Employee(
        id: widget.employee?.id ?? '',
        name: _nameController.text.trim(),
        photoUrl: _photoUrl,
        active: _active,
      );

      if (widget.employee != null) {
        await ref
            .read(employeesNotifierProvider.notifier)
            .updateEmployee(employee.id, {
              'name': employee.name,
              'photoUrl': employee.photoUrl,
              'active': employee.active,
            }, widget.businessId);
      } else {
        await ref
            .read(employeesNotifierProvider.notifier)
            .createEmployee(widget.businessId, employee);
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
            widget.employee != null ? l10n.editEmployee : l10n.addEmployee,
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
                  onPressed: _saveEmployee,
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
                  Center(
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.indigoMain.withOpacity(0.04),
                        backgroundImage:
                            _photoUrl != null && !_photoUrl!.startsWith('http')
                            ? null
                            : _photoUrl != null
                            ? NetworkImage(_photoUrl!)
                            : null,
                        child:
                            _photoUrl != null && !_photoUrl!.startsWith('http')
                            ? Icon(
                                Icons.person_outline,
                                size: 50,
                                color: AppTheme.indigoMain,
                              )
                            : _photoUrl == null
                            ? Icon(
                                Icons.add_a_photo_outlined,
                                size: 50,
                                color: AppTheme.indigoMain,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLG),
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
                        return l10n.pleaseEnterEmployeeName;
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

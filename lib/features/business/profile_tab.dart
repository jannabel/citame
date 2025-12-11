import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'business_providers.dart';
import '../auth/auth_providers.dart';
import '../../core/models/business_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class ProfileTab extends ConsumerStatefulWidget {
  final Business business;

  const ProfileTab({super.key, required this.business});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _timezoneController;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business.name);
    _descriptionController = TextEditingController(
      text: widget.business.description ?? '',
    );
    _phoneController = TextEditingController(text: widget.business.phone ?? '');
    _addressController = TextEditingController(
      text: widget.business.address ?? '',
    );
    _timezoneController = TextEditingController(text: widget.business.timezone);
    _logoUrl = widget.business.logoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      // In a real app, you would upload the file to a server
      setState(() {
        _logoUrl = result.files.single.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authState = ref.read(authStateProvider);
      final businessId = authState.businessId;

      if (businessId == null) return;

      final updates = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'timezone': _timezoneController.text.trim(),
        if (_logoUrl != null) 'logoUrl': _logoUrl,
      };

      await ref
          .read(businessNotifierProvider.notifier)
          .updateBusiness(businessId, updates);

      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileUpdatedSuccessfully)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _logoUrl != null
                        ? _logoUrl!.startsWith('http')
                              ? NetworkImage(_logoUrl!)
                              : null
                        : null,
                    child: _logoUrl == null || !_logoUrl!.startsWith('http')
                        ? const Icon(Icons.business, size: 60)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.indigoMain,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20),
                        color: Colors.white,
                        onPressed: _pickLogo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.businessName,
                filled: true,
                fillColor: AppTheme.indigoMain.withOpacity(0.04),
              ),
              style: AppTheme.textStyleBody,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.pleaseEnterBusinessName;
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMD),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.description,
                filled: true,
                fillColor: AppTheme.indigoMain.withOpacity(0.04),
              ),
              style: AppTheme.textStyleBody,
              maxLines: 3,
            ),
            const SizedBox(height: AppTheme.spacingMD),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: l10n.phone,
                filled: true,
                fillColor: AppTheme.indigoMain.withOpacity(0.04),
              ),
              style: AppTheme.textStyleBody,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppTheme.spacingMD),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: l10n.address,
                filled: true,
                fillColor: AppTheme.indigoMain.withOpacity(0.04),
              ),
              style: AppTheme.textStyleBody,
              maxLines: 2,
            ),
            const SizedBox(height: AppTheme.spacingMD),
            TextFormField(
              controller: _timezoneController,
              decoration: InputDecoration(
                labelText: l10n.timezone,
                helperText: l10n.timezoneHelper,
                filled: true,
                fillColor: AppTheme.indigoMain.withOpacity(0.04),
              ),
              style: AppTheme.textStyleBody,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.pleaseEnterTimezone;
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingXL),
            AppTheme.primaryButton(
              text: l10n.saveProfile,
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );
  }
}

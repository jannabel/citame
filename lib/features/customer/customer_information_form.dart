import 'package:flutter/material.dart';
import '../../core/models/customer_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class CustomerInformationForm extends StatefulWidget {
  final Customer? initialCustomer;

  const CustomerInformationForm({
    super.key,
    this.initialCustomer,
  });

  @override
  State<CustomerInformationForm> createState() => _CustomerInformationFormState();
}

class _CustomerInformationFormState extends State<CustomerInformationForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCustomer?.name ?? '');
    _phoneController = TextEditingController(text: widget.initialCustomer?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu información',
              style: AppTheme.textStyleH2,
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.customerName,
                      hintText: l10n.enterCustomerName,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterCustomerName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: l10n.customerPhone,
                      hintText: l10n.enterCustomerPhone,
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterCustomerPhone;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingLG),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: AppTheme.spacingSM),
                      ElevatedButton(
                        onPressed: _save,
                        child: Text(l10n.save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final customer = Customer(
        id: widget.initialCustomer?.id ?? '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      Navigator.of(context).pop(customer);
    }
  }
}


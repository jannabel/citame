import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'business_providers.dart';
import '../auth/auth_providers.dart';
import '../../core/models/business_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class DepositsTab extends ConsumerStatefulWidget {
  final Business business;

  const DepositsTab({super.key, required this.business});

  @override
  ConsumerState<DepositsTab> createState() => _DepositsTabState();
}

class _DepositsTabState extends ConsumerState<DepositsTab> {
  late bool _requiresDeposit;
  late DepositType? _depositType;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _requiresDeposit = widget.business.requiresDeposit;
    _depositType = widget.business.depositType;
    _amountController = TextEditingController(
      text: widget.business.depositAmount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveDepositSettings() async {
    final authState = ref.read(authStateProvider);
    final businessId = authState.businessId;

    if (businessId == null) return;

    final updates = <String, dynamic>{
      'requiresDeposit': _requiresDeposit,
      if (_requiresDeposit) ...{
        'depositType': _depositType?.toString(),
        'depositAmount': _amountController.text.isNotEmpty
            ? double.tryParse(_amountController.text)
            : null,
      },
    };

    await ref
        .read(businessNotifierProvider.notifier)
        .updateBusiness(businessId, updates);

    if (mounted) {
      final l10n = context.l10n;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.depositSettingsUpdated)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.indigoMain.withOpacity(0.04),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: SwitchListTile(
              title: Text(
                l10n.requiresDeposit,
                style: AppTheme.textStyleBody.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                l10n.enableDepositRequirement,
                style: AppTheme.textStyleBodySmall,
              ),
              value: _requiresDeposit,
              onChanged: (value) => setState(() => _requiresDeposit = value),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLG),
          if (_requiresDeposit) ...[
            DropdownButtonFormField<DepositType>(
              initialValue: _depositType,
              decoration: InputDecoration(
                labelText: l10n.depositType,
                filled: true,
                fillColor: AppTheme.indigoMain.withOpacity(0.04),
              ),
              style: AppTheme.textStyleBody,
              items: [
                DropdownMenuItem(
                  value: DepositType.fixed,
                  child: Text(l10n.fixedAmount),
                ),
                DropdownMenuItem(
                  value: DepositType.percentage,
                  child: Text(l10n.percentage),
                ),
              ],
              onChanged: (value) => setState(() => _depositType = value),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: _depositType == DepositType.percentage
                    ? l10n.percentageLabel
                    : l10n.amount,
                helperText: _depositType == DepositType.percentage
                    ? l10n.enterPercentage
                    : l10n.enterFixedAmount,
                filled: true,
                fillColor: AppTheme.indigoMain.withOpacity(0.04),
              ),
              style: AppTheme.textStyleBody,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_requiresDeposit && (value == null || value.isEmpty)) {
                  return l10n.pleaseEnterValue;
                }
                if (value != null && value.isNotEmpty) {
                  final num = double.tryParse(value);
                  if (num == null) {
                    return l10n.pleaseEnterValidNumber;
                  }
                  if (_depositType == DepositType.percentage &&
                      (num < 0 || num > 100)) {
                    return l10n.percentageMustBeBetween;
                  }
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: AppTheme.spacingXL),
          AppTheme.primaryButton(
            text: l10n.saveSettings,
            onPressed: _saveDepositSettings,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class SettingsOptionsList extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onOptionSelected;

  const SettingsOptionsList({
    super.key,
    required this.selectedIndex,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final options = [
      {'label': l10n.profile, 'icon': Icons.person_outline},
      {'label': l10n.workingHours, 'icon': Icons.access_time_outlined},
      {'label': l10n.exceptions, 'icon': Icons.event_busy_outlined},
      {'label': l10n.deposits, 'icon': Icons.payment_outlined},
    ];

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = selectedIndex == index;

          return InkWell(
            onTap: () => onOptionSelected(index),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMD,
                vertical: AppTheme.spacingLG,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: index < options.length - 1
                        ? AppTheme.borderLight
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSM),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.indigoMain.withOpacity(0.1)
                          : AppTheme.backgroundMain,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      option['icon'] as IconData,
                      color: isSelected
                          ? AppTheme.indigoMain
                          : AppTheme.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Text(
                      option['label'] as String,
                      style: AppTheme.textStyleBody.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? AppTheme.indigoMain
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.indigoMain,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

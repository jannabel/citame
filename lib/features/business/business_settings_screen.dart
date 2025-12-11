import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class BusinessSettingsScreen extends ConsumerWidget {
  const BusinessSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final options = [
      {
        'label': l10n.profile,
        'icon': Icons.person_outline,
        'route': '/settings/profile',
        'description': l10n.profileDescription,
      },
      {
        'label': l10n.workingHours,
        'icon': Icons.access_time_outlined,
        'route': '/settings/working-hours',
        'description': l10n.workingHoursDescription,
      },
      {
        'label': l10n.exceptions,
        'icon': Icons.event_busy_outlined,
        'route': '/settings/exceptions',
        'description': l10n.exceptionsDescription,
      },
      {
        'label': l10n.deposits,
        'icon': Icons.payment_outlined,
        'route': '/settings/deposits',
        'description': l10n.depositsDescription,
      },
      {
        'label': 'Subscription',
        'icon': Icons.star_outline,
        'route': '/subscription/plans',
        'description': 'Manage your subscription plan',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        title: Text(l10n.businessSettings),
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            color: AppTheme.textPrimary,
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
            child: AppTheme.card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMD,
                  vertical: AppTheme.spacingSM,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSM),
                  decoration: BoxDecoration(
                    color: AppTheme.indigoMain.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    option['icon'] as IconData,
                    color: AppTheme.indigoMain,
                    size: 24,
                  ),
                ),
                title: Text(
                  option['label'] as String,
                  style: AppTheme.textStyleBody.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  option['description'] as String,
                  style: AppTheme.textStyleBodySmall,
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
                onTap: () {
                  context.push(option['route'] as String);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

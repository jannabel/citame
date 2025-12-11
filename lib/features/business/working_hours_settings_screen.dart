import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_providers.dart';
import 'working_hours_tab.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class WorkingHoursSettingsScreen extends ConsumerWidget {
  const WorkingHoursSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final businessId = authState.businessId;
    final l10n = context.l10n;

    if (businessId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        title: Text(l10n.workingHours),
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
      ),
      body: WorkingHoursTab(businessId: businessId),
    );
  }
}

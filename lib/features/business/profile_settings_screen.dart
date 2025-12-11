import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_providers.dart';
import 'business_providers.dart';
import 'profile_tab.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final businessId = authState.businessId;
    final l10n = context.l10n;

    if (businessId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final businessAsync = ref.watch(businessProvider(businessId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        title: Text(l10n.profile),
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
      ),
      body: businessAsync.when(
        data: (business) => ProfileTab(business: business),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
      ),
    );
  }
}

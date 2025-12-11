import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/subscription_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';
import '../auth/auth_providers.dart';
import 'subscription_providers.dart';

/// Widget to display subscription status and provide quick access to subscription management
class SubscriptionStatusWidget extends ConsumerWidget {
  const SubscriptionStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final businessId = authState.businessId;

    if (businessId == null) {
      return const SizedBox.shrink();
    }

    final subscriptionAsync = ref.watch(subscriptionProvider(businessId));

    return subscriptionAsync.when(
      data: (subscription) {
        if (subscription == null) {
          return AppTheme.card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.warning,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacingSM),
                      Text(
                        context.l10n.noSubscription,
                        style: AppTheme.textStyleBody.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  Text(
                    context.l10n.subscribeToAccessPremium,
                    style: AppTheme.textStyleBodySmall,
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/subscription/plans'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.indigoMain,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(context.l10n.viewPlans),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final statusColor = subscription.status.isActive
            ? AppTheme.success
            : subscription.status == SubscriptionStatus.expired
                ? AppTheme.error
                : AppTheme.warning;

        return AppTheme.card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSM),
                        Text(
                          subscription.plan?.name ?? context.l10n.noPlan,
                          style: AppTheme.textStyleBody.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      subscription.status.toString(),
                      style: AppTheme.textStyleBodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (subscription.status == SubscriptionStatus.trial &&
                    subscription.trialDaysRemaining != null) ...[
                  const SizedBox(height: AppTheme.spacingSM),
                  Text(
                    context.l10n.daysRemainingInTrial(subscription.trialDaysRemaining!),
                    style: AppTheme.textStyleBodySmall,
                  ),
                ],
                if (subscription.currentPeriodEnd != null &&
                    subscription.status == SubscriptionStatus.active) ...[
                  const SizedBox(height: AppTheme.spacingSM),
                  Text(
                    context.l10n.renewsOn(_formatDate(subscription.currentPeriodEnd!)),
                    style: AppTheme.textStyleBodySmall,
                  ),
                ],
                const SizedBox(height: AppTheme.spacingMD),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/subscription/plans'),
                    child: Text(context.l10n.manageSubscription),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => AppTheme.card(
        child: const Padding(
          padding: EdgeInsets.all(AppTheme.spacingMD),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => AppTheme.card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.error,
                size: 32,
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                context.l10n.errorLoadingSubscription,
                style: AppTheme.textStyleBodySmall,
              ),
              const SizedBox(height: AppTheme.spacingMD),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(subscriptionProvider(businessId));
                },
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}


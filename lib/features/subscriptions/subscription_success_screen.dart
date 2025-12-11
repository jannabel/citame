import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_providers.dart';
import 'subscription_providers.dart';

class SubscriptionSuccessScreen extends ConsumerStatefulWidget {
  const SubscriptionSuccessScreen({super.key});

  @override
  ConsumerState<SubscriptionSuccessScreen> createState() =>
      _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState
    extends ConsumerState<SubscriptionSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh subscription status after a short delay to allow webhook processing
    Future.delayed(const Duration(seconds: 2), () {
      final authState = ref.read(authStateProvider);
      final businessId = authState.businessId;
      if (businessId != null) {
        ref.invalidate(subscriptionProvider(businessId));
        ref.invalidate(currentSubscriptionProvider);
        ref.read(currentSubscriptionNotifierProvider.notifier).refreshSubscription();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final businessId = authState.businessId;
    final subscriptionAsync = businessId != null
        ? ref.watch(subscriptionProvider(businessId))
        : null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              Text(
                'Subscription Successful!',
                style: AppTheme.textStyleH1.copyWith(
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingMD),
              Text(
                'Your subscription has been activated. You can now access all premium features.',
                style: AppTheme.textStyleBody,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXL),
              if (subscriptionAsync != null)
                subscriptionAsync.when(
                  data: (subscription) {
                    if (subscription != null) {
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
                                    color: AppTheme.indigoMain,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppTheme.spacingSM),
                                  Text(
                                    'Subscription Details',
                                    style: AppTheme.textStyleBody.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingMD),
                              _buildDetailRow(
                                'Plan',
                                subscription.plan?.name ?? 'N/A',
                              ),
                              _buildDetailRow(
                                'Status',
                                subscription.status.toString(),
                              ),
                              if (subscription.currentPeriodEnd != null)
                                _buildDetailRow(
                                  'Renews on',
                                  _formatDate(subscription.currentPeriodEnd!),
                                ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              const SizedBox(height: AppTheme.spacingXL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.indigoMain,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingMD,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Go to Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.textStyleBodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTheme.textStyleBodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}


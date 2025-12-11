import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/customer_models.dart';
import '../../core/providers/api_providers.dart';

final customerProvider = FutureProvider.family<Customer, String>((
  ref,
  customerId,
) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getCustomer(customerId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/billing_models.dart';
import 'data/billing_repository.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) => throw UnimplementedError());
final billingStatusProvider = FutureProvider<BillingStatus>((ref) => ref.read(billingRepositoryProvider).getBillingStatus());
final billingPlansProvider = FutureProvider<List<BillingPlan>>((ref) => ref.read(billingRepositoryProvider).getPlans());

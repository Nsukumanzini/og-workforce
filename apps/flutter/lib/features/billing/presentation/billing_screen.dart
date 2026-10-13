import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../billing_providers.dart';
import '../data/billing_models.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(billingStatusProvider);
    final plans = ref.watch(billingPlansProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Plan & Billing')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(billingStatusProvider);
          ref.invalidate(billingPlansProvider);
          await ref.read(billingStatusProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            status.when(
              loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              error: (error, _) => _ErrorState(message: '$error', onRetry: () => ref.invalidate(billingStatusProvider)),
              data: (value) => _StatusContent(status: value),
            ),
            const SizedBox(height: 24),
            Text('Available plans', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            plans.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => _ErrorState(message: '$error', onRetry: () => ref.invalidate(billingPlansProvider)),
              data: (items) => Column(children: items.where((plan) => plan.active).map(_PlanCard.new).toList()),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusContent extends StatelessWidget {
  const _StatusContent({required this.status});

  final BillingStatus status;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current plan', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(status.plan.name.isEmpty ? 'No active plan' : status.plan.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('Subscription: ${_label(status.subscriptionState)}'),
            const SizedBox(height: 4),
            Text(status.trialActive ? 'Trial active${status.trialEnd == null ? '' : ' until ${_date(status.trialEnd!)}'}' : status.trialEnd != null && status.trialEnd!.isBefore(DateTime.now()) ? 'Trial expired' : 'No active trial'),
          ]))),
          const SizedBox(height: 20),
          Text('Usage', style: Theme.of(context).textTheme.titleLarge),
          Card(child: Column(children: status.metrics.map((metric) => _UsageRow(metric: metric)).toList())),
          const SizedBox(height: 20),
          Text('Included features', style: Theme.of(context).textTheme.titleLarge),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Wrap(spacing: 10, runSpacing: 10, children: status.plan.features.map((feature) => Chip(label: Text(_label(feature)))).toList()))),
          const SizedBox(height: 20),
          Card(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(status.providerMessage, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Plan and usage tracking are available. Online subscription payments will be connected during final integration.'),
            const SizedBox(height: 12),
            const OutlinedButton(onPressed: null, child: Text('Payments not yet connected')),
          ]))),
        ],
      );
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.metric});

  final UsageMetric metric;

  @override
  Widget build(BuildContext context) {
    final progress = metric.limit == null || metric.limit == 0 ? null : (metric.value / metric.limit!).clamp(0, 1).toDouble();
    final amount = metric.limit == null ? '${metric.value}' : '${metric.value} / ${metric.limit}';
    return ListTile(
      title: Text(_label(metric.key)),
      subtitle: progress == null ? null : Padding(padding: const EdgeInsets.only(top: 8), child: LinearProgressIndicator(value: progress)),
      trailing: Text(amount),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard(this.plan);

  final BillingPlan plan;

  @override
  Widget build(BuildContext context) {
    final price = plan.monthlyPrice == null ? null : '${plan.currency} ${plan.monthlyPrice} / month';
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(plan.name, style: Theme.of(context).textTheme.titleMedium),
      if (plan.description != null) ...[const SizedBox(height: 4), Text(plan.description!)],
      if (price != null) ...[const SizedBox(height: 4), Text(price)],
      const SizedBox(height: 8),
      ...plan.features.take(4).map((feature) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('• ${_label(feature)}'))),
    ])));
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(message), const SizedBox(height: 8), TextButton(onPressed: onRetry, child: const Text('Retry'))])));
}

String _label(String value) => value.split('_').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')} ${_month(value.month)} ${value.year}';
String _month(int value) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][value - 1];

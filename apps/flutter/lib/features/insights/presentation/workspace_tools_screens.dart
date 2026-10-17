import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/workforce_theme.dart';
import '../../workforce/workforce_providers.dart';
import '../insights_providers.dart';

class AgentSetupScreen extends ConsumerWidget {
  const AgentSetupScreen({super.key});

  static const agents = <_AgentSetupItem>[
    _AgentSetupItem('Business Assistant', 'Answer questions using your business knowledge.', Icons.auto_awesome_outlined, '/agents/business-assistant', 'Add FAQs, policies, and documents to Business Brain first.'),
    _AgentSetupItem('WhatsApp Agent', 'Handle customer chats and hand off to your team.', Icons.chat_bubble_outline, '/agents/whatsapp', 'Connect WhatsApp in Integrations, then review the reply policy.'),
    _AgentSetupItem('Email Agent', 'Triage incoming email and prepare replies.', Icons.email_outlined, '/agents/email', 'Connect an email provider before enabling external replies.'),
    _AgentSetupItem('Voice Receptionist', 'Capture calls, answer common questions, and escalate.', Icons.headset_mic_outlined, '/agents/voice', 'Connect a voice provider before enabling live call handling.'),
    _AgentSetupItem('Accounts Agent', 'Manage invoice follow-ups with approval controls.', Icons.request_quote_outlined, '/agents/accounts', 'Review collection rules and approval requirements first.'),
    _AgentSetupItem('Tender Agent', 'Track opportunities and prepare grounded drafts.', Icons.description_outlined, '/tenders', 'Add business documents to support evidence-based drafts.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Set up your AI workforce')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Start with the work you want to hand off.', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 7),
                Text('Choose an agent, check its connection and safety controls, then activate it when you are ready.', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 18),
                _ChecklistTile(icon: Icons.lightbulb_outline, title: 'Give agents business context', subtitle: 'Add accurate company details, FAQs, policies, products, and documents.', action: 'Open Business Brain', onTap: () => context.go('/business-brain')),
                const SizedBox(height: 10),
                _ChecklistTile(icon: Icons.link_outlined, title: 'Connect the channels you use', subtitle: 'Provider authorization and credentials are managed securely on the server.', action: 'View integrations', onTap: () => context.go('/integrations')),
                const SizedBox(height: 26),
                Text('Choose an agent', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                ref.watch(workforceSummaryProvider).when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => _LoadFailure(message: 'Agent status could not load: $error', onRetry: () => ref.invalidate(workforceSummaryProvider)),
                  data: (summary) {
                    final rows = (summary['employees'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
                    return Column(children: agents.map((agent) {
                      final status = rows.cast<Map<String, dynamic>?>().firstWhere((row) => row?['route'] == agent.route, orElse: () => null)?['status']?.toString();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Card(child: ListTile(
                          leading: CircleAvatar(backgroundColor: WorkforceTheme.mint, foregroundColor: WorkforceTheme.forest, child: Icon(agent.icon)),
                          title: Text(agent.name),
                          subtitle: Text('${status == null ? 'Not configured yet' : status.toUpperCase()} • ${agent.prerequisite}'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go(agent.route),
                        )),
                      );
                    }).toList());
                  },
                ),
              ],
            ),
          ),
        ),
      );
}

class IntegrationsScreen extends ConsumerWidget {
  const IntegrationsScreen({super.key});

  static const _providers = <_IntegrationItem>[
    _IntegrationItem('WhatsApp', 'Meta WhatsApp Cloud API', Icons.chat_bubble_outline, '/agents/whatsapp', 'whatsapp'),
    _IntegrationItem('Email', 'Inbox and email replies', Icons.email_outlined, '/agents/email', 'email'),
    _IntegrationItem('Voice', 'Inbound phone calls', Icons.phone_in_talk_outlined, '/agents/voice', 'voice'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Integrations')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Connect your business channels', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text('Connection status is read from your workspace. Tokens and provider secrets never leave the backend.', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 18),
                ref.watch(integrationsProvider).when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                  error: (error, _) => _LoadFailure(message: 'Integrations could not load: $error', onRetry: () => ref.invalidate(integrationsProvider)),
                  data: (connected) => Column(children: _providers.map((provider) {
                    final records = connected.where((row) => provider.channel == row['channel']).toList();
                    final isConnected = records.any((row) => row['status'] == 'connected');
                    final label = isConnected ? 'Connected' : 'Not connected';
                    final accounts = records.map((row) => row['account']).where((value) => value != null && '$value'.isNotEmpty).toList();
                    final account = accounts.isEmpty ? null : accounts.first;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(child: ListTile(
                        leading: CircleAvatar(backgroundColor: isConnected ? WorkforceTheme.mint : Theme.of(context).colorScheme.surfaceContainerHighest, child: Icon(provider.icon, color: isConnected ? WorkforceTheme.forest : null)),
                        title: Text(provider.name),
                        subtitle: Text('${provider.description}\n$label${account == null ? '' : ' • $account'}', maxLines: 3, overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go(provider.route),
                      )),
                    );
                  }).toList()),
                ),
                const SizedBox(height: 10),
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('If a provider is not connected, its agent can still be configured and tested in simulation mode. Live sending or calling stays disabled until secure provider authorization is completed.'))),
              ],
            ),
          ),
        ),
      );
}

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Performance')),
        body: ref.watch(workspaceReportProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _LoadFailure(message: 'Performance data could not load: $error', onRetry: () => ref.invalidate(workspaceReportProvider)),
          data: (report) {
            final activity = Map<String, dynamic>.from(report['activity'] as Map? ?? const {});
            final workspace = Map<String, dynamic>.from(report['workspace'] as Map? ?? const {});
            final accounts = Map<String, dynamic>.from(report['accounts'] as Map? ?? const {});
            final balances = (accounts['balances'] as List? ?? const []).map((value) => Map<String, dynamic>.from(value as Map)).toList();
            return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: ListView(padding: const EdgeInsets.all(20), children: [
              Text('Your business at a glance', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 5),
              Text('Live totals from the last 30 days and your current workspace.', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth > 660 ? (constraints.maxWidth - 24) / 3 : (constraints.maxWidth - 12) / 2;
                return Wrap(spacing: 12, runSpacing: 12, children: [
                  _MetricCard(width: width, icon: Icons.auto_awesome, label: 'AI runs · 30 days', value: '${activity['runs'] ?? 0}'),
                  _MetricCard(width: width, icon: Icons.check_circle_outline, label: 'Actions completed', value: '${activity['actionsCompleted'] ?? 0}'),
                  _MetricCard(width: width, icon: Icons.pending_actions_outlined, label: 'Approvals waiting', value: '${activity['pendingApprovals'] ?? 0}', onTap: () => context.go('/approvals')),
                  _MetricCard(width: width, icon: Icons.people_alt_outlined, label: 'Customers', value: '${workspace['customers'] ?? 0}', onTap: () => context.go('/crm')),
                  _MetricCard(width: width, icon: Icons.forum_outlined, label: 'Open conversations', value: '${workspace['openConversations'] ?? 0}', onTap: () => context.go('/inbox')),
                  _MetricCard(width: width, icon: Icons.description_outlined, label: 'Open tenders', value: '${workspace['openTenders'] ?? 0}', onTap: () => context.go('/tenders')),
                ]);
              }),
              const SizedBox(height: 20),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Invoice balances', style: Theme.of(context).textTheme.titleMedium),
                Text('${accounts['invoices'] ?? 0} invoices recorded', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                if (balances.isEmpty) const Text('No invoice balances recorded yet.'),
                ...balances.map((balance) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${balance['currency'] ?? 'ZAR'} outstanding: ${_money(balance['outstandingAmount'])}'),
                  subtitle: Text('Paid ${_money(balance['paidAmount'])} • overdue ${_money(balance['overdueAmount'])}'),
                )),
              ]))),
              const SizedBox(height: 10),
              Text('${activity['successfulRuns'] ?? 0} successful runs • ${activity['failedRuns'] ?? 0} failed runs • ${workspace['connectedIntegrations'] ?? 0} connected integrations', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ])));
          },
        ),
      );

  static String _money(dynamic value) => (value is num ? value : num.tryParse('$value') ?? 0).toStringAsFixed(2);
}

class _AgentSetupItem {
  const _AgentSetupItem(this.name, this.description, this.icon, this.route, this.prerequisite);
  final String name, description, route, prerequisite;
  final IconData icon;
}

class _IntegrationItem {
  const _IntegrationItem(this.name, this.description, this.icon, this.route, this.channel);
  final String name, description, route;
  final IconData icon;
  final String channel;
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({required this.icon, required this.title, required this.subtitle, required this.action, required this.onTap});
  final IconData icon;
  final String title, subtitle, action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), trailing: TextButton(onPressed: onTap, child: Text(action)), isThreeLine: true));
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.width, required this.icon, required this.label, required this.value, this.onTap});
  final double width;
  final IconData icon;
  final String label, value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: Card(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: WorkforceTheme.forest), const SizedBox(height: 14), Text(value, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 3), Text(label, style: Theme.of(context).textTheme.bodyMedium)])))));
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(message, textAlign: TextAlign.center), const SizedBox(height: 12), OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again'))]));
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../app/theme/workforce_theme.dart';
import '../../workforce/workforce_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _modules = <_ModuleInfo>[
    _ModuleInfo('AI Workforce', 'Your digital team, ready to work.', Icons.hub_outlined, '/workforce', Color(0xFFE7F3EC)),
    _ModuleInfo('Set up agents', 'Choose a task and configure an AI teammate.', Icons.playlist_add_check_circle_outlined, '/setup/agents', Color(0xFFEAF2F2)),
    _ModuleInfo('Approvals', 'Review actions that need your decision.', Icons.pending_actions_outlined, '/approvals', Color(0xFFF8EFE2)),
    _ModuleInfo('Integrations', 'Connect the channels your team uses.', Icons.link_outlined, '/integrations', Color(0xFFEAF0F8)),
    _ModuleInfo('Performance', 'See activity across agents and operations.', Icons.insights_outlined, '/reports', Color(0xFFF1ECF8)),
    _ModuleInfo('Unified Inbox', 'Bring every conversation together.', Icons.forum_outlined, '/inbox', Color(0xFFEAF0F8)),
    _ModuleInfo('CRM', 'Keep customer relationships in view.', Icons.people_alt_outlined, '/crm', Color(0xFFF8EFE2)),
    _ModuleInfo('Business Brain', 'Give your team the right context.', Icons.lightbulb_outline_rounded, '/business-brain', Color(0xFFF1ECF8)),
    _ModuleInfo('Accounts', 'Invoices, approvals and collections.', Icons.account_balance_wallet_outlined, '/accounts', Color(0xFFEAF2F2)),
    _ModuleInfo('Tender Agent', 'Find and manage new opportunities.', Icons.description_outlined, '/tenders', Color(0xFFF8ECE9)),
    _ModuleInfo('Email Agent', 'Let your assistant handle email tasks.', Icons.mark_email_unread_outlined, '/agents/email', Color(0xFFEAF0F8)),
    _ModuleInfo('Voice Receptionist', 'Stay on top of every call.', Icons.headset_mic_outlined, '/agents/voice', Color(0xFFE7F3EC)),
    _ModuleInfo('Business Assistant', 'Get help with everyday work.', Icons.auto_awesome_outlined, '/agents/business-assistant', Color(0xFFF1ECF8)),
    _ModuleInfo('WhatsApp Agent', 'Manage customer chats on WhatsApp.', Icons.chat_bubble_outline_rounded, '/agents/whatsapp', Color(0xFFE7F3EC)),
    _ModuleInfo('Accounts Assistant', 'Get help with billing workflows.', Icons.request_quote_outlined, '/agents/accounts', Color(0xFFEAF2F2)),
    _ModuleInfo('Plan & Billing', 'Manage your plan and payment details.', Icons.credit_card_outlined, '/billing', Color(0xFFF8EFE2)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceControllerProvider).value;
    final workforce = ref.watch(workforceSummaryProvider);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      drawer: _WorkspaceDrawer(workspaceName: workspace?.name ?? 'OG Workforce'),
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: WorkforceTheme.forest, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.hub_rounded, size: 19, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text('OG Workforce'),
        ]),
        actions: [
          IconButton(tooltip: 'Settings', onPressed: () => context.go('/settings'), icon: const Icon(Icons.settings_outlined)),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
            padding: EdgeInsets.fromLTRB(width < 600 ? 20 : 36, 26, width < 600 ? 20 : 36, 40),
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(color: WorkforceTheme.mint, borderRadius: BorderRadius.circular(30)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.circle, size: 8, color: WorkforceTheme.forest),
                    SizedBox(width: 7),
                    Text('YOUR WORKSPACE', style: TextStyle(fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: WorkforceTheme.forestDeep)),
                  ]),
                ),
              ]),
              const SizedBox(height: 15),
              Text(workspace?.name ?? 'Welcome to your workspace', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 7),
                Text('Everything your team needs to move work forward.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 28),
              _OverviewBanner(onOpen: () => context.go('/business-brain')),
              const SizedBox(height: 14),
              workforce.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (summary) => _ActionStrip(
                  pendingApprovals: summary['pendingApprovals'] ?? 0,
                  onApprovals: () => context.go('/approvals'),
                  onInbox: () => context.go('/inbox'),
                  onSetUp: () => context.go('/setup/agents'),
                ),
              ),
              const SizedBox(height: 31),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Your workspace', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Choose a space to pick up where you left off.', style: Theme.of(context).textTheme.bodyMedium),
                ])),
                if (width > 460) TextButton.icon(onPressed: () => context.go('/settings'), icon: const Icon(Icons.tune_rounded, size: 18), label: const Text('Manage workspace')),
              ]),
              const SizedBox(height: 17),
              LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 590 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _modules.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 132,
                  ),
                  itemBuilder: (context, index) => _ModuleCard(module: _modules[index]),
                );
              }),
              const SizedBox(height: 22),
              Card(child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: const CircleAvatar(backgroundColor: WorkforceTheme.mint, foregroundColor: WorkforceTheme.forest, child: Icon(Icons.settings_outlined)),
                title: const Text('Workspace settings'),
                subtitle: const Text('Preferences, access and account details'),
                trailing: const Icon(Icons.arrow_forward_rounded, size: 19),
                onTap: () => context.go('/settings'),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({required this.pendingApprovals, required this.onApprovals, required this.onInbox, required this.onSetUp});
  final dynamic pendingApprovals;
  final VoidCallback onApprovals, onInbox, onSetUp;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 10, runSpacing: 10, children: [
    ActionChip(avatar: const Icon(Icons.pending_actions_outlined, size: 18), label: Text('$pendingApprovals approvals to review'), onPressed: onApprovals),
    ActionChip(avatar: const Icon(Icons.forum_outlined, size: 18), label: const Text('Open inbox'), onPressed: onInbox),
    ActionChip(avatar: const Icon(Icons.playlist_add_check_circle_outlined, size: 18), label: const Text('Set up an AI agent'), onPressed: onSetUp),
  ]);
}

class _OverviewBanner extends StatelessWidget {
  const _OverviewBanner({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [WorkforceTheme.forestDeep, WorkforceTheme.forest]),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Make your AI team feel like your team.', style: TextStyle(color: Colors.white, fontSize: 19, height: 1.2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        Text('Add your business knowledge so every agent can work with the right context.', style: TextStyle(color: Colors.white.withValues(alpha: .82), height: 1.4, fontSize: 13)),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: onOpen,
          icon: const Icon(Icons.arrow_forward_rounded, size: 17),
          label: const Text('Explore Business Brain'),
          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: WorkforceTheme.forestDeep, minimumSize: const Size(0, 44)),
        ),
      ])),
      if (MediaQuery.sizeOf(context).width > 550) ...[
        const SizedBox(width: 24),
        Container(
          width: 102,
          height: 102,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), shape: BoxShape.circle),
          child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD9F1E2), size: 43),
        ),
      ],
    ]),
  );
}

class _ModuleInfo {
  const _ModuleInfo(this.title, this.description, this.icon, this.route, this.tint);
  final String title;
  final String description;
  final IconData icon;
  final String route;
  final Color tint;
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});
  final _ModuleInfo module;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.go(module.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: module.tint, borderRadius: BorderRadius.circular(15)), child: Icon(module.icon, color: WorkforceTheme.forestDeep, size: 23)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(module.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(module.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
          ])),
          const SizedBox(width: 5),
          Icon(Icons.arrow_outward_rounded, size: 17, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ]),
      ),
    ),
  );
}

class _WorkspaceDrawer extends StatelessWidget {
  const _WorkspaceDrawer({required this.workspaceName});
  final String workspaceName;

  @override
  Widget build(BuildContext context) => NavigationDrawer(
    onDestinationSelected: (index) {
      Navigator.pop(context);
      final routes = [...DashboardScreen._modules.map((module) => module.route), '/settings'];
      context.go(routes[index]);
    },
    children: [
      Padding(padding: const EdgeInsets.fromLTRB(24, 22, 20, 18), child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: WorkforceTheme.forest, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.hub_rounded, color: Colors.white, size: 21)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('OG Workforce', style: TextStyle(fontWeight: FontWeight.w700)), Text(workspaceName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)])),
      ])),
      const Divider(indent: 16, endIndent: 16),
      const Padding(padding: EdgeInsets.fromLTRB(28, 14, 20, 8), child: Text('WORKSPACE', style: TextStyle(color: WorkforceTheme.mutedInk, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w800))),
      ...DashboardScreen._modules.map((module) => NavigationDrawerDestination(icon: Icon(module.icon), label: Text(module.title))),
      const Divider(indent: 16, endIndent: 16),
      const NavigationDrawerDestination(icon: Icon(Icons.settings_outlined), label: Text('Settings')),
    ],
  );
}

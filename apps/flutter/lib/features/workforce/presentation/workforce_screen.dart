import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/workforce_theme.dart';
import '../workforce_providers.dart';

class WorkforceScreen extends ConsumerWidget {
  const WorkforceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('AI Workforce')),
    body: ref.watch(workforceSummaryProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$error', textAlign: TextAlign.center))),
      data: (summary) {
        final employees = summary['employees'] as List? ?? const [];
        final pending = summary['pendingApprovals'] ?? 0;
        return Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1060),
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 22, 20, 40), children: [
            Text('Meet your team', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 7),
            Text('Your AI workforce is here to take routine work off your hands.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 22),
            LayoutBuilder(builder: (context, constraints) => Wrap(spacing: 12, runSpacing: 12, children: [
              _StatCard(label: 'AI teammates', value: '${employees.length}', icon: Icons.groups_2_outlined, width: (constraints.maxWidth - 12) / 2),
              _StatCard(label: 'Approvals waiting', value: '$pending', icon: Icons.pending_actions_outlined, width: (constraints.maxWidth - 12) / 2),
            ])),
            const SizedBox(height: 30),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Your AI teammates', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Open a teammate to see what they can do.', style: Theme.of(context).textTheme.bodyMedium),
              ])),
              IconButton(tooltip: 'Refresh team', onPressed: () => ref.invalidate(workforceSummaryProvider), icon: const Icon(Icons.refresh_rounded)),
            ]),
            const SizedBox(height: 14),
            if (employees.isEmpty)
              Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30), child: Column(children: [
                Container(width: 58, height: 58, decoration: const BoxDecoration(color: WorkforceTheme.mint, shape: BoxShape.circle), child: const Icon(Icons.hub_outlined, color: WorkforceTheme.forest, size: 28)),
                const SizedBox(height: 14),
                Text('Your team is getting ready', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('As your AI teammates become available, they will appear here.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              ])))
            else
              ...employees.map((employee) {
                final name = '${employee['name'] ?? 'AI teammate'}';
                final status = '${employee['status'] ?? 'Unknown'}';
                final route = employee['route'];
                return Padding(padding: const EdgeInsets.only(bottom: 11), child: Card(child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  leading: CircleAvatar(backgroundColor: WorkforceTheme.mint, foregroundColor: WorkforceTheme.forest, child: Text(name.isEmpty ? 'A' : name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700))),
                  title: Text(name, style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: WorkforceTheme.forest, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(status, style: Theme.of(context).textTheme.bodyMedium),
                  ])),
                  trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
                  onTap: route == null ? null : () => context.go('$route'),
                )));
              }),
          ]),
        ));
      },
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.width});
  final String label;
  final String value;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
    Container(width: 42, height: 42, decoration: BoxDecoration(color: WorkforceTheme.mint, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: WorkforceTheme.forest, size: 21)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
    ])),
  ]))));
}

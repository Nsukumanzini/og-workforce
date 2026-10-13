import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../workforce_providers.dart';

class WorkforceScreen extends ConsumerWidget {
  const WorkforceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(appBar: AppBar(title: const Text('AI Workforce')), body: ref.watch(workforceSummaryProvider).when(
    loading: () => const Center(child: CircularProgressIndicator()), error: (error, _) => Center(child: Text('$error')),
    data: (summary) { final employees = summary['employees'] as List? ?? const []; return ListView(padding: const EdgeInsets.all(16), children: [Text('${employees.length} AI Employees • Pending approvals: ${summary['pendingApprovals'] ?? 0}'), const SizedBox(height: 12), ...employees.map((employee) => Card(child: ListTile(title: Text('${employee['name'] ?? 'AI Employee'}'), subtitle: Text('${employee['status'] ?? 'Unknown'}'), trailing: TextButton(onPressed: employee['route'] == null ? null : () => context.go('${employee['route']}'), child: const Text('Open'))))) ]); },
  ));
}

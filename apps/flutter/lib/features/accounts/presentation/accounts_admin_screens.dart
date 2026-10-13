import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../accounts_providers.dart';

class AccountsApprovalsScreen extends ConsumerWidget { const AccountsApprovalsScreen({super.key}); @override Widget build(BuildContext c, WidgetRef r) => Scaffold(appBar: AppBar(title: const Text('Approvals')), body: r.watch(accountsApprovalsProvider).when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Center(child: Text('$e')), data: (items) => items.isEmpty ? const Center(child: Text('No pending approvals.')) : ListView(children: items.map((item) => ListTile(title: Text('${item['status'] ?? 'Approval'}'), subtitle: Text('${item['created_at'] ?? ''}'))).toList()))); }
class AccountsAgentScreen extends ConsumerWidget { const AccountsAgentScreen({super.key}); @override Widget build(BuildContext c, WidgetRef r) => Scaffold(appBar: AppBar(title: const Text('Accounts Agent')), body: FutureBuilder(future: r.read(accountsRepositoryProvider).agent(), builder: (c, snapshot) => snapshot.hasData ? Center(child: Text('${(snapshot.data as Map)['status'] ?? 'Unknown'}')) : const Center(child: CircularProgressIndicator()))); }

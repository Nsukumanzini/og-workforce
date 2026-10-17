import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../accounts_providers.dart';

class AccountsApprovalsScreen extends ConsumerWidget {
  const AccountsApprovalsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Approvals'), actions: [IconButton(tooltip: 'Refresh', onPressed: () => ref.invalidate(accountsApprovalsProvider), icon: const Icon(Icons.refresh))]),
        body: ref.watch(accountsApprovalsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Problem(text: 'Approvals could not be loaded: $e', retry: () => ref.invalidate(accountsApprovalsProvider)),
          data: (items) {
            final pending = items.where((item) => ['pending', 'requested'].contains(item['status'])).toList();
            if (pending.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No pending approvals.')));
            return ListView(padding: const EdgeInsets.all(14), children: [
              Text('Review agent actions before they affect customers or finances.', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              ...pending.map((item) {
                final action = Map<String, dynamic>.from(item['action'] as Map? ?? const {});
                return Card(child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.pending_actions_outlined)),
                  title: Text('${action['tool_key'] ?? 'Agent action'}'.replaceAll('_', ' ')),
                  subtitle: Text('${action['risk'] ?? 'Review required'} • Requested ${item['created_at'] ?? ''}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _review(context, ref, item),
                ));
              }),
            ]);
          },
        ),
      );

  Future<void> _review(BuildContext context, WidgetRef ref, Map<String, dynamic> item) async {
    final id = '${item['id'] ?? ''}'; if (id.isEmpty) { await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Approval details'), content: Text(item.toString()), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))])); return; }
    final action = Map<String, dynamic>.from(item['action'] as Map? ?? const {});
    final payload = action['input_payload'] is Map ? Map<String, dynamic>.from(action['input_payload'] as Map) : <String, dynamic>{};
    final toolKey = '${action['tool_key'] ?? ''}';
    final toolTitle = switch (toolKey) {
      'requestEmailApproval' => 'email reply',
      'requestTenderApproval' => 'tender draft',
      'sendPaymentReminder' => 'payment reminder',
      _ => toolKey.replaceAll('_', ' ').isEmpty ? 'agent action' : toolKey.replaceAll('_', ' '),
    };
    final review = Map<String, dynamic>.from(action['review_context'] as Map? ?? const {});
    final detail = switch (review['type']) {
      'email_reply' => 'To: ${review['recipient'] ?? 'Unknown recipient'}\nSubject: ${review['subject'] ?? '(no subject)'}\n\n${review['content'] ?? ''}',
      'tender_draft' => 'Draft type: ${review['draftType'] ?? 'response'} • Current status: ${review['status'] ?? 'draft'}\n\n${review['content'] ?? ''}\n\nApproval is for internal use. It will not submit the tender externally.',
      'invoice_reminder' => 'Invoice: ${review['invoiceNumber'] ?? 'Unknown'}\nStage: ${review['stage'] ?? 'review'}\nDue: ${review['dueDate'] ?? 'unknown'}\nAmount: ${review['currency'] ?? ''} ${review['total'] ?? ''}',
      _ => payload.isEmpty ? 'No action details were provided.' : const JsonEncoder.withIndent('  ').convert(payload),
    };
    final decision = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Review $toolTitle'),
      content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Risk: ${action['risk'] ?? 'not specified'}'),
        const SizedBox(height: 10),
        Text(detail, style: Theme.of(ctx).textTheme.bodySmall),
        if (review['type'] == 'email_reply') ...[
          const SizedBox(height: 10),
          const Text('Approval does not send this message. The email provider is not connected, so it will remain available for manual follow-up.'),
        ],
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, 'rejected'), child: const Text('Reject')), FilledButton(onPressed: () => Navigator.pop(ctx, 'approved'), child: const Text('Approve'))],
    ));
    if (decision == null) return;
    try {
      await ref.read(accountsRepositoryProvider).resolveApproval(id, decision);
      ref.invalidate(accountsApprovalsProvider);
      if (context.mounted) {
        final message = decision == 'rejected' ? 'Action rejected.' : toolKey == 'requestEmailApproval' ? 'Email approved for manual follow-up. It was not sent.' : toolKey == 'requestTenderApproval' ? 'Draft approved for internal use. It was not submitted.' : 'Approval decision saved.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approval could not be updated: $e'))); }
  }
}

class AccountsAgentScreen extends ConsumerStatefulWidget { const AccountsAgentScreen({super.key}); @override ConsumerState<AccountsAgentScreen> createState() => _AccountsAgentScreenState(); }
class _AccountsAgentScreenState extends ConsumerState<AccountsAgentScreen> {
  late Future<Map<String, dynamic>> agent; bool busy = false;
  @override void initState() { super.initState(); agent = ref.read(accountsRepositoryProvider).agent(); }
  void reload() => setState(() => agent = ref.read(accountsRepositoryProvider).agent());
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Accounts Agent'), actions: [IconButton(tooltip: 'Refresh', onPressed: reload, icon: const Icon(Icons.refresh))]), body: FutureBuilder<Map<String, dynamic>>(future: agent, builder: (context, snapshot) { if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator()); if (snapshot.hasError) return _Problem(text: 'Agent status could not be loaded: ${snapshot.error}', retry: reload); final data = snapshot.data!; final status = '${data['status'] ?? 'paused'}'; final active = status == 'active'; return ListView(padding: const EdgeInsets.all(20), children: [Card(child: ListTile(leading: Icon(active ? Icons.check_circle : Icons.pause_circle_outline), title: Text(active ? 'Agent active' : 'Agent paused'), subtitle: Text(active ? 'Automatic account actions are enabled according to your collection policy.' : 'The agent will not run automatically.'), trailing: Text(status))), const SizedBox(height: 12), FilledButton.icon(onPressed: busy ? null : () => _setStatus(active ? 'paused' : 'active'), icon: Icon(active ? Icons.pause : Icons.play_arrow), label: Text(active ? 'Pause agent' : 'Activate agent')), OutlinedButton.icon(onPressed: busy ? null : _run, icon: const Icon(Icons.play_circle_outline), label: const Text('Run now'),), const SizedBox(height: 8), const Text('The collection policy controls reminders and approval requirements.')]); }));
  Future<void> _setStatus(String status) async { setState(() => busy = true); try { await ref.read(accountsRepositoryProvider).setAgent(status); reload(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Agent status could not be changed: $e'))); } finally { if (mounted) setState(() => busy = false); } }
  Future<void> _run() async { setState(() => busy = true); try { final result = await ref.read(accountsRepositoryProvider).run(); if (mounted) await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Agent run complete'), content: Text(result['message']?.toString() ?? result.toString()), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))])); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Agent could not run: $e'))); } finally { if (mounted) setState(() => busy = false); } }
}

class _Problem extends StatelessWidget { const _Problem({required this.text, required this.retry}); final String text; final VoidCallback retry; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(text, textAlign: TextAlign.center), OutlinedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Retry'))]))); }

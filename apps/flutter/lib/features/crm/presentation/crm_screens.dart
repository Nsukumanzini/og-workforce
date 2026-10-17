import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../crm_providers.dart';
import '../data/crm_inbox_repository.dart';

class CrmScreen extends ConsumerStatefulWidget {
  const CrmScreen({super.key});
  @override
  ConsumerState<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends ConsumerState<CrmScreen> {
  String query = '';
  String status = 'All';

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(crmContactsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Customers'), actions: [IconButton(tooltip: 'Refresh', onPressed: () => ref.invalidate(crmContactsProvider), icon: const Icon(Icons.refresh)), IconButton(tooltip: 'Inbox', onPressed: () => context.go('/inbox'), icon: const Icon(Icons.forum_outlined))]),
      body: contacts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Failure(text: 'Customers could not be loaded: $e', retry: () => ref.invalidate(crmContactsProvider)),
        data: (items) {
          final filtered = items.where((c) => (status == 'All' || c.status.toLowerCase() == status.toLowerCase()) && '${c.name} ${c.email} ${c.phone} ${c.company}'.toLowerCase().contains(query.toLowerCase())).toList();
          return RefreshIndicator(onRefresh: () async => ref.invalidate(crmContactsProvider), child: ListView(padding: const EdgeInsets.all(16), children: [TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search customers'), onChanged: (v) => setState(() => query = v)), const SizedBox(height: 12), Wrap(spacing: 8, children: ['All', 'lead', 'customer'].map((s) => ChoiceChip(label: Text(s), selected: status == s, onSelected: (_) => setState(() => status = s))).toList()), const SizedBox(height: 12), if (filtered.isEmpty) const _Empty(text: 'No customers match this search.') else ...filtered.map((c) => Card(child: ListTile(leading: CircleAvatar(child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase())), title: Text(c.name), subtitle: Text([c.company, c.email, c.phone].where((s) => s.isNotEmpty).join(' • ')), trailing: Text(c.status.isEmpty ? '' : c.status), onTap: () => context.go('/crm/contacts/${c.id}'))))]));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showAddContact(context), icon: const Icon(Icons.person_add_alt_1), label: const Text('Add customer')),
    );
  }

  Future<void> _showAddContact(BuildContext context) async {
    final name = TextEditingController(), email = TextEditingController(), phone = TextEditingController(), company = TextEditingController();
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Add customer'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')), TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')), TextField(controller: company, decoration: const InputDecoration(labelText: 'Company'))])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () async { if (name.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter the customer name.'))); return; } try { await ref.read(crmInboxRepositoryProvider).createContact({'full_name': name.text.trim(), if (email.text.trim().isNotEmpty) 'email': email.text.trim(), if (phone.text.trim().isNotEmpty) 'phone': phone.text.trim(), if (company.text.trim().isNotEmpty) 'company_name': company.text.trim()}); ref.invalidate(crmContactsProvider); if (ctx.mounted) Navigator.pop(ctx); } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Customer could not be added: $e'))); } }, child: const Text('Save'))]));
    name.dispose(); email.dispose(); phone.dispose(); company.dispose();
  }
}

class ContactDetailScreen extends ConsumerStatefulWidget {
  const ContactDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends ConsumerState<ContactDetailScreen> {
  late Future<CrmContact> contact;
  @override
  void initState() { super.initState(); contact = ref.read(crmInboxRepositoryProvider).contact(widget.id); }
  void reload() => setState(() => contact = ref.read(crmInboxRepositoryProvider).contact(widget.id));
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Customer'), actions: [IconButton(tooltip: 'Edit customer', onPressed: () => contact.then(_edit), icon: const Icon(Icons.edit_outlined))]), body: FutureBuilder<CrmContact>(future: contact, builder: (context, snap) { if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator()); if (snap.hasError) return _Failure(text: 'Customer could not be loaded: ${snap.error}', retry: reload); final c = snap.data!; return ListView(padding: const EdgeInsets.all(20), children: [CircleAvatar(radius: 32, child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase())), const SizedBox(height: 16), Center(child: Text(c.name, style: Theme.of(context).textTheme.headlineSmall)), if (c.company.isNotEmpty) Center(child: Text(c.company)), const SizedBox(height: 20), _InfoTile(icon: Icons.alternate_email, label: 'Email', value: c.email), _InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: c.phone), _InfoTile(icon: Icons.flag_outlined, label: 'Status', value: c.status), _InfoTile(icon: Icons.notes_outlined, label: 'Notes', value: c.notes), const SizedBox(height: 12), FilledButton.icon(onPressed: () => context.go('/accounts/invoices?contactId=${c.id}'), icon: const Icon(Icons.receipt_long), label: const Text('View invoices')), OutlinedButton.icon(onPressed: () => context.go('/inbox'), icon: const Icon(Icons.forum_outlined), label: const Text('Open inbox'))]); }));

  Future<void> _edit(CrmContact c) async {
    final name = TextEditingController(text: c.name), email = TextEditingController(text: c.email), company = TextEditingController(text: c.company), status = TextEditingController(text: c.status);
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Edit customer'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')), TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')), TextField(controller: company, decoration: const InputDecoration(labelText: 'Company')), TextField(controller: status, decoration: const InputDecoration(labelText: 'Lifecycle status'))])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () async { try { await ref.read(crmInboxRepositoryProvider).updateContact(c.id, {'full_name': name.text.trim(), 'email': email.text.trim(), 'company_name': company.text.trim(), 'lifecycle_status': status.text.trim()}); ref.invalidate(crmContactsProvider); reload(); if (ctx.mounted) Navigator.pop(ctx); } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Changes could not be saved: $e'))); } }, child: const Text('Save'))]));
    name.dispose(); email.dispose(); company.dispose(); status.dispose();
  }
}

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});
  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String query = '';
  CrmContact? _contactFor(List<CrmContact> contacts, String id) { for (final contact in contacts) { if (contact.id == id) return contact; } return null; }
  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(inboxConversationsProvider);
    final contacts = ref.watch(crmContactsProvider).when(
      data: (value) => value,
      error: (_, __) => const <CrmContact>[],
      loading: () => const <CrmContact>[],
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox'), actions: [
        IconButton(tooltip: 'Refresh', onPressed: () => ref.invalidate(inboxConversationsProvider), icon: const Icon(Icons.refresh)),
      ]),
      body: conversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Failure(text: 'Inbox could not be loaded: $e', retry: () => ref.invalidate(inboxConversationsProvider)),
        data: (items) {
          final filtered = items.where((x) {
            final c = _contactFor(contacts, x.contactId);
            return '${c?.name ?? ''} ${x.channel} ${x.status}'.toLowerCase().contains(query.toLowerCase());
          }).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(inboxConversationsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search conversations'),
                  onChanged: (value) => setState(() => query = value),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const _Empty(text: 'No conversations found.')
                else
                  ...filtered.map((conversation) {
                    final contact = _contactFor(contacts, conversation.contactId);
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
                        title: Text(contact?.name ?? 'Conversation'),
                        subtitle: Text('${conversation.channel} • ${conversation.status}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/inbox/${conversation.id}'),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  late Future<List<UnifiedMessage>> messages;
  final composer = TextEditingController();
  bool busy = false;
  InboxConversation? conversation;
  @override
  void initState() { super.initState(); messages = _load(); }
  Future<List<UnifiedMessage>> _load() async { final repo = ref.read(crmInboxRepositoryProvider); final conversations = await repo.conversations(); final matches = conversations.where((x) => x.id == widget.id); conversation = matches.isEmpty ? null : matches.first; return repo.messages(widget.id); }
  void reload() => setState(() => messages = _load());
  @override
  void dispose() { composer.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Conversation'), actions: [IconButton(tooltip: 'Refresh', onPressed: reload, icon: const Icon(Icons.refresh)), if (conversation != null) TextButton(onPressed: busy ? null : _toggleOwner, child: Text(conversation!.status == 'human_takeover' ? 'Return to AI' : 'Take over'))]), body: FutureBuilder<List<UnifiedMessage>>(future: messages, builder: (context, snap) { if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator()); if (snap.hasError) return _Failure(text: 'Messages could not be loaded: ${snap.error}', retry: reload); final list = snap.data!; return Column(children: [if (conversation?.channel != 'whatsapp') Padding(padding: const EdgeInsets.all(12), child: Text('Replies are only available for connected WhatsApp conversations (${conversation?.channel ?? 'unknown'}).')), Expanded(child: list.isEmpty ? const _Empty(text: 'No messages yet.') : ListView(padding: const EdgeInsets.all(16), children: list.map((m) => Align(alignment: m.direction == 'outbound' ? Alignment.centerRight : Alignment.centerLeft, child: Card(color: m.direction == 'outbound' ? Theme.of(context).colorScheme.primaryContainer : null, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m.content), const SizedBox(height: 4), Text('${m.human ? 'Team member' : m.agent ? 'AI agent' : m.direction} • ${m.status}', style: Theme.of(context).textTheme.labelSmall)]))))).toList())), SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: composer, minLines: 1, maxLines: 4, decoration: const InputDecoration(hintText: 'Write a reply'))), const SizedBox(width: 8), IconButton.filled(tooltip: 'Send reply', onPressed: busy ? null : _send, icon: const Icon(Icons.send))]))) ]); }));
  Future<void> _send() async { final text = composer.text.trim(); if (text.isEmpty) return; if (conversation?.channel != 'whatsapp') { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This channel does not support replies yet.'))); return; } setState(() => busy = true); try { await ref.read(crmInboxRepositoryProvider).send(widget.id, text); composer.clear(); reload(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reply failed: $e'))); } finally { if (mounted) setState(() => busy = false); } }
  Future<void> _toggleOwner() async { setState(() => busy = true); try { final repo = ref.read(crmInboxRepositoryProvider); if (conversation?.status == 'human_takeover') { await repo.handback(widget.id); } else { await repo.takeover(widget.id); } ref.invalidate(inboxConversationsProvider); reload(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not change conversation owner: $e'))); } finally { if (mounted) setState(() => busy = false); } }
}

class _InfoTile extends StatelessWidget { const _InfoTile({required this.icon, required this.label, required this.value}); final IconData icon; final String label, value; @override Widget build(BuildContext context) => ListTile(leading: Icon(icon), title: Text(label), subtitle: Text(value.isEmpty ? 'Not provided' : value)); }
class _Empty extends StatelessWidget { const _Empty({required this.text}); final String text; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(text))); }
class _Failure extends StatelessWidget { const _Failure({required this.text, required this.retry}); final String text; final VoidCallback retry; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(text, textAlign: TextAlign.center), const SizedBox(height: 12), OutlinedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Try again'))]))); }

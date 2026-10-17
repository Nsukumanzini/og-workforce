import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../crm/crm_providers.dart';
import '../../crm/data/crm_inbox_repository.dart';
import '../accounts_providers.dart';

class AccountsDashboard extends ConsumerWidget {
  const AccountsDashboard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Accounts & Collections'), actions: [
      IconButton(tooltip: 'Refresh', onPressed: () => ref.invalidate(invoicesProvider), icon: const Icon(Icons.refresh_rounded)),
      const SizedBox(width: 8),
    ]),
    body: ref.watch(invoicesProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorMessage(message: '$error', onRetry: () => ref.invalidate(invoicesProvider)),
      data: (items) {
        final outstanding = items.fold<double>(0, (sum, item) => sum + item.outstanding);
        final overdue = items.where((item) => item.status == 'overdue').length;
        return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Accounts overview', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 7),
          Text('Track customer invoices, balances, and collection work.', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 18),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _SummaryCard(label: 'Invoices', value: '${items.length}', icon: Icons.receipt_long_outlined),
            _SummaryCard(label: 'Outstanding', value: outstanding.toStringAsFixed(2), icon: Icons.account_balance_wallet_outlined),
            _SummaryCard(label: 'Overdue', value: '$overdue', icon: Icons.warning_amber_rounded),
          ]),
          const SizedBox(height: 22),
          FilledButton.icon(onPressed: () => context.go('/accounts/invoices/new'), icon: const Icon(Icons.add_rounded), label: const Text('Create invoice')),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => context.go('/accounts/invoices'), icon: const Icon(Icons.receipt_long_outlined), label: const Text('View invoices')),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => context.go('/accounts/approvals'), icon: const Icon(Icons.fact_check_outlined), label: const Text('Review approvals')),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => context.go('/agents/accounts'), icon: const Icon(Icons.auto_awesome_outlined), label: const Text('Open Accounts Agent')),
        ])));
      },
    ),
  );
}

class InvoiceCreateScreen extends ConsumerStatefulWidget {
  const InvoiceCreateScreen({super.key});
  @override
  ConsumerState<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends ConsumerState<InvoiceCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String? _contactId;
  late final _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  bool _saving = false;
  @override
  void dispose() { _number.dispose(); _amount.dispose(); _notes.dispose(); super.dispose(); }

  String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  Future<void> _pickDueDate() async {
    final value = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
    if (value != null) setState(() => _dueDate = value);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _contactId == null) {
      if (_contactId == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a customer before creating the invoice.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(accountsRepositoryProvider).createInvoice({
        'contact_id': _contactId,
        'invoice_number': _number.text.trim(),
        'issue_date': _date(_issueDate),
        'due_date': _date(_dueDate),
        'currency': 'ZAR',
        'total_amount': double.parse(_amount.text.trim()),
        'notes': _notes.text.trim(),
      });
      ref.invalidate(invoicesProvider);
      if (mounted) context.go('/accounts/invoices');
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice could not be created: $error')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create invoice')),
    body: ref.watch(crmContactsProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorMessage(message: 'Customers could not be loaded: $error', onRetry: () => ref.invalidate(crmContactsProvider)),
      data: (contacts) => Form(key: _form, child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Invoice details', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 7),
        Text('Choose a customer and set the invoice total and due date.', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _contactId,
          decoration: const InputDecoration(labelText: 'Customer'),
          items: contacts.map((contact) => DropdownMenuItem(value: contact.id, child: Text(contact.name, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: _saving ? null : (value) => setState(() => _contactId = value),
          validator: (value) => value == null ? 'Choose a customer.' : null,
        ),
        if (contacts.isEmpty) ...[
          const SizedBox(height: 9),
          Text('Add a customer in CRM before creating an invoice.', style: Theme.of(context).textTheme.bodyMedium),
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => context.go('/crm'), icon: const Icon(Icons.people_outline), label: const Text('Open CRM'))),
        ],
        const SizedBox(height: 14),
        TextFormField(controller: _number, decoration: const InputDecoration(labelText: 'Invoice number'), validator: (value) => value == null || value.trim().isEmpty ? 'Enter an invoice number.' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Total amount (ZAR)'), validator: (value) { final amount = double.tryParse(value ?? ''); return amount == null || amount <= 0 ? 'Enter an amount greater than zero.' : null; }),
        const SizedBox(height: 14),
        Card(child: ListTile(leading: const Icon(Icons.event_outlined), title: const Text('Issue date'), subtitle: Text(_date(_issueDate)))),
        const SizedBox(height: 8),
        Card(child: ListTile(leading: const Icon(Icons.event_available_outlined), title: const Text('Due date'), subtitle: Text(_date(_dueDate)), trailing: const Icon(Icons.edit_calendar_outlined), onTap: _saving ? null : _pickDueDate)),
        const SizedBox(height: 14),
        TextFormField(controller: _notes, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Notes (optional)')),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator()) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Creating…' : 'Create invoice')),
      ])))),
    ),
  );
}

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key, this.contactId});
  final String? contactId;
  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  final _search = TextEditingController();
  String _filter = 'All';
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.contactId == null ? 'Invoices' : 'Customer invoices'), actions: [
      IconButton(tooltip: 'Create invoice', onPressed: () => context.go('/accounts/invoices/new'), icon: const Icon(Icons.add_rounded)),
    ]),
    body: ref.watch(invoicesProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorMessage(message: '$error', onRetry: () => ref.invalidate(invoicesProvider)),
      data: (allItems) {
        final query = _search.text.trim().toLowerCase();
        final items = allItems.where((item) => (widget.contactId == null || item.contactId == widget.contactId) && (_filter == 'All' || item.status.toLowerCase() == _filter.toLowerCase()) && (query.isEmpty || item.number.toLowerCase().contains(query))).toList();
        return Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: 'Search invoice number', suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.clear_rounded))))),
          SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [for (final item in ['All', 'Draft', 'Issued', 'Overdue', 'Paid']) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(item), selected: _filter == item, onSelected: (_) => setState(() => _filter = item)))])),
          Expanded(child: items.isEmpty
            ? _EmptyInvoices(onCreate: () => context.go('/accounts/invoices/new'))
            : RefreshIndicator(onRefresh: () async => ref.invalidate(invoicesProvider), child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (context, index) {
                final invoice = items[index];
                return Padding(padding: const EdgeInsets.only(bottom: 10), child: Card(child: ListTile(
                  leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.secondaryContainer, child: const Icon(Icons.receipt_long_outlined)),
                  title: Text(invoice.number),
                  subtitle: Text('${invoice.status} · Due ${invoice.dueDate}'),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${invoice.currency} ${invoice.outstanding.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleSmall), const Icon(Icons.chevron_right_rounded, size: 16)]),
                  onTap: () => context.go('/accounts/invoices/${invoice.id}'),
                )));
              }))),
        ]);
      },
    ),
  );
}

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  late Future<Map<String, dynamic>> _invoiceFuture;
  bool _busy = false;
  @override
  void initState() { super.initState(); _invoiceFuture = ref.read(accountsRepositoryProvider).invoice(widget.id); }
  void _reload() => setState(() => _invoiceFuture = ref.read(accountsRepositoryProvider).invoice(widget.id));

  Future<void> _recordPayment(Map<String, dynamic> invoice) async {
    final amount = TextEditingController();
    final reference = TextEditingController();
    final accepted = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Record payment'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Payment amount')),
        const SizedBox(height: 12),
        TextField(controller: reference, decoration: const InputDecoration(labelText: 'Reference (optional)')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () { final value = double.tryParse(amount.text); final outstanding = (double.tryParse('${invoice['total_amount']}') ?? 0) - (double.tryParse('${invoice['amount_paid'] ?? 0}') ?? 0); if (value == null || value <= 0 || value > outstanding) { ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(value == null || value <= 0 ? 'Enter a payment greater than zero.' : 'Payment cannot exceed the outstanding balance of ${outstanding.toStringAsFixed(2)}.'))); return; } Navigator.pop(context, true); }, child: const Text('Record'))],
    ));
    if (accepted == true) {
      setState(() => _busy = true);
      try {
        await ref.read(accountsRepositoryProvider).payment(widget.id, {'amount': double.parse(amount.text), 'payment_reference': reference.text.trim()});
        ref.invalidate(invoicesProvider);
        _reload();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded.')));
      } catch (error) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment could not be recorded: $error')));
      } finally { if (mounted) setState(() => _busy = false); }
    }
    amount.dispose(); reference.dispose();
  }

  Future<void> _dispute() async {
    final reason = TextEditingController();
    final accepted = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Raise a dispute'),
      content: TextField(controller: reason, maxLines: 4, maxLength: 300, decoration: const InputDecoration(labelText: 'Reason')),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () { if (reason.text.trim().isEmpty) { ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Enter a reason for the dispute.'))); return; } Navigator.pop(context, true); }, child: const Text('Submit dispute'))],
    ));
    if (accepted == true) {
      try {
        setState(() => _busy = true);
        await ref.read(accountsRepositoryProvider).dispute(widget.id, reason.text.trim());
        _reload();
      } catch (error) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dispute could not be submitted: $error')));
      } finally { if (mounted) setState(() => _busy = false); }
    }
    reason.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Invoice'), actions: [IconButton(tooltip: 'Refresh', onPressed: _busy ? null : _reload, icon: const Icon(Icons.refresh_rounded))]),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _invoiceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _ErrorMessage(message: '${snapshot.error}', onRetry: _reload);
        final payload = snapshot.data!;
        final invoice = Map<String, dynamic>.from(payload['invoice'] as Map);
        final payments = payload['payments'] as List? ?? const [];
        invoice['amount_paid'] = payments.where((payment) => payment['status'] == 'confirmed').fold<double>(0, (sum, payment) => sum + (double.tryParse('${payment['amount']}') ?? 0));
        return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('${invoice['invoice_number'] ?? widget.id}', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Card(child: Column(children: [
            _DetailRow(label: 'Status', value: '${invoice['status'] ?? 'Unknown'}'),
            _DetailRow(label: 'Issue date', value: '${invoice['issue_date'] ?? '—'}'),
            _DetailRow(label: 'Due date', value: '${invoice['due_date'] ?? '—'}'),
            _DetailRow(label: 'Total', value: '${invoice['currency'] ?? 'ZAR'} ${invoice['total_amount'] ?? '0'}'),
            _DetailRow(label: 'Disputed', value: invoice['disputed'] == true ? 'Yes' : 'No'),
            if ('${invoice['notes'] ?? ''}'.isNotEmpty) _DetailRow(label: 'Notes', value: '${invoice['notes']}'),
          ])),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _busy ? null : () => context.go('/accounts/invoices/${widget.id}/edit'), icon: const Icon(Icons.edit_outlined), label: const Text('Edit invoice')),
          const SizedBox(height: 9),
          OutlinedButton.icon(onPressed: _busy ? null : () => _recordPayment(invoice), icon: const Icon(Icons.payments_outlined), label: const Text('Record payment')),
          const SizedBox(height: 9),
          OutlinedButton.icon(onPressed: _busy || invoice['disputed'] == true ? null : _dispute, icon: const Icon(Icons.report_problem_outlined), label: Text(invoice['disputed'] == true ? 'Dispute submitted' : 'Raise a dispute')),
          const SizedBox(height: 22),
          Text('Payments', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (payments.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No payments recorded yet.'))),
          ...payments.map((payment) => Card(child: ListTile(leading: const Icon(Icons.payments_outlined), title: Text('${invoice['currency'] ?? 'ZAR'} ${payment['amount'] ?? '0'}'), subtitle: Text('${payment['payment_date'] ?? ''} · ${payment['payment_reference'] ?? 'No reference'}'), trailing: Text('${payment['status'] ?? ''}')))),
        ])));
      },
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(width: 190, child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: Theme.of(context).textTheme.titleLarge), Text(label, style: Theme.of(context).textTheme.bodySmall)])]))));
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)), Expanded(child: Text(value))]));
}

class _EmptyInvoices extends StatelessWidget {
  const _EmptyInvoices({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.receipt_long_outlined, size: 44), const SizedBox(height: 10), const Text('No invoices match this view.'), const SizedBox(height: 12), FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_rounded), label: const Text('Create invoice'))])));
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(message, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again'))])));
}

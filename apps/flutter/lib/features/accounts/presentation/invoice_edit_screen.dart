import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../accounts_providers.dart';

class InvoiceEditScreen extends ConsumerStatefulWidget {
  const InvoiceEditScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<InvoiceEditScreen> createState() => _InvoiceEditScreenState();
}

class _InvoiceEditScreenState extends ConsumerState<InvoiceEditScreen> {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _issueDate = TextEditingController();
  final _dueDate = TextEditingController();
  final _notes = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _number.dispose(); _issueDate.dispose(); _dueDate.dispose(); _notes.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await ref.read(accountsRepositoryProvider).invoice(widget.id);
      final invoice = Map<String, dynamic>.from(response['invoice'] as Map);
      _number.text = '${invoice['invoice_number'] ?? ''}';
      _issueDate.text = '${invoice['issue_date'] ?? ''}';
      _dueDate.text = '${invoice['due_date'] ?? ''}';
      _notes.text = '${invoice['notes'] ?? ''}';
      if (mounted) setState(() => _loading = false);
    } catch (error) {
      if (mounted) setState(() { _error = '$error'; _loading = false; });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(accountsRepositoryProvider).updateInvoice(widget.id, {
        'invoice_number': _number.text.trim(),
        'issue_date': _issueDate.text.trim(),
        'due_date': _dueDate.text.trim(),
        'notes': _notes.text.trim(),
      });
      ref.invalidate(invoicesProvider);
      if (mounted) context.go('/accounts/invoices/${widget.id}');
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice could not be saved: $error')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit invoice')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again'))])))
            : Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: Form(key: _form, child: ListView(padding: const EdgeInsets.all(20), children: [
                Text('Update invoice details', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 18),
                TextFormField(controller: _number, decoration: const InputDecoration(labelText: 'Invoice number'), validator: _required),
                const SizedBox(height: 14),
                TextFormField(controller: _issueDate, decoration: const InputDecoration(labelText: 'Issue date (YYYY-MM-DD)'), validator: _date),
                const SizedBox(height: 14),
                TextFormField(controller: _dueDate, decoration: const InputDecoration(labelText: 'Due date (YYYY-MM-DD)'), validator: _date),
                const SizedBox(height: 14),
                TextFormField(controller: _notes, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Notes')),
                const SizedBox(height: 20),
                FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator()) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving…' : 'Save changes')),
              ])))),
  );

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'This field is required.' : null;
  String? _date(String? value) => DateTime.tryParse(value ?? '') == null ? 'Enter a date in YYYY-MM-DD format.' : null;
}

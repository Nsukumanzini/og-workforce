import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';

class BusinessBrainModuleScreen extends ConsumerStatefulWidget {
  const BusinessBrainModuleScreen({super.key, required this.table, required this.title, required this.fields});
  final String table;
  final String title;
  final List<String> fields;

  @override
  ConsumerState<BusinessBrainModuleScreen> createState() => _BusinessBrainModuleScreenState();
}

class _BusinessBrainModuleScreenState extends ConsumerState<BusinessBrainModuleScreen> {
  List<Map<String, dynamic>> rows = [];
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final workspace = ref.read(workspaceControllerProvider).value;
    if (workspace == null) return;
    try {
      final result = await ref.read(businessBrainRepositoryProvider).list(widget.table, workspace.id, orderBy: 'created_at');
      if (mounted) setState(() { rows = result; loading = false; });
    } catch (_) { if (mounted) setState(() => loading = false); }
  }

  Future<void> _edit([Map<String, dynamic>? existing]) async {
    final controllers = {for (final field in widget.fields) field: TextEditingController(text: '${existing?[field] ?? ''}')};
    final saved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(existing == null ? 'Add ${widget.title}' : 'Edit ${widget.title}'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final field in widget.fields) Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: controllers[field], decoration: InputDecoration(labelText: field.replaceAll('_', ' ')))),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () async {
        final workspace = ref.read(workspaceControllerProvider).value;
        if (workspace == null) return;
        final values = {for (final entry in controllers.entries) entry.key: entry.value.text.trim()};
        if (existing?['id'] != null) values['id'] = existing!['id'];
        try { await ref.read(businessBrainRepositoryProvider).save(widget.table, workspace.id, values); if (context.mounted) Navigator.pop(context, true); }
        catch (_) { if (context.mounted) Navigator.pop(context); }
      }, child: const Text('Save'))],
    ));
    for (final controller in controllers.values) { controller.dispose(); }
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title), actions: [IconButton(onPressed: () => _edit(), icon: const Icon(Icons.add))]),
    body: loading ? const Center(child: CircularProgressIndicator()) : rows.isEmpty
      ? Center(child: FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: Text('Add ${widget.title}')))
      : ListView.builder(padding: const EdgeInsets.all(16), itemCount: rows.length, itemBuilder: (_, index) {
          final row = rows[index];
          return Card(child: ListTile(title: Text('${row[widget.fields.first] ?? widget.title}'), subtitle: Text(widget.fields.skip(1).map((f) => '${row[f] ?? ''}').where((v) => v.trim().isNotEmpty).join(' • ')), trailing: IconButton(onPressed: () => _edit(row), icon: const Icon(Icons.edit))));
        }),
  );
}

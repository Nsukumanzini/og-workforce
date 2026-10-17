import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';

class BusinessBrainModuleScreen extends ConsumerStatefulWidget {
  const BusinessBrainModuleScreen({
    super.key,
    required this.table,
    required this.title,
    required this.fields,
    this.fixedValues = const {},
    this.description,
  });

  final String table;
  final String title;
  final List<String> fields;
  final Map<String, dynamic> fixedValues;
  final String? description;

  @override
  ConsumerState<BusinessBrainModuleScreen> createState() => _BusinessBrainModuleScreenState();
}

class _BusinessBrainModuleScreenState extends ConsumerState<BusinessBrainModuleScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  bool get _canArchive => const {
    'business_locations', 'departments', 'business_contacts', 'escalation_contacts',
    'products', 'services', 'packages', 'knowledge_entries',
  }.contains(widget.table);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final workspace = ref.read(workspaceControllerProvider).value;
      if (workspace == null) throw Exception('Your business workspace is not available.');
      final orderBy = switch (widget.table) {
        'pricing_rules' || 'customer_engagement_profiles' => 'updated_at',
        'organisation_languages' => null,
        _ => 'created_at',
      };
      final result = await ref.read(businessBrainRepositoryProvider).list(widget.table, workspace.id, orderBy: orderBy);
      final rows = result.where((row) => widget.fixedValues.entries.every((entry) => row[entry.key] == entry.value)).toList();
      if (mounted) setState(() { _rows = rows; _loading = false; });
    } catch (error) {
      if (mounted) setState(() { _error = _friendlyError(error); _loading = false; });
    }
  }

  Future<void> _edit([Map<String, dynamic>? existing]) async {
    final controllers = <String, TextEditingController>{
      for (final field in widget.fields)
        field: TextEditingController(text: _fieldText(existing?[field], field)),
    };
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add ${widget.title}' : 'Edit ${widget.title}'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (widget.description != null) ...[
                Align(alignment: Alignment.centerLeft, child: Text(widget.description!, style: Theme.of(dialogContext).textTheme.bodyMedium)),
                const SizedBox(height: 14),
              ],
              for (final field in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: controllers[field],
                    minLines: _isLongText(field) ? 3 : 1,
                    maxLines: _isLongText(field) ? 5 : 1,
                    keyboardType: _isNumeric(field) ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: _label(field),
                      hintText: _isJsonList(field) ? 'Enter one item per line' : null,
                    ),
                  ),
                ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () async {
              final workspace = ref.read(workspaceControllerProvider).value;
              if (workspace == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your business workspace is not available.')));
                return;
              }
              final values = <String, dynamic>{...widget.fixedValues};
              for (final entry in controllers.entries) {
                final converted = _convert(entry.key, entry.value.text.trim());
                if (identical(converted, _invalid)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('${_label(entry.key)} must be a valid ${_isBoolean(entry.key) ? 'yes/no value' : 'number'}.')),
                  );
                  return;
                }
                if (converted != _invalid) values[entry.key] = converted;
              }
              if (existing?['id'] != null) values['id'] = existing!['id'];
              try {
                await ref.read(businessBrainRepositoryProvider).save(widget.table, workspace.id, values);
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
                }
              }
            },
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save'),
          ),
        ],
      ),
    );
    for (final controller in controllers.values) { controller.dispose(); }
    if (saved == true) _load();
  }

  Future<void> _archive(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Archive ${widget.title.toLowerCase()} item?'),
        content: const Text('Archived items stop appearing as active Business Brain knowledge.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep item')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Archive')),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    final workspace = ref.read(workspaceControllerProvider).value;
    if (workspace == null) return;
    try {
      await ref.read(businessBrainRepositoryProvider).archive(widget.table, workspace.id, id);
      _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded)),
        IconButton(tooltip: 'Add ${widget.title}', onPressed: () => _edit(), icon: const Icon(Icons.add_rounded)),
        const SizedBox(width: 8),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? _MessageState(message: _error!, actionLabel: 'Try again', onAction: _load)
            : _rows.isEmpty
                ? _MessageState(
                    icon: Icons.auto_awesome_outlined,
                    message: 'Nothing here yet. Add your first ${widget.title.toLowerCase()} item to make it available to your team.',
                    actionLabel: 'Add ${widget.title}',
                    onAction: () => _edit(),
                  )
                : Center(child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1020),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _rows.length,
                      itemBuilder: (context, index) {
                        final row = _rows[index];
                        final visibleFields = widget.fields.where((field) => !widget.fixedValues.containsKey(field)).toList();
                        final titleField = visibleFields.isEmpty ? widget.fields.first : visibleFields.first;
                        final title = '${row[titleField] ?? widget.title}';
                        final details = widget.fields.where((field) => field != titleField)
                            .map((field) => '${row[field] ?? ''}'.trim())
                            .where((value) => value.isNotEmpty)
                            .take(2)
                            .join(' · ');
                        return Padding(padding: const EdgeInsets.only(bottom: 10), child: Card(child: ListTile(
                          contentPadding: const EdgeInsets.only(left: 16, right: 8, top: 5, bottom: 5),
                          leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.secondaryContainer, child: Icon(Icons.article_outlined, color: Theme.of(context).colorScheme.onSecondaryContainer)),
                          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: details.isEmpty ? null : Text(details, maxLines: 2, overflow: TextOverflow.ellipsis),
                          onTap: () => _edit(row),
                          trailing: PopupMenuButton<String>(
                            tooltip: 'More actions',
                            onSelected: (value) => value == 'edit' ? _edit(row) : _archive(row),
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit'), contentPadding: EdgeInsets.zero)),
                              if (_canArchive) const PopupMenuItem(value: 'archive', child: ListTile(leading: Icon(Icons.archive_outlined), title: Text('Archive'), contentPadding: EdgeInsets.zero)),
                            ],
                          ),
                        )));
                      },
                    ),
                  )),
  );
}

const Object _invalid = Object();

Object? _convert(String field, String value) {
  if (value.isEmpty) return null;
  if (_isBoolean(field)) {
    if (const {'true', 'yes'}.contains(value.toLowerCase())) return true;
    if (const {'false', 'no'}.contains(value.toLowerCase())) return false;
    return _invalid;
  }
  if (_isJsonList(field)) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded;
    } catch (_) {}
    return value.split('\n').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  }
  if (_isInteger(field)) return int.tryParse(value) ?? _invalid;
  if (_isNumeric(field)) return num.tryParse(value) ?? _invalid;
  return value;
}

String _fieldText(Object? value, String field) {
  if (value is List && _isJsonList(field)) return value.map((item) => '$item').join('\n');
  return value?.toString() ?? '';
}

bool _isBoolean(String field) => const {'active', 'is_primary', 'customer_visible', 'is_default', 'follow_up_allowed', 'prices_may_be_discussed', 'discounts_may_be_mentioned', 'vat_registered', 'discounts_allowed', 'negotiation_allowed', 'deposit_required', 'negotiable'}.contains(field);
bool _isJsonList(String field) => const {'customer_types', 'target_locations', 'preferred_channels', 'supported_languages'}.contains(field);
bool _isInteger(String field) => const {'year_established', 'estimated_duration_minutes', 'quotation_valid_days', 'invoice_due_days', 'follow_up_interval_hours', 'maximum_follow_up_attempts', 'priority'}.contains(field);
bool _isNumeric(String field) => _isInteger(field) || const {'price', 'minimum_price', 'maximum_ai_discount_percent', 'maximum_discount_percent', 'deposit_value', 'maximum_automatic_discount_percent', 'default_vat_percent', 'deposit_percent', 'call_out_fee', 'delivery_fee', 'minimum_order_value'}.contains(field);
bool _isLongText(String field) => const {'description', 'customer_notes', 'internal_notes', 'customer_terms', 'content', 'guidance', 'complaint_handling_instructions', 'vip_handling_notes', 'stop_contact_rules', 'availability_notes', 'cancellation_fee', 'late_payment_policy'}.contains(field) || field.endsWith('_notes');
String _label(String value) => value.split('_').map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
String _friendlyError(Object error) => error.toString().replaceFirst('Exception: ', '').replaceFirst('AppFailure: ', '');

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, required this.actionLabel, required this.onAction, this.icon = Icons.error_outline_rounded});
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: onAction, icon: Icon(actionLabel.startsWith('Try') ? Icons.refresh_rounded : Icons.add_rounded), label: Text(actionLabel)),
    ]),
  )));
}

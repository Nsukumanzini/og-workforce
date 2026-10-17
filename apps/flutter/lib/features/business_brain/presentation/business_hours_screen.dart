import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';

class BusinessHoursScreen extends ConsumerStatefulWidget { const BusinessHoursScreen({super.key}); @override ConsumerState<BusinessHoursScreen> createState() => _BusinessHoursScreenState(); }
class _BusinessHoursScreenState extends ConsumerState<BusinessHoursScreen> {
  static const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final open = List<bool>.filled(7, false), from = List.generate(7, (_) => TextEditingController()), to = List.generate(7, (_) => TextEditingController());
  final ids = List<String?>.filled(7, null);
  final timezone = TextEditingController(text: 'Africa/Johannesburg');
  bool busy = true, saving = false;
  String? error;
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { for (final controller in [...from, ...to, timezone]) { controller.dispose(); } super.dispose(); }
  String _time(dynamic value) { final text = '${value ?? ''}'; return text.length >= 5 ? text.substring(0, 5) : text; }
  Future<void> _load() async {
    setState(() { busy = true; error = null; });
    try { final w = ref.read(workspaceControllerProvider).value; if (w == null) throw Exception('Business workspace is not available.'); final rows = await ref.read(businessBrainRepositoryProvider).list('business_hours', w.id, orderBy: 'weekday'); for (final row in rows) { final i = (row['weekday'] as int) - 1; if (i >= 0 && i < 7) { ids[i] = row['id']?.toString(); open[i] = row['is_open'] == true; from[i].text = _time(row['opens_at']); to[i].text = _time(row['closes_at']); timezone.text = '${row['timezone'] ?? timezone.text}'; } } }
    catch (e) { error = '$e'; }
    if (mounted) setState(() => busy = false);
  }
  Future<void> _save() async {
    final w = ref.read(workspaceControllerProvider).value; if (w == null) return;
    for (var i = 0; i < 7; i++) { if (open[i] && (from[i].text.isEmpty || to[i].text.isEmpty || from[i].text.compareTo(to[i].text) >= 0)) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${days[i]} needs opening and closing times in order.'))); return; } }
    setState(() => saving = true);
    try { for (var i = 0; i < 7; i++) { final saved = await ref.read(businessBrainRepositoryProvider).save('business_hours', w.id, {if (ids[i] != null) 'id': ids[i], 'weekday': i + 1, 'is_open': open[i], 'opens_at': open[i] ? from[i].text : null, 'closes_at': open[i] ? to[i].text : null, 'timezone': timezone.text.trim()}); ids[i] = saved['id']?.toString(); } if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business hours saved.'))); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Business hours could not be saved: $e'))); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Business Hours'), actions: [IconButton(tooltip: 'Save hours', onPressed: busy || saving ? null : _save, icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator()) : const Icon(Icons.save))]), body: busy ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!), TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Try again'))]))) : Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: ListView(padding: const EdgeInsets.all(16), children: [TextField(controller: timezone, decoration: const InputDecoration(labelText: 'Timezone')), const SizedBox(height: 12), ...List.generate(7, (i) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Row(children: [Expanded(child: Text(days[i], style: Theme.of(context).textTheme.titleMedium)), Text(open[i] ? 'Open' : 'Closed'), Switch(value: open[i], onChanged: saving ? null : (v) => setState(() => open[i] = v))]), if (open[i]) Row(children: [Expanded(child: TextField(controller: from[i], keyboardType: TextInputType.datetime, decoration: const InputDecoration(labelText: 'Opens', hintText: '09:00'))), const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('to')), Expanded(child: TextField(controller: to[i], keyboardType: TextInputType.datetime, decoration: const InputDecoration(labelText: 'Closes', hintText: '17:00')))])])))]))));
}

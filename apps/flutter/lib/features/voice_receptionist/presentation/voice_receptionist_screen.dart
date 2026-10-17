import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../voice_receptionist_providers.dart';
import '../data/voice_receptionist_models.dart';

class VoiceReceptionistScreen extends ConsumerStatefulWidget {
  const VoiceReceptionistScreen({super.key});
  @override
  ConsumerState<VoiceReceptionistScreen> createState() => _VoiceState();
}

class _VoiceState extends ConsumerState<VoiceReceptionistScreen> {
  final number = TextEditingController(), name = TextEditingController(), text = TextEditingController();
  VoiceRunResult? result;
  bool busy = false;
  @override void dispose() { number.dispose(); name.dispose(); text.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final agent = ref.watch(voiceAgentProvider), policy = ref.watch(voicePolicyProvider);
    return Scaffold(appBar: AppBar(title: const Text('Voice Receptionist'), actions: [IconButton(tooltip: 'Refresh', onPressed: () { ref.invalidate(voiceAgentProvider); ref.invalidate(voicePolicyProvider); }, icon: const Icon(Icons.refresh))]), body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: ListView(padding: const EdgeInsets.all(20), children: [
      agent.when(loading: () => const LinearProgressIndicator(), error: (e, _) => _Failure(text: 'Agent status could not be loaded: $e', retry: () => ref.invalidate(voiceAgentProvider)), data: (state) => Card(child: ListTile(title: Text(state.active ? 'Active' : 'Paused'), subtitle: Text(state.connected ? 'Voice provider connected.' : 'Voice provider is not connected. Live calls require a connected provider. Use the simulator below to test.'), trailing: FilledButton(onPressed: busy ? null : () async { try { await ref.read(voiceRepositoryProvider).status(state.active ? 'paused' : 'active'); ref.invalidate(voiceAgentProvider); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status could not be changed: $e'))); } }, child: Text(state.active ? 'Pause' : 'Activate')))),
      const SizedBox(height: 10),
      policy.when(loading: () => const LinearProgressIndicator(), error: (e, _) => _Failure(text: 'Voice policy could not be loaded: $e', retry: () => ref.invalidate(voicePolicyProvider)), data: (value) => Card(child: ListTile(title: const Text('Reception policy'), subtitle: Text('Enquiries ${value.basic ? 'on' : 'off'} • escalation ${value.escalation ? 'on' : 'off'} • ${value.tone.replaceAll('_', ' ')}'), trailing: const Icon(Icons.edit_outlined), onTap: () => _editPolicy(value)))),
      const Divider(height: 32), Text('Try a simulated call', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8),
      TextField(controller: number, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Caller number')),
      const SizedBox(height: 10), TextField(controller: name, decoration: const InputDecoration(labelText: 'Caller name (optional)')),
      const SizedBox(height: 10), TextField(controller: text, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'What the caller says')),
      const SizedBox(height: 12), FilledButton.icon(onPressed: busy ? null : _run, icon: const Icon(Icons.play_arrow), label: Text(busy ? 'Processing…' : 'Run simulated call')),
      if (result != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Call result', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text('Category: ${result!.category}'), Text('Response: ${result!.response}'), Text('Summary: ${result!.summary}'), Text('Action: ${result!.action}'), Text('Escalated: ${result!.escalated ? 'Yes' : 'No'}')]))),
    ]))));
  }

  Future<void> _run() async {
    if (number.text.trim().isEmpty || text.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the caller number and what they said.'))); return; }
    setState(() => busy = true);
    try { result = await ref.read(voiceRepositoryProvider).run(number.text.trim(), name.text.trim(), text.text.trim()); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulation failed: $e'))); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _editPolicy(VoicePolicy initial) async {
    var basic = initial.basic, escalation = initial.escalation, appointments = initial.appointments, sensitive = initial.sensitive, tone = initial.tone;
    final updated = await showDialog<VoicePolicy>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(title: const Text('Reception policy'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [SwitchListTile(value: basic, onChanged: (v) => setDialogState(() => basic = v), title: const Text('Answer basic enquiries')), SwitchListTile(value: escalation, onChanged: (v) => setDialogState(() => escalation = v), title: const Text('Escalate requests to a person')), SwitchListTile(value: appointments, onChanged: (v) => setDialogState(() => appointments = v), title: const Text('Capture appointment requests')), SwitchListTile(value: sensitive, onChanged: (v) => setDialogState(() => sensitive = v), title: const Text('Escalate sensitive requests')), DropdownButtonFormField<String>(value: tone, decoration: const InputDecoration(labelText: 'Tone'), items: const ['professional_friendly', 'professional', 'friendly'].map((v) => DropdownMenuItem(value: v, child: Text(v.replaceAll('_', ' ')))).toList(), onChanged: (v) => setDialogState(() => tone = v ?? tone))])), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, VoicePolicy.fromJson({'basic_enquiries_enabled': basic, 'human_escalation_enabled': escalation, 'appointment_capture_enabled': appointments, 'sensitive_requests_escalate': sensitive, 'default_tone': tone})), child: const Text('Save'))])));
    if (updated == null) return;
    try { await ref.read(voiceRepositoryProvider).save(updated); ref.invalidate(voicePolicyProvider); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Policy could not be saved: $e'))); }
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.text, required this.retry});
  final String text; final VoidCallback retry;
  @override Widget build(BuildContext context) => Column(children: [Text(text), TextButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Try again'))]);
}

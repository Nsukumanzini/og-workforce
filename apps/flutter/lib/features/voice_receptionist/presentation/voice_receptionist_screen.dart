import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/voice_receptionist_models.dart';
import '../voice_receptionist_providers.dart';

class VoiceReceptionistScreen extends ConsumerStatefulWidget {
  const VoiceReceptionistScreen({super.key});

  @override
  ConsumerState<VoiceReceptionistScreen> createState() => _VoiceState();
}

class _VoiceState extends ConsumerState<VoiceReceptionistScreen> {
  final number = TextEditingController();
  final name = TextEditingController();
  final transcript = TextEditingController();
  VoiceRunResult? result;
  bool busy = false;

  @override
  void dispose() {
    number.dispose();
    name.dispose();
    transcript.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agent = ref.watch(voiceAgentProvider);
    final policy = ref.watch(voicePolicyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Receptionist'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(voiceAgentProvider);
              ref.invalidate(voicePolicyProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              agent.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => _Failure(
                  text: 'Agent status could not be loaded: $error',
                  retry: () => ref.invalidate(voiceAgentProvider),
                ),
                data: (state) => Card(
                  child: ListTile(
                    title: Text(state.active ? 'Active' : 'Paused'),
                    subtitle: Text(
                      state.connected
                          ? 'Voice provider connected.'
                          : 'Voice provider is not connected. Live calls require a connected provider. Use the simulator below to test.',
                    ),
                    trailing: FilledButton(
                      onPressed: busy ? null : () => _setAgentStatus(state.active ? 'paused' : 'active'),
                      child: Text(state.active ? 'Pause' : 'Activate'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              policy.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => _Failure(
                  text: 'Voice policy could not be loaded: $error',
                  retry: () => ref.invalidate(voicePolicyProvider),
                ),
                data: (value) => Card(
                  child: ListTile(
                    title: const Text('Reception policy'),
                    subtitle: Text(
                      'Enquiries ${value.basic ? 'on' : 'off'} • escalation ${value.escalation ? 'on' : 'off'} • ${value.tone.replaceAll('_', ' ')}',
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _editPolicy(value),
                  ),
                ),
              ),
              const Divider(height: 32),
              Text('Try a simulated call', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              TextField(controller: number, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Caller number')),
              const SizedBox(height: 10),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Caller name (optional)')),
              const SizedBox(height: 10),
              TextField(controller: transcript, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'What the caller says')),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: busy ? null : _run,
                icon: const Icon(Icons.play_arrow),
                label: Text(busy ? 'Processing…' : 'Run simulated call'),
              ),
              if (result != null) _resultCard(context, result!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultCard(BuildContext context, VoiceRunResult value) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Call result', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Category: ${value.category}'),
            Text('Response: ${value.response}'),
            Text('Summary: ${value.summary}'),
            Text('Action: ${value.action}'),
            Text('Escalated: ${value.escalated ? 'Yes' : 'No'}'),
          ]),
        ),
      );

  Future<void> _setAgentStatus(String status) async {
    setState(() => busy = true);
    try {
      await ref.read(voiceRepositoryProvider).status(status);
      ref.invalidate(voiceAgentProvider);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status could not be changed: $error')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _run() async {
    if (number.text.trim().isEmpty || transcript.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the caller number and what they said.')));
      return;
    }
    setState(() => busy = true);
    try {
      result = await ref.read(voiceRepositoryProvider).run(number.text.trim(), name.text.trim(), transcript.text.trim());
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulation failed: $error')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _editPolicy(VoicePolicy initial) async {
    var basic = initial.basic;
    var escalation = initial.escalation;
    var appointments = initial.appointments;
    var sensitive = initial.sensitive;
    var tone = initial.tone;
    final updated = await showDialog<VoicePolicy>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reception policy'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SwitchListTile(value: basic, onChanged: (value) => setDialogState(() => basic = value), title: const Text('Answer basic enquiries')),
              SwitchListTile(value: escalation, onChanged: (value) => setDialogState(() => escalation = value), title: const Text('Escalate requests to a person')),
              SwitchListTile(value: appointments, onChanged: (value) => setDialogState(() => appointments = value), title: const Text('Capture appointment requests')),
              SwitchListTile(value: sensitive, onChanged: (value) => setDialogState(() => sensitive = value), title: const Text('Escalate sensitive requests')),
              DropdownButtonFormField<String>(
                value: tone,
                decoration: const InputDecoration(labelText: 'Tone'),
                items: const ['professional_friendly', 'professional', 'friendly']
                    .map((value) => DropdownMenuItem(value: value, child: Text(value.replaceAll('_', ' '))) )
                    .toList(),
                onChanged: (value) => setDialogState(() => tone = value ?? tone),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, VoicePolicy.fromJson({
                'basic_enquiries_enabled': basic,
                'human_escalation_enabled': escalation,
                'appointment_capture_enabled': appointments,
                'sensitive_requests_escalate': sensitive,
                'default_tone': tone,
              })),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (updated == null) return;
    try {
      await ref.read(voiceRepositoryProvider).save(updated);
      ref.invalidate(voicePolicyProvider);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Policy could not be saved: $error')));
    }
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.text, required this.retry});
  final String text;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(text),
        TextButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
      ]);
}

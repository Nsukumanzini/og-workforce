import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../data/business_assistant_repository.dart';

class BusinessAssistantScreen extends ConsumerStatefulWidget { const BusinessAssistantScreen({super.key}); @override ConsumerState<BusinessAssistantScreen> createState() => _BusinessAssistantScreenState(); }
class _BusinessAssistantScreenState extends ConsumerState<BusinessAssistantScreen> {
  final input = TextEditingController(); AssistantSession? session; List<AssistantMessage> messages = []; bool busy = false;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final sessions = await ref.read(businessAssistantRepositoryProvider).listSessions(); if (sessions.isNotEmpty) { session = sessions.first; messages = await ref.read(businessAssistantRepositoryProvider).messages(session!.id); } if (mounted) setState(() {}); }
  Future<void> _send() async { final text = input.text.trim(); if (text.isEmpty || session == null || busy) return; input.clear(); setState(() { busy = true; messages = [...messages, AssistantMessage(role: 'user', content: text)]; }); try { messages = [...messages, await ref.read(businessAssistantRepositoryProvider).send(session!.id, text)]; } catch (_) { messages = [...messages, const AssistantMessage(role: 'assistant', content: 'The Business Assistant is temporarily unavailable.')]; } if (mounted) setState(() => busy = false); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Business Assistant')), body: Column(children: [Expanded(child: messages.isEmpty ? const Center(child: Text('Ask about your business.')) : ListView(children: messages.map((message) => ListTile(title: Text(message.content), subtitle: message.sources.isEmpty ? null : Text(message.sources.map((source) => source.label).join(', ')))).toList())), Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: input, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'Ask your Business Assistant'))), IconButton(onPressed: busy ? null : _send, icon: const Icon(Icons.send))]))]));
}

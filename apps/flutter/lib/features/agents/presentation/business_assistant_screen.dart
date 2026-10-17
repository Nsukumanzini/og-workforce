import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../data/business_assistant_repository.dart';

class BusinessAssistantScreen extends ConsumerStatefulWidget {
  const BusinessAssistantScreen({super.key});

  @override
  ConsumerState<BusinessAssistantScreen> createState() => _BusinessAssistantScreenState();
}

class _BusinessAssistantScreenState extends ConsumerState<BusinessAssistantScreen> {
  final input = TextEditingController();
  AssistantSession? session;
  List<AssistantSession> sessions = [];
  List<AssistantMessage> messages = [];
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { busy = true; error = null; });
    try {
      final repo = ref.read(businessAssistantRepositoryProvider);
      sessions = await repo.listSessions();
      if (sessions.isNotEmpty) {
        session = sessions.first;
        messages = await repo.messages(session!.id);
      } else {
        session = null;
        messages = [];
      }
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _newSession() async {
    setState(() => busy = true);
    try {
      final created = await ref.read(businessAssistantRepositoryProvider).createSession();
      sessions = [created, ...sessions];
      session = created;
      messages = [];
      error = null;
    } catch (e) {
      error = 'Could not create a conversation: $e';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _select(AssistantSession selected) async {
    setState(() { busy = true; session = selected; error = null; });
    try {
      messages = await ref.read(businessAssistantRepositoryProvider).messages(selected.id);
    } catch (e) {
      error = 'Could not load this conversation: $e';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _send() async {
    final text = input.text.trim();
    if (text.isEmpty || busy) return;
    if (session == null) {
      await _newSession();
      if (session == null) return;
    }
    input.clear();
    setState(() {
      busy = true;
      error = null;
      messages = [...messages, AssistantMessage(role: 'user', content: text)];
    });
    try {
      messages = [...messages, await ref.read(businessAssistantRepositoryProvider).send(session!.id, text)];
    } catch (e) {
      messages = messages.where((message) => message.role != 'user' || message.content != text).toList();
      error = 'Your message was not sent: $e';
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Business Assistant'),
          actions: [
            if (sessions.isNotEmpty)
              PopupMenuButton<AssistantSession>(
                tooltip: 'Conversation history',
                icon: const Icon(Icons.history),
                onSelected: _select,
                itemBuilder: (_) => sessions
                    .map((value) => PopupMenuItem(value: value, child: Text(value.title, maxLines: 1, overflow: TextOverflow.ellipsis)))
                    .toList(),
              ),
            IconButton(tooltip: 'New conversation', onPressed: busy ? null : _newSession, icon: const Icon(Icons.add_comment_outlined)),
          ],
        ),
        body: Column(
          children: [
            if (error != null)
              MaterialBanner(
                content: Text(error!),
                leading: const Icon(Icons.error_outline),
                actions: [TextButton(onPressed: _load, child: const Text('Retry'))],
              ),
            Expanded(
              child: busy && messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? const Center(child: Text('Start a conversation. Ask about your business.'))
                      : ListView(
                          padding: const EdgeInsets.all(12),
                          children: messages.map((message) => _messageCard(context, message)).toList(),
                        ),
            ),
            if (busy) const LinearProgressIndicator(),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      onSubmitted: (_) => _send(),
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: 'Ask your Business Assistant'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(tooltip: 'Send', onPressed: busy ? null : _send, icon: const Icon(Icons.send)),
                ]),
              ),
            ),
          ],
        ),
      );

  Widget _messageCard(BuildContext context, AssistantMessage message) => Align(
        alignment: message.role == 'user' ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Card(
            color: message.role == 'user' ? Theme.of(context).colorScheme.primaryContainer : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(message.content),
                if (message.sources.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _showSources(message.sources),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: Text('${message.sources.length} sources'),
                  ),
              ]),
            ),
          ),
        ),
      );

  Future<void> _showSources(List<AssistantSource> sources) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => ListView(
          padding: const EdgeInsets.all(20),
          shrinkWrap: true,
          children: [
            Text('Sources', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...sources.map((source) => ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(source.label),
                  subtitle: Text([
                    if (source.page != null) 'Page ${source.page}',
                    if (source.sheet != null) 'Sheet ${source.sheet}',
                  ].join(' • ')),
                )),
          ],
        ),
      );
}

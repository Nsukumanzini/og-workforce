import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_providers.dart';

class DocumentVaultScreen extends ConsumerStatefulWidget { const DocumentVaultScreen({super.key}); @override ConsumerState<DocumentVaultScreen> createState() => _DocumentVaultScreenState(); }
class _DocumentVaultScreenState extends ConsumerState<DocumentVaultScreen> {
  late Future<List<Map<String, dynamic>>> documents;
  @override void initState() { super.initState(); documents = _load(); }
  Future<List<Map<String, dynamic>>> _load() async { final workspace = ref.read(workspaceControllerProvider).value; if (workspace == null) return []; return ref.read(businessBrainRepositoryProvider).list('documents', workspace.id, orderBy: 'created_at'); }
  void reload() => setState(() => documents = _load());
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Documents'),
          actions: [IconButton(tooltip: 'Refresh', onPressed: reload, icon: const Icon(Icons.refresh))],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/tenders'),
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload document'),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: documents,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _EmptyState(text: 'Documents could not be loaded: ${snapshot.error}', onTap: reload);
            }
            final rows = snapshot.data!;
            if (rows.isEmpty) {
              return _EmptyState(
                text: 'No business documents yet. Upload tender documents from the Tender Agent.',
                onTap: () => context.go('/tenders'),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Private documents available to your workspace.'),
                  const SizedBox(height: 12),
                  ...rows.map((row) {
                    final name = '${row['title'] ?? row['filename'] ?? 'Business document'}';
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(name),
                        subtitle: Text('${row['classification'] ?? 'Document'} • ${row['created_at'] ?? ''}'),
                        trailing: const Icon(Icons.info_outline),
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          builder: (ctx) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, style: Theme.of(ctx).textTheme.titleLarge),
                              const SizedBox(height: 12),
                              Text('Classification: ${row['classification'] ?? 'Unknown'}'),
                              Text('Added: ${row['created_at'] ?? 'Unknown'}'),
                              Text('Status: ${row['status'] ?? 'Pending'}'),
                            ]),
                          ),
                        ),
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
class _EmptyState extends StatelessWidget { const _EmptyState({required this.text, required this.onTap}); final String text; final VoidCallback onTap; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.folder_open_outlined, size: 44), const SizedBox(height: 12), Text(text, textAlign: TextAlign.center), const SizedBox(height: 12), OutlinedButton.icon(onPressed: onTap, icon: const Icon(Icons.upload_file), label: const Text('Open Tender Agent'))]))); }

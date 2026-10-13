import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tenders_providers.dart';

class TenderDashboardScreen extends ConsumerWidget {
  const TenderDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunities = ref.watch(tenderOpportunitiesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tender Agent')),
      body: opportunities.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton(
              onPressed: () async {
                await ref.read(tendersRepositoryProvider).run();
                ref.invalidate(tenderOpportunitiesProvider);
              },
              child: const Text('Run Tender Agent'),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Card(
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.reference} • ${item.buyer}\nCloses ${item.closingAt}',
                  ),
                  trailing: Text(item.status),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TenderOpportunityScreen(id: item.id),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TenderOpportunityScreen extends ConsumerWidget {
  const TenderOpportunityScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = FutureProvider.autoDispose(
      (ref) => ref.read(tendersRepositoryProvider).opportunity(id),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Tender opportunity')),
      body: ref
          .watch(provider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (bundle) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  bundle.opportunity.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(bundle.opportunity.reference),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    await ref.read(tendersRepositoryProvider).openWorkspace(id);
                    if (context.mounted)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TenderWorkspaceScreen(
                            id: bundle.workspace?['id']?.toString() ?? id,
                          ),
                        ),
                      );
                  },
                  child: const Text('Open workspace'),
                ),
              ],
            ),
          ),
    );
  }
}

class TenderWorkspaceScreen extends ConsumerWidget {
  const TenderWorkspaceScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = FutureProvider.autoDispose(
      (ref) => ref.read(tendersRepositoryProvider).workspace(id),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Tender workspace')),
      body: ref
          .watch(provider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (bundle) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  bundle.opportunity.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                _PickerCard(
                  workspaceId: bundle.workspace?['id']?.toString() ?? id,
                  onUploaded: () => ref.invalidate(provider),
                ),
                const SizedBox(height: 12),
                const Text('Documents'),
                ...bundle.documents.map(
                  (document) => ListTile(
                    title: Text(
                      '${document['metadata']?['filename'] ?? document['document_id'] ?? 'Document'}',
                    ),
                    subtitle: Text('${document['document_role'] ?? 'source'}'),
                  ),
                ),
                const Divider(),
                const Text('Drafts'),
                ...bundle.drafts.map(
                  (draft) => ListTile(
                    title: Text('${draft['draft_type']}'),
                    subtitle: Text('${draft['status']}'),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _PickerCard extends ConsumerStatefulWidget {
  const _PickerCard({required this.workspaceId, required this.onUploaded});
  final String workspaceId;
  final VoidCallback onUploaded;
  @override
  ConsumerState<_PickerCard> createState() => _PickerCardState();
}

class _PickerCardState extends ConsumerState<_PickerCard> {
  String? message;
  bool uploading = false;
  Future<void> pick() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx', 'xlsx', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (!mounted || result == null) return;
    final file = result.files.single;
    if (file.bytes == null || file.size > 10 * 1024 * 1024) {
      setState(() => message = 'Choose a supported file smaller than 10 MB.');
      return;
    }
    setState(() {
      uploading = true;
      message = 'Uploading ${file.name}…';
    });
    try {
      final upload = await ref
          .read(tendersRepositoryProvider)
          .uploadWorkspaceDocument(workspaceId: widget.workspaceId, file: file);
      ref.invalidate(tenderSummaryProvider);
      widget.onUploaded();
      setState(
        () => message = upload.processingStatus == 'ready'
            ? 'Document processed successfully.'
            : upload.processingStatus == 'requires_ocr'
            ? 'Document uploaded. OCR processing is required.'
            : upload.processingStatus == 'failed'
            ? 'Document uploaded, but processing failed.'
            : 'Document uploaded and is being processed.',
      );
    } catch (_) {
      setState(
        () => message =
            'Document upload failed. Please verify the file and try again.',
      );
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Tender document'),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: uploading ? null : pick,
            child: Text(uploading ? 'Uploading…' : 'Select file'),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(message!),
            ),
        ],
      ),
    ),
  );
}

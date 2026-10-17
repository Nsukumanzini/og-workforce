import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';

class BusinessBrainScreen extends ConsumerWidget {
  const BusinessBrainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brain = ref.watch(businessBrainSnapshotProvider).value;
    final sections = <_BrainSection>[
      _BrainSection('Company Profile', Icons.business_outlined, brain?.companyProfile != null, 'Legal identity and contact details', brain?.companyProfile != null ? 'Complete' : 'Not started', '/business-brain/company-profile'),
      _BrainSection('Locations', Icons.location_on_outlined, false, 'Branches, offices, and operating sites', 'Not started', '/business-brain/locations'),
      _BrainSection('Business Hours', Icons.schedule_outlined, brain?.hasHours ?? false, 'Weekly operating hours and timezone', brain?.hasHours == true ? 'Configured' : 'Not configured', '/business-brain/hours'),
      _BrainSection('Contacts & Departments', Icons.contacts_outlined, brain?.hasContactOrEscalation ?? false, 'People, teams, and responsibilities', '${brain?.counts['contacts'] ?? 0} contacts', '/business-brain/contacts'),
      _BrainSection('Products', Icons.inventory_2_outlined, brain != null && brain.activeProducts > 0, 'Customer-facing products and pricing', '${brain?.activeProducts ?? 0} active', '/business-brain/products'),
      _BrainSection('Services', Icons.handyman_outlined, brain != null && brain.activeServices > 0, 'Services, quotes, deposits, and terms', '${brain?.activeServices ?? 0} active', '/business-brain/services'),
      _BrainSection('Packages', Icons.layers_outlined, false, 'Simple product and service bundles', 'Not started', '/business-brain/packages'),
      _BrainSection('Pricing Rules', Icons.sell_outlined, brain?.hasPricing ?? false, 'Commercial rules and discount boundaries', brain?.hasPricing == true ? 'Configured' : 'Not configured', '/business-brain/pricing'),
      _BrainSection('Customer Engagement', Icons.forum_outlined, brain?.hasEngagement ?? false, 'Audience, tone, channels, and follow-up rules', brain?.hasEngagement == true ? 'Configured' : 'Not started', '/business-brain/engagement'),
      _BrainSection('Escalation Rules', Icons.call_merge_outlined, brain?.hasContactOrEscalation ?? false, 'Contacts for sensitive or urgent cases', '${brain?.counts['escalations'] ?? 0} configured', '/business-brain/escalations'),
      _BrainSection('FAQs & Policies', Icons.menu_book_outlined, false, 'Structured answers and customer policies', 'Not started', '/business-brain/knowledge'),
      _BrainSection('Documents', Icons.folder_outlined, brain != null && brain.documents > 0, 'Private business documents and certificates', '${brain?.documents ?? 0} files', '/business-brain/documents'),
      _BrainSection('Activity', Icons.history, false, 'Safe history of Business Brain changes', 'View activity', '/business-brain/activity'),
    ];
    final completed = sections.where((section) => section.complete).length;
    final completion = completed / sections.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Business Brain')),
      body: LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 3 : constraints.maxWidth >= 600 ? 2 : 1;
        return ListView(padding: const EdgeInsets.all(24), children: [
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${(completion * 100).round()}% complete', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('$completed of ${sections.length} knowledge sections are ready for your future workforce.', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: completion, minHeight: 10)),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: () => context.go('/business-brain/company-profile'), icon: const Icon(Icons.edit_outlined), label: const Text('Edit Company Profile')),
            const SizedBox(height: 16),
            GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: sections.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: columns == 1 ? 4.2 : 2.3), itemBuilder: (_, index) => _SectionCard(section: sections[index])),
          ])),
        ]);
      }),
    );
  }
}

class _BrainSection {
  const _BrainSection(this.title, this.icon, this.complete, this.description, this.status, this.route);
  final String title;
  final IconData icon;
  final bool complete;
  final String description;
  final String status;
  final String route;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});
  final _BrainSection section;
  @override
  Widget build(BuildContext context) => Card(child: InkWell(onTap: () => context.go(section.route), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
    CircleAvatar(child: Icon(section.icon)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(section.title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(section.description, maxLines: 2, overflow: TextOverflow.ellipsis),
    ])), const SizedBox(width: 8), Chip(label: Text(section.complete ? 'Complete' : section.status), avatar: Icon(section.complete ? Icons.check : Icons.circle_outlined, size: 16)),
  ]))));
}

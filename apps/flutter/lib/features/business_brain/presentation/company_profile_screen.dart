import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/validation/validators.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});
  @override
  ConsumerState<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  bool _loading = true;
  bool _saving = false;

  static const _fields = [
    'business_type', 'industry', 'description', 'slogan', 'year_established',
    'country_code', 'region', 'city', 'physical_address', 'postal_address', 'phone', 'email', 'sales_email',
    'support_email', 'website', 'registration_number', 'vat_number', 'tax_number', 'csd_number', 'bbbee_status',
  ];

  @override
  void initState() {
    super.initState();
    for (final field in _fields) { _controllers[field] = TextEditingController(); }
    _load();
  }

  Future<void> _load() async {
    final snapshot = await ref.read(businessBrainSnapshotProvider.future);
    final profile = snapshot?.companyProfile ?? const <String, dynamic>{};
    for (final field in _fields) {
      _controllers[field]!.text = profile[field]?.toString() ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() { for (final controller in _controllers.values) { controller.dispose(); } super.dispose(); }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final workspace = ref.read(workspaceControllerProvider).value;
    if (workspace == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(businessBrainRepositoryProvider).save('business_profiles', workspace.id, {
        for (final field in _fields)
          field: switch (field) {
            'year_established' => int.tryParse(_controllers[field]!.text.trim()),
            'country_code' => _controllers[field]!.text.trim().isEmpty ? null : _controllers[field]!.text.trim().toUpperCase(),
            _ => _controllers[field]!.text.trim().isEmpty ? null : _controllers[field]!.text.trim(),
          },
        'organisation_id': workspace.id,
      });
      ref.invalidate(businessBrainSnapshotProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company Profile saved.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final workspace = ref.watch(workspaceControllerProvider).value;
    Widget field(String key, String label, {int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(controller: _controllers[key], maxLines: maxLines, keyboardType: keyboardType, validator: validator, decoration: InputDecoration(labelText: label)),
    );
    return Scaffold(appBar: AppBar(title: const Text('Company Profile')), body: Form(key: _form, child: ListView(padding: const EdgeInsets.all(24), children: [
      if (workspace != null) ...[
        Text('Legal organisation name', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(workspace.name, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
      ],
      Text('Business identity', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
      field('business_type', 'Business type'), field('industry', 'Industry'), field('description', 'Description', maxLines: 4), field('slogan', 'Tagline'), field('year_established', 'Year established', keyboardType: TextInputType.number, validator: (v) { if (v == null || v.isEmpty) return null; final year = int.tryParse(v); return year == null || year < 1800 || year > DateTime.now().year ? 'Enter a valid year.' : null; }),
      const SizedBox(height: 12), Text('Address', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
      field('country_code', 'Country code', validator: Validators.country), field('region', 'Province / state'), field('city', 'City / town'), field('physical_address', 'Physical address', maxLines: 3), field('postal_address', 'Postal address', maxLines: 3),
      const SizedBox(height: 12), Text('Contact', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
      field('phone', 'Main phone'), field('email', 'Main email', validator: (v) => v == null || v.isEmpty ? null : Validators.email(v)), field('sales_email', 'Sales email', validator: (v) => v == null || v.isEmpty ? null : Validators.email(v)), field('support_email', 'Support email', validator: (v) => v == null || v.isEmpty ? null : Validators.email(v)), field('website', 'Website'),
      const SizedBox(height: 12), Text('Restricted compliance information', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8),
      const Text('Only permitted organisation roles should edit these fields.'), const SizedBox(height: 16), field('registration_number', 'Company registration number'), field('vat_number', 'VAT number'), field('tax_number', 'Tax reference'), field('csd_number', 'CSD supplier number'), field('bbbee_status', 'B-BBEE level / status'),
      const SizedBox(height: 12), FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator()) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Save profile')),
    ])));
  }
}

import 'package:flutter/material.dart';
class CustomerEngagementScreen extends StatelessWidget { const CustomerEngagementScreen({super.key}); @override Widget build(BuildContext context) => const _BrainPage('Customer engagement'); }
class LanguagesScreen extends StatelessWidget { const LanguagesScreen({super.key}); @override Widget build(BuildContext context) => const _BrainPage('Languages'); }
class KnowledgeEntriesScreen extends StatelessWidget { const KnowledgeEntriesScreen({super.key, required this.type}); final String type; @override Widget build(BuildContext context) => _BrainPage(type == 'policy' ? 'Policies' : 'FAQs'); }
class _BrainPage extends StatelessWidget { const _BrainPage(this.title); final String title; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Text('$title are managed in the Business Brain.'))); }

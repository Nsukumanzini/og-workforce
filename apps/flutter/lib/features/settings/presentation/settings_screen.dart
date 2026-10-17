import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../app/theme/workforce_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value?.user;
    final workspace = ref.watch(workspaceControllerProvider).value;
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: ListView(padding: EdgeInsets.fromLTRB(width < 600 ? 18 : 28, 22, width < 600 ? 18 : 28, 40), children: [
          Text('Manage your workspace', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('Your account, workspace details, and connected tools.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 22),
          _SettingsSection(title: 'Account', children: [
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Your account',
              subtitle: user?.email ?? 'Account details unavailable',
              onTap: () => showDialog<void>(context: context, builder: (context) => AlertDialog(
                title: const Text('Account details'),
                content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Name not provided'),
                  const SizedBox(height: 6),
                  Text(user?.email ?? 'Email unavailable'),
                  if (workspace != null) ...[const SizedBox(height: 12), Text('Workspace: ${workspace.name}')],
                ]),
                actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
              )),
            ),
            _SettingsTile(icon: Icons.business_outlined, title: 'Company profile', subtitle: 'Business identity and contact details', onTap: () => context.go('/business-brain/company-profile')),
            _SettingsTile(icon: Icons.groups_2_outlined, title: 'AI Workforce', subtitle: 'View your AI teammates and pending work', onTap: () => context.go('/workforce')),
            _SettingsTile(icon: Icons.credit_card_outlined, title: 'Plan & billing', subtitle: 'Review your plan and usage', onTap: () => context.go('/billing')),
          ]),
          const SizedBox(height: 18),
          _SettingsSection(title: 'Integrations', children: [
            _SettingsTile(icon: Icons.chat_bubble_outline_rounded, title: 'WhatsApp', subtitle: 'Connection status and agent controls', onTap: () => context.go('/agents/whatsapp')),
            _SettingsTile(icon: Icons.email_outlined, title: 'Email', subtitle: 'Agent controls and reply policy', onTap: () => context.go('/agents/email')),
            _SettingsTile(icon: Icons.phone_in_talk_outlined, title: 'Voice', subtitle: 'Receptionist controls and call simulator', onTap: () => context.go('/agents/voice')),
            _SettingsTile(icon: Icons.forum_outlined, title: 'Unified Inbox', subtitle: 'Review and respond to customer conversations', onTap: () => context.go('/inbox')),
          ]),
          const SizedBox(height: 18),
          _SettingsSection(title: 'Workspace', children: [
            _SettingsTile(icon: Icons.auto_awesome_outlined, title: 'Business Brain', subtitle: 'Manage the information your AI team can use', onTap: () => context.go('/business-brain')),
            _SettingsTile(icon: Icons.history_rounded, title: 'Audit activity', subtitle: 'Review changes made in your workspace', onTap: () => context.go('/business-brain/activity')),
          ]),
          const SizedBox(height: 18),
          Card(child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFFBE9E7), child: Icon(Icons.logout_rounded, color: Color(0xFFB5473C))),
            title: const Text('Log out'),
            subtitle: const Text('Sign out of this device'),
            trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
            onTap: () => _confirmSignOut(context, ref),
          )),
        ]),
      )),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final signOut = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You can sign back in with your account details.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay signed in')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
      ],
    ));
    if (signOut == true) await ref.read(authControllerProvider.notifier).signOut();
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(left: 4, bottom: 9), child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
    Card(child: Column(children: [for (var i = 0; i < children.length; i++) ...[if (i > 0) const Divider(indent: 68, endIndent: 12), children[i]]])),
  ]);
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(backgroundColor: WorkforceTheme.mint, foregroundColor: WorkforceTheme.forest, child: Icon(icon, size: 20)),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/auth_screens.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/business_brain/presentation/business_brain_screen.dart';
import '../../features/business_brain/presentation/business_brain_module_screen.dart';
import '../../features/business_brain/presentation/company_profile_screen.dart';
import '../../features/business_brain/presentation/business_hours_screen.dart';
import '../../features/business_brain/presentation/organisation_structure_screen.dart';
import '../../features/business_brain/presentation/commercial_core_screen.dart';
import '../../features/business_brain/presentation/knowledge_communication_screens.dart';
import '../../features/business_brain/presentation/document_vault_screen.dart';
import '../../features/business_brain/presentation/business_brain_activity_screen.dart';
import '../../features/agents/presentation/business_assistant_screen.dart';
import '../../features/email_agent/presentation/email_agent_screen.dart';
import '../../features/voice_receptionist/presentation/voice_receptionist_screen.dart';
import '../../features/workforce/presentation/workforce_screen.dart';
import '../../features/billing/presentation/billing_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/workspace/presentation/workspace_onboarding_screen.dart';
import '../../features/workspace/domain/workspace.dart';
import '../app_providers.dart';
import '../shell/splash_screen.dart';
import '../../features/crm/presentation/crm_screens.dart';
import '../../features/crm/presentation/whatsapp_agent_screen.dart';
import '../../features/accounts/presentation/accounts_screens.dart'; import '../../features/accounts/presentation/accounts_admin_screens.dart';
import '../../features/accounts/presentation/invoice_edit_screen.dart'; import '../../features/accounts/presentation/accounts_policy_screen.dart';
import '../../features/tenders/presentation/tender_screens.dart';

String? appRouteRedirect({
  required AuthState auth,
  required AsyncValue<Workspace?> workspace,
  required String path,
}) {
  const publicRoutes = {'/welcome', '/sign-in', '/sign-up', '/forgot-password', '/reset-password'};
  if (auth.phase == AuthPhase.loading || workspace.isLoading) return path == '/splash' ? null : '/splash';
  if (auth.phase == AuthPhase.signedOut) return publicRoutes.contains(path) ? null : '/welcome';
  if (path == '/reset-password') return null;
  final currentWorkspace = workspace.value;
  if (currentWorkspace == null || !currentWorkspace.onboardingComplete) return path == '/onboarding' ? null : '/onboarding';
  if (path == '/dashboard' || path == '/workforce' || path == '/billing' || path == '/settings' || path == '/business-brain' || path.startsWith('/business-brain/') || path == '/agents/business-assistant' || path == '/agents/email' || path == '/agents/voice' || path == '/crm' || path.startsWith('/crm/') || path == '/inbox' || path.startsWith('/inbox/') || path == '/agents/whatsapp' || path == '/accounts' || path.startsWith('/accounts/') || path == '/agents/accounts' || path == '/tenders' || path.startsWith('/tenders/')) return null;
  return '/dashboard';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider).value ?? const AuthState.loading();
  final workspace = ref.watch(workspaceControllerProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) => appRouteRedirect(auth: auth, workspace: workspace, path: state.matchedLocation),
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (_, __) => const SignUpScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const WorkspaceOnboardingScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/workforce', builder: (_, __) => const WorkforceScreen()),
      GoRoute(path: '/billing', builder: (_, __) => const BillingScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/agents/business-assistant', builder: (_, __) => const BusinessAssistantScreen()),
      GoRoute(path: '/agents/email', builder: (_, __) => const EmailAgentScreen()),
      GoRoute(path: '/agents/voice', builder: (_, __) => const VoiceReceptionistScreen()),
      GoRoute(path: '/agents/whatsapp', builder: (_, __) => const WhatsAppAgentScreen()),
      GoRoute(path: '/crm', builder: (_, __) => const CrmScreen()),
      GoRoute(path: '/crm/contacts/:id', builder: (_, state) => ContactDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/inbox', builder: (_, __) => const InboxScreen()),
      GoRoute(path: '/inbox/:id', builder: (_, state) => ConversationScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/accounts', builder: (_, __) => const AccountsDashboard()),
      GoRoute(path: '/accounts/invoices', builder: (_, state) => InvoiceListScreen(contactId: state.uri.queryParameters['contactId'])),
      GoRoute(path: '/accounts/invoices/new', builder: (_, __) => const InvoiceCreateScreen()),
      GoRoute(path: '/accounts/invoices/:id', builder: (_, state) => InvoiceDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/accounts/invoices/:id/edit', builder: (_, state) => InvoiceEditScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/accounts/policy', builder: (_, __) => const AccountsPolicyScreen()),
      GoRoute(path: '/accounts/approvals', builder: (_, __) => const AccountsApprovalsScreen()),
      GoRoute(path: '/agents/accounts', builder: (_, __) => const AccountsAgentScreen()),
      GoRoute(path: '/tenders', builder: (_, __) => const TenderDashboardScreen()),
      GoRoute(path: '/tenders/:id/workspace', builder: (_, state) => TenderWorkspaceScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/business-brain', builder: (_, __) => const BusinessBrainScreen()),
      GoRoute(path: '/business-brain/company-profile', builder: (_, __) => const CompanyProfileScreen()),
      GoRoute(path: '/business-brain/locations', builder: (_, __) => const BusinessBrainModuleScreen(table: 'business_locations', title: 'Locations', fields: ['name', 'location_type', 'address', 'city', 'region', 'country_code', 'postal_code', 'phone', 'email', 'is_primary', 'active'])),
      GoRoute(path: '/business-brain/hours', builder: (_, __) => const BusinessHoursScreen()),
      GoRoute(path: '/business-brain/contacts', builder: (_, __) => const BusinessBrainModuleScreen(table: 'business_contacts', title: 'Contacts', fields: ['full_name', 'job_title', 'department_id', 'location_id', 'email', 'phone', 'preferred_contact_method', 'active'])),
      GoRoute(path: '/business-brain/departments', builder: (_, __) => const BusinessBrainModuleScreen(table: 'departments', title: 'Departments', fields: ['name', 'active'])),
      GoRoute(path: '/business-brain/products', builder: (_, __) => const BusinessBrainModuleScreen(table: 'products', title: 'Products', fields: ['name', 'category', 'description', 'price', 'currency', 'tax_behavior', 'unit', 'minimum_price', 'maximum_ai_discount_percent', 'availability_status', 'customer_notes', 'internal_notes', 'status'])),
      GoRoute(path: '/business-brain/services', builder: (_, __) => const BusinessBrainModuleScreen(table: 'services', title: 'Services', fields: ['name', 'category', 'description', 'pricing_model', 'price', 'currency', 'tax_behavior', 'estimated_duration_minutes', 'deposit_value', 'maximum_discount_percent', 'service_area', 'customer_notes', 'internal_notes', 'status'])),
      GoRoute(path: '/business-brain/packages', builder: (_, __) => const BusinessBrainModuleScreen(table: 'packages', title: 'Packages', fields: ['name', 'description', 'price', 'currency', 'tax_behavior', 'valid_from', 'valid_until', 'customer_terms', 'active'])),
      GoRoute(path: '/business-brain/pricing', builder: (_, __) => const BusinessBrainModuleScreen(table: 'pricing_rules', title: 'Pricing Rules', fields: ['default_currency', 'vat_registered', 'default_vat_percent', 'payment_terms', 'deposit_percent', 'quotation_valid_days', 'invoice_due_days', 'discounts_allowed', 'maximum_automatic_discount_percent', 'negotiation_allowed', 'call_out_fee', 'delivery_fee', 'minimum_order_value', 'cancellation_fee', 'late_payment_policy'])),
      GoRoute(path: '/business-brain/engagement', builder: (_, __) => const BusinessBrainModuleScreen(table: 'customer_engagement_profiles', title: 'Customer Engagement', description: 'Set the tone, channels, and follow-up guidelines that shape customer conversations.', fields: ['customer_types', 'target_locations', 'preferred_channels', 'communication_tone', 'guidance', 'preferred_greeting', 'preferred_closing', 'supported_languages', 'follow_up_allowed', 'follow_up_interval_hours', 'maximum_follow_up_attempts', 'stop_contact_rules', 'prices_may_be_discussed', 'discounts_may_be_mentioned', 'complaint_handling_instructions', 'vip_handling_notes'])),
      GoRoute(path: '/business-brain/languages', builder: (_, __) => const BusinessBrainModuleScreen(table: 'organisation_languages', title: 'Languages', description: 'Add language codes such as en, zu, or af. Set one language as the default.', fields: ['language_code', 'is_default'])),
      GoRoute(path: '/business-brain/escalations', builder: (_, __) => const BusinessBrainModuleScreen(table: 'escalation_contacts', title: 'Escalation Contacts', fields: ['category', 'primary_contact_id', 'secondary_contact_id', 'phone', 'email', 'availability_notes', 'priority', 'active'])),
      GoRoute(path: '/business-brain/knowledge', builder: (_, __) => const BusinessBrainModuleScreen(table: 'knowledge_entries', title: 'FAQs', description: 'Record answers the AI team can use. Keep customer visibility turned off for internal guidance.', fixedValues: {'entry_type': 'faq'}, fields: ['title', 'category', 'content', 'customer_visible', 'active'])),
      GoRoute(path: '/business-brain/policies', builder: (_, __) => const BusinessBrainModuleScreen(table: 'knowledge_entries', title: 'Policies', description: 'Add clear policy guidance for consistent customer responses.', fixedValues: {'entry_type': 'policy'}, fields: ['title', 'category', 'content', 'customer_visible', 'active'])),
      GoRoute(path: '/business-brain/documents', builder: (_, __) => const DocumentVaultScreen()),
      GoRoute(path: '/business-brain/activity', builder: (_, __) => const BusinessBrainActivityScreen()),
    ],
  );
});


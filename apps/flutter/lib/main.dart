import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/app_providers.dart';
import 'core/config/app_config.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/workspace/data/workspace_repository.dart';
import 'features/business_brain/data/business_brain_repository.dart';
import 'features/agents/data/business_assistant_repository.dart';
import 'features/crm/crm_providers.dart';
import 'features/crm/data/crm_inbox_repository.dart';
import 'features/accounts/accounts_providers.dart'; import 'features/accounts/data/accounts_repository.dart';
import 'features/tenders/tenders_providers.dart'; import 'features/tenders/data/tenders_repository.dart';
import 'features/email_agent/email_agent_providers.dart'; import 'features/email_agent/data/email_agent_repository.dart';
import 'features/voice_receptionist/voice_receptionist_providers.dart'; import 'features/voice_receptionist/data/voice_receptionist_repository.dart';
import 'features/workforce/workforce_providers.dart'; import 'features/workforce/data/workforce_repository.dart';
import 'features/billing/billing_providers.dart'; import 'features/billing/data/billing_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  AuthRepository authRepository = const UnconfiguredAuthRepository();
  WorkspaceRepository workspaceRepository = const UnconfiguredWorkspaceRepository();
  BusinessBrainRepository businessBrainRepository = const UnconfiguredBusinessBrainRepository();
  SupabaseClient? supabaseClient;
  if (config.isConfigured) {
    await Supabase.initialize(url: config.supabaseUrl, anonKey: config.supabasePublishableKey);
    supabaseClient = Supabase.instance.client;
    authRepository = SupabaseAuthRepository(supabaseClient);
    workspaceRepository = SupabaseWorkspaceRepository(supabaseClient);
    businessBrainRepository = SupabaseBusinessBrainRepository(supabaseClient);
  }
  final client = supabaseClient;
  runApp(ProviderScope(overrides: [
    authRepositoryProvider.overrideWithValue(authRepository),
    workspaceRepositoryProvider.overrideWithValue(workspaceRepository),
    businessBrainRepositoryProvider.overrideWithValue(businessBrainRepository),
    if (client != null) ...[
      businessAssistantRepositoryProvider.overrideWithValue(BusinessAssistantRepository(config.apiBaseUrl, client)),
      crmInboxRepositoryProvider.overrideWithValue(CrmInboxRepository(config.apiBaseUrl, client)),
      accountsRepositoryProvider.overrideWithValue(AccountsRepository(config.apiBaseUrl, client)),
      tendersRepositoryProvider.overrideWithValue(TendersRepository(config.apiBaseUrl, client)),
      emailAgentRepositoryProvider.overrideWithValue(EmailAgentRepository(config.apiBaseUrl, client)),
      voiceRepositoryProvider.overrideWithValue(VoiceReceptionistRepository(config.apiBaseUrl, client)),
      workforceRepositoryProvider.overrideWithValue(WorkforceRepository(config.apiBaseUrl, client)),
      billingRepositoryProvider.overrideWithValue(BillingRepository(config.apiBaseUrl, client)),
    ],
  ], child: const WorkforceApp()));
}

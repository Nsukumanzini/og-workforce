# Development setup

## Flutter configuration

The Flutter client reads only two build-time values:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

Keep real values outside source control. Copy `apps/flutter/.env.example` to a local ignored file, then supply its values as `--dart-define` flags:

```powershell
flutter run --dart-define=SUPABASE_URL=https://your-development-project.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_your_key
```

The same flags apply to web, Android, Windows, iOS, and macOS builds. The app centralises initialization in `lib/main.dart`; widgets do not read environment values.

Never supply a service-role key, database password, AI-provider key, payment credential, or integration secret to Flutter.

## Development backend procedure

1. Use the Supabase plugin with project ref `xlgmmvabbezpmuqqzioy`.
2. Review the remote migration list before applying changes.
3. Apply the repository SQL through the Supabase plugin and record the returned remote migration name/version in the mapping below.
4. Run `supabase/tests/auth_workspace_rls.sql` against non-production users only.

The migrations remain the database source of truth. Do not reproduce migration objects manually in the dashboard.

### Plugin migration mapping

The repository filenames remain canonical. The Supabase-plugin apply operation recorded these remote names and versions:

| Repository migration | Remote applied migration |
| --- | --- |
| `20260924000100_phase_1_foundation.sql` | `20260925055329_phase_1_foundation` |
| `20260924000200_authentication_workspace_onboarding.sql` | `20260925055342_authentication_workspace_onboarding` |
| `20260925000300_database_quality_indexes.sql` | `20260925060327_database_quality_indexes` |
| `20260925000400_restrict_workspace_rpc_execution.sql` | `20260925060428_restrict_workspace_rpc_execution` |
| `20260926000100_business_brain_v1.sql` | `20260925174244_business_brain_v1` |
| `20260926000200_business_brain_indexes.sql` | `20260925174536_business_brain_indexes` |
| `20260926000300_business_brain_policy_cleanup.sql` | `20260925192659_business_brain_policy_cleanup` |
| `20260928000100_business_assistant_v1.sql` | `20260928163118_business_assistant_v1` |
| `20260928000200_business_assistant_runs.sql` | `20260928185120_business_assistant_runs` |
| `20260928000300_business_assistant_vector_search.sql` | `20260928203022_business_assistant_vector_search` |
| `20260930140000_tender_agent_v1.sql` | `20260930120655_tender_agent_v1` |
| `20260930150000_tender_agent_indexes.sql` | `20260930121920_tender_agent_indexes` |
| `20260930160000_tender_document_vector_scope.sql` | `20260930153420_tender_document_vector_scope` |

For future schema changes, retain the local SQL file, apply the same SQL through the Supabase plugin, and add its returned remote mapping here. Do not edit Supabase migration-history tables manually.

## Development workflow

Feature implementation proceeds continuously across the platform. Flutter analyzer,
test, platform-build, live persistence, tenant-isolation, storage-isolation,
advisor, and end-to-end checks are collected for the dedicated final verification
phase rather than repeatedly blocking feature work on known machine-level stalls.
Security boundaries and RLS remain enforced during implementation, and unresolved
verification items are recorded for that final phase.

## Auth environment policy

Development currently has email/password authentication enabled with **Confirm Email temporarily disabled** so the isolated development project can run live foundation checks. The built-in Supabase mail service is not production email infrastructure.

Production must enable Confirm Email, configure a custom SMTP or email provider, set production redirect URLs, and review Auth delivery rate limits before release.

The Free plan currently reports `auth_leaked_password_protection` as unavailable. Development enforces an eight-character password with an uppercase letter and number; enable leaked-password protection in production if the selected Supabase plan supports it.

Password reset delivery is pending custom SMTP while the development email quota is unavailable. The Flutter client requests the reset through Supabase with the allowed `ogworkforce://reset-password` deep link.

- 20260929000100_whatsapp_crm_unified_inbox.sql -> applied remotely via Supabase plugin (version recorded by Supabase migration history)
## Voice Receptionist migration

- Local: `20261002000100_voice_receptionist_v1.sql`
- Remote Supabase migration: `voice_receptionist_v1`

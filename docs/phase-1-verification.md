# Phase 1 foundation verification

## Verdict

**PHASE 1 FOUNDATION READY** for the next specification. Business Brain V1 has not been started.

## Live development backend

Project: `og-workforce-dev` (`xlgmmvabbezpmuqqzioy`)

- Two genuine disposable development users authenticated successfully.
- Organisation A and Organisation B were created through the protected workspace RPC.
- Each RPC call atomically created the organisation, owner membership, Business Profile, trial subscription, and audit record.
- User A could not read or modify Organisation B.
- User B could not read Organisation A.
- Anonymous reads and workspace creation were blocked.
- Protected role and subscription writes were blocked.
- Password login, refresh-based session restoration, and logout passed.

Development Auth policy: Confirm Email is temporarily disabled only in `og-workforce-dev`. Production must enable Confirm Email and use reliable custom SMTP/email delivery.

Password reset request wiring and redirect configuration are present; delivery remains pending custom SMTP because the built-in development mail service is limited.

## Plugin migration mapping

Repository SQL remains canonical. The Supabase-plugin apply operation recorded:

| Repository file | Remote applied name/version |
| --- | --- |
| `20260924000100_phase_1_foundation.sql` | `20260925055329_phase_1_foundation` |
| `20260924000200_authentication_workspace_onboarding.sql` | `20260925055342_authentication_workspace_onboarding` |
| `20260925000300_database_quality_indexes.sql` | `20260925060327_database_quality_indexes` |
| `20260925000400_restrict_workspace_rpc_execution.sql` | `20260925060428_restrict_workspace_rpc_execution` |

Future migrations must be retained in the repository, applied through the Supabase plugin, and added to this mapping. Migration-history tables are not edited manually.

## Flutter verification

- Route/onboarding guard tests cover unauthenticated redirects, onboarding enforcement, dashboard access, logout protection, loading, and reset-password routing.
- `flutter analyze --no-pub`: PASS.
- `flutter test --no-pub`: PASS, 6 tests.
- Web compiler and Android Gradle stalls remain documented machine-level issues.
- Windows builds still require the Visual Studio Desktop Development with C++ workload.

## Security notes

- RLS remains enabled on all intended public tables.
- Anonymous workspace RPC execution is revoked.
- Flutter exposes only the Supabase URL and publishable key.
- Database passwords, service-role keys, and secret keys are not stored in Flutter or the repository.
- Free-plan leaked-password protection is unavailable; the app enforces an eight-character password with uppercase and numeric characters. Enable the Supabase protection when the production plan supports it.

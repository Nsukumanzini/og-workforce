# Phase 1 architecture

## Scope

Phase 1 establishes the shared application shape, tenant model, access boundaries, and Business Brain schema. It does not implement authentication screens, document uploads, AI chat, integrations, billing, or any agent workflow.

The Flutter app was generated with Android, iOS, web, Windows, and macOS shells. Its shared source modules remain intentionally featureless until the development foundation is verified.

## Flutter application layout

```text
apps/flutter/lib/
  app/
    bootstrap/                 # startup composition and environment loading
    routing/                   # route declarations and guards
    shell/                     # phone navigation and desktop/sidebar shell
    theme/                     # OG Workforce design tokens and themes
  core/
    auth/                      # session contracts; no UI implementation yet
    data/                      # Supabase/API clients and base repositories
    errors/                    # typed failures and error presentation
    permissions/               # client display capability models only
    platform/                  # platform-specific abstractions
  features/
    workspace/                 # organisation selection and onboarding
    business_brain/            # verified company facts
    documents/                 # private document records and processing states
    agents/                    # agent catalogue, config, sessions, actions
    approvals/                 # human approval queue and history
    dashboard/                 # workspace overview
    billing/                   # entitlement display and usage
  shared/
    domain/                    # value types used across features
    widgets/                   # reusable adaptive UI primitives
```

Each feature will contain `domain`, `application`, `data`, and `presentation` folders once implementation starts. Presentation code may request a server action, but it never talks to an LLM provider or external integration directly. Flutter only receives the Supabase publishable key and API base URL at build time.

## Server boundaries

```text
services/api/src/
  auth/          # validates caller identity and active membership
  policy/        # evaluates agent tool permissions and approval requirements
  agents/        # runtime, coordination, session handling
  tools/         # typed, idempotent side-effect handlers
  knowledge/     # retrieval and document ingestion orchestration
  providers/     # model and embedding provider abstractions
  workflows/     # jobs, schedules, retries and event handlers
  integrations/  # WhatsApp, email, telephony, calendar adapters
  audit/         # append-only operational records
```

The policy layer is the server-side authority for every side effect. It checks organisation membership, role permission, agent grant, subscription entitlement, input schema, risk level, and approval before the relevant handler runs. An LLM response cannot bypass it.

## Supabase schema slices

| Slice | Tables in the initial schema | Why now |
|---|---|---|
| Tenant identity | `profiles`, `organisations`, `organisation_members` | Workspace creation and tenant isolation |
| Business Brain | `business_profiles`, `products`, `services` | Structured approved facts before AI answers |
| Knowledge | `documents`, `document_versions`, `document_chunks` | Private, versioned RAG source data |
| Agents and governance | `agent_types`, `agents`, `agent_permissions`, `agent_actions`, `approvals`, `audit_logs` | Extensible agent framework and approval boundary |
| Subscriptions | `plans`, `plan_entitlements`, `subscriptions`, `usage_events` | Prevent features being enabled outside a plan |

All tenant-owned tables have `organisation_id`. RLS derives access from the active membership record rather than user-editable JWT metadata. The migration also grants `authenticated` only the approved read surface, so a project whose Data API requires explicit grants has the same intended behaviour. The application cannot create or alter memberships, approval decisions, audit records, or agent action outcomes through direct client writes.

## First implementation sequence

1. Generate Flutter platform shells and add routing/theme bootstrap.
2. Create a Supabase project, review this migration, apply it, and run RLS isolation checks against two test organisations.
3. Implement Supabase authentication and workspace creation through a narrowly scoped transactional RPC.
4. Implement Business Brain facts and document ingestion.
5. Implement Business Assistant retrieval, policy checked internal task creation, and audit views.

## Authentication and workspace onboarding

Flutter uses `supabase_flutter` behind `AuthRepository` and `WorkspaceRepository`, Riverpod asynchronous controllers, and GoRouter route guards. The app only accepts a Supabase URL and publishable key through build-time defines; it never contains a service-role key.

```text
launch → splash resolver → welcome/sign in
                      └→ signed in → membership check → onboarding or dashboard
```

`20260924000200_authentication_workspace_onboarding.sql` adds the `staff` role, the minimum location and business-type fields required for onboarding, and a starter-trial record. `public.create_initial_workspace` is an invoker RPC wrapper. The privileged insert transaction remains in `private.create_initial_workspace`, locks on `auth.uid()` to prevent double submission, creates the organisation, owner membership, Business Brain profile, trial subscription, and audit event atomically. It accepts no target user ID.

The direct Flutter client has no membership, role, subscription, audit, or organisation write policy. RLS permits tenant scoped reads; the workspace function is the only initial owner-creation path. `supabase/tests/auth_workspace_rls.sql` documents the two-user verification scenarios to run against a linked non-production project.

## Known environment constraints

Flutter source analysis and tests passed before this milestone. Windows binaries require the missing Visual Studio Desktop C++ workload. The local web compiler and Android Gradle build previously stalled; each should be retried once after this milestone with captured logs. No Supabase project is linked yet, so authentication and RLS verification cannot be run against a live database until the migrations are applied.

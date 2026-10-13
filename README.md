# OG Workforce AI

Phase 1 foundation for Optimal Growth Technologies SA's multi-tenant AI workforce platform.

## Structure

- `apps/flutter` — shared Flutter application for Android, iOS, web/PWA, Windows, and macOS.
- `services/api` — future server-side API, policy, workflow, model, and integration adapters.
- `services/api/src/agent-runtime` — provider-neutral Business Assistant runtime, tool registry, and organisation-scoped read tools.
- `packages/contracts` — future versioned API and agent-tool contracts shared by server components.
- `supabase/migrations` — database migrations. The initial migration is a proposed schema and has not been applied to a Supabase project.
- `docs` — architecture decisions and implementation plans.

See `docs/phase-1-architecture.md` before implementing application features.

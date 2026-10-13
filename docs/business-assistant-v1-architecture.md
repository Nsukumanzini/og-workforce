# Business Assistant V1 architecture

The Business Assistant is a read-only organisation-aware agent. Flutter sends
authenticated messages to a server-side runtime; provider credentials never enter
the Flutter application.

The runtime boundary is in `services/api/src/agent-runtime` and contains:

- provider-neutral AI and embedding interfaces
- an organisation-scoped Tool Registry
- automatic/read-only permission enforcement
- structured Business Brain tool definitions
- request context requiring authenticated user, organisation, role, agent, and session

The `20260928000100_business_assistant_v1.sql` migration adds agent sessions,
messages, memories, and document intelligence status fields. It must be applied
through the Supabase plugin and mapped here after the plugin returns its remote
migration version.

Document intelligence remains a server-side pipeline: uploaded → queued →
processing → ready/failed/requires_ocr. Vector retrieval must always filter by
organisation before any similarity search.

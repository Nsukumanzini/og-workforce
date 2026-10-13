# Final verification backlog

## Repository stabilization

- API package manager: npm (`services/api/package.json`); API is a standalone workspace with no root package manifest. Node v24.16.0 and npm 11.13.0 are available, with no repository engine constraint.
- The Windows default npm cache remains inaccessible with `EPERM`/`EACCES`. `npm install --cache .npm-cache --loglevel verbose` completed with exit code 0 using the repository-local cache; it generated `package-lock.json`, `node_modules`, and local `node_modules/.bin/tsc`.
- API typecheck now passes with the repository-managed TypeScript compiler. The fixes cover Tender dispatcher syntax and tool contracts, typed Supabase repository table results, Cloudflare document Blob conversion, and Email dispatcher fallback typing.

## Billing final integration

- Paystack configuration and live checkout
- Payment success and failed-payment handling
- Payment webhook verification and idempotency
- Renewal, cancellation, downgrade, and trial-expiry behaviour
- Usage reset and plan enforcement across every Agent, including AI monthly limits
- Flutter upgrade flow and final pricing
- Billing RLS verification
- Full Flutter analyzer and release builds

## Flutter stabilization

- Initial bundled-Dart analysis reported 106 diagnostics; parser-root repairs reduced this to 11 before Tender upload integration.
- Tender document upload is implemented through the authenticated multipart API, byte-based cross-platform Flutter handling, and workspace-provider refresh after a successful server response.
- Flutter tests remain subject to the Codex Flutter SDK lock restriction; Dart telemetry access warnings are environment-only.

## Phase 2 remote security verification

- Remote project `djxiieetcvnxmrlgumnr` contains the foundation, Business Brain, Business Assistant, CRM/Inbox, Tender vector scope, and Voice migrations. The canonical Accounts & Collections migration was missing remotely and was applied as `accounts_collections_agent_v1`.
- The private `business-brain-documents` bucket remains private, has a 10 MB limit, and allows only PDF, DOCX, XLSX, PNG, and JPEG. Its object policies derive organisation access from the first object-path segment.
- All inspected organisation-owned public tables have RLS enabled and membership-scoped policies. The write policies inspected use both `USING` and `WITH CHECK`; no inspected policy uses `user_metadata` for authorization.
- `search_scoped_document_chunks` remains SECURITY INVOKER and RLS-protected. Its inherited PUBLIC execution was removed through `restrict_document_search_rpc_execution`; only `authenticated` now has execution permission.
- Tender Flutter uploads now set the allowlisted multipart MIME type explicitly, matching the authenticated backend contract.
- The Tender storage helper now supplies an `ArrayBuffer` request body accepted by the Cloudflare fetch type definition; `npm.cmd run typecheck` passes after this repair.
- The remote project currently has zero Auth users, organisations, memberships, documents, conversations, invoices, Tender workspaces, agent runs, and voice calls. Authenticated two-tenant, storage, and workflow E2E verification is pending suitable development users and seed organisations; it must not be claimed from schema inspection alone.
- Live tenant-bootstrap attempt: public sign-up is enabled, but `mailer_autoconfirm` is false and the mail sender returned `over_email_send_rate_limit`. The connected Supabase plugin has no Auth-admin user-creation operation, and computer-use access to the dashboard did not initialize. No users or application data were created.
- Admin-bootstrap follow-up: `services/api` declares `SUPABASE_URL` and optional `SUPABASE_SERVICE_ROLE_KEY`, but the local verification environment has no service-role secret file, configured server-side admin client, or credential source available. No secret was retrieved, created, or exposed.
- Recheck after local configuration notice: this Codex API execution shell still reports both `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` absent, and `services/api` contains no `.env` or `.dev.vars` file. The Admin Auth bootstrap cannot run until those values are available to this process.

- Customer engagement persistence and permission behaviour
- Language persistence and one-default-language rule
- Supported-language persistence
- FAQ persistence and archive behaviour
- Policy persistence and customer visibility handling
- Tenant isolation across knowledge and communication modules
- Role-specific read/write behaviour
- Responsive layouts across phone, tablet, and desktop
- Business Assistant prompt-injection isolation for untrusted document content
- Organisation-scoped tool execution and vector retrieval
- Provider adapter configuration with secrets absent from Flutter
- Conversation persistence, bounded context, confidence classification, and source citations
- Document extraction, OCR-required states, chunk provenance, and archived-document exclusion
- Agent run and AI usage diagnostics without sensitive content logging
- Hono Worker deployment and health endpoint
- Bearer-token authentication and session tenant isolation
- Configured provider inference and missing-provider error handling
- Document processing status transitions and retry idempotency
- Document extraction currently reports `unsupported` for PDF/DOCX/XLSX until a verified Cloudflare Worker-compatible extractor dependency is available; images report `requires_ocr`. The pipeline now normalizes text and preserves document/version/page/sheet provenance for future extraction adapters.
- Vector retrieval is exposed only through the organization-scoped `search_business_document_chunks` RPC and rejects embeddings that are not exactly 1536 dimensions.
- Agent tool execution is capped at four calls per round and permits only registered automatic read tools; write or unknown tools are rejected.
- Live query embeddings and vector retrieval are wired into document-specific Assistant messages. Final verification still needs real Gemini credentials, ready chunks, similarity tuning, hybrid source checks, and outage simulation.
- Assistant responses now de-duplicate document sources, classify retrieval mode, and isolate document evidence as untrusted context. Run/usage telemetry and tool-provider execution remain final verification items.
- Assistant message execution now creates and finalizes `agent_runs` records and records one safe Groq request event in `ai_usage_events`. Live verification still needs provider usage payload mapping, Gemini/document conversion telemetry, failure simulation, and confirmation that no sensitive content enters telemetry.
- Flutter Business Assistant implementation added: authenticated API repository, typed session/message/source models, responsive conversation screen, session reload, new conversation, send/retry messaging, and source chips. Final verification remains for real Worker URL, token expiry, provider errors, responsive layouts, and accessibility.
- WhatsApp/CRM foundation migration added after schema inspection. No prior CRM, unified conversation, message, channel, or integration tables existed; existing agents, sessions, actions, approvals, audit logs, and usage tables remain the shared runtime foundation. Remote application and webhook/live verification remain pending.

- WhatsApp CRM migration applied remotely; provider abstraction and webhook verification scaffold added. Remaining: tenant resolution/persistence, signed webhook authenticity, inbox routes, manual replies, takeover, and Flutter inbox.
- WhatsApp Agent catalogue entry and reusable eligibility/customer-context dispatch boundary added. Actual Groq dispatch, durable duplicate-run claim, CRM write tools, escalation, and outbound AI handling remain the next implementation slice.

- WhatsApp Agent durable claim migration and dispatcher boundary added. Full Groq dispatch, retrieval, tools, escalation, and outbound AI execution remain pending.
- WhatsApp runtime policy and tightly scoped CRM tools added. Full background Groq dispatch, retrieval/tool orchestration, pre-send race recheck, outbound AI handling, and telemetry finalization remain pending implementation and live verification.
- WhatsApp runtime decision types, explicit human-request detection, and conservative stale-claim recovery boundary added. Full background Groq execution and outbound AI orchestration remain pending.
- Added a contained `WhatsAppAgentDispatcher.handle` entry point with guaranteed failure cleanup. Webhook-to-background scheduling still requires a webhook-native trusted organisation context and full Agent execution wiring; no fake authenticated user context was introduced.
- Added explicit `ToolExecutionContext` and actor authorization helpers so organisation-scoped Agent execution does not require a human user. Existing human `RequestContext` tools and routes remain unchanged. Full WhatsApp execution wiring remains pending.
- Organisation-safe Business Brain read handlers now route through `organisationExecutionQuery`; authenticated Business Assistant paths remain available through the existing registry. Full WhatsApp dispatcher execution is still pending and is not declared complete.

- Complaint escalation shortcut added to WhatsApp dispatcher. Document RAG, Tool Registry rounds, controlled CRM tool requests, escalation acknowledgement, and Agent audit/run metadata remain pending.

## WhatsApp Agent V1 closure verification
- human request acknowledgement
- complaint acknowledgement
- tool-driven escalation acknowledgement
- model-driven escalation acknowledgement
- acknowledgement success and Meta failure
- duplicate acknowledgement prevention
- deterministic escalation, RAG, hybrid, tool, race suppression, and normal Meta failure run metadata
- telemetry failure after successful business outcome

## Flutter CRM + Unified Inbox + WhatsApp Agent UI
- live WhatsApp Inbox refresh and inbound delivery
- human reply and delivery/read transitions
- failed Meta send rendering
- takeover and handback against live backend
- Agent pause/resume when endpoint is available
- disconnected integration state
- desktop three-pane layout and mobile navigation
- CRM editing and cross-platform builds

## Accounts & Collections Agent V1
- apply and verify Accounts schema/RLS remotely
- invoice/payment CRUD live verification
- overdue/upcoming deterministic checks
- collection policy and reminder scheduler
- Accounts Agent Tool Registry runtime
- approval workflow for sensitive reminders
- promise-to-pay/dispute handling
- live channel delivery and audit verification

## Accounts & Collections runtime verification
- policy update and authorization
- deterministic stage boundaries
- max reminder and idempotency retries
- promise-to-pay and broken promise
- disputed invoice suppression
- approval-required reminder actions
- manual/scheduled dispatch
- provider/channel restrictions
- tenant isolation and audit/usage telemetry

## Accounts & Collections closure verification
- approval action persistence/resolution
- channel adapter with WhatsApp provider restrictions
- reminder send success/failure and delivery states
- scheduler/manual idempotency
- agent audit and usage coverage
- promise fulfillment/broken transitions
- disputed invoice suppression
- tenant isolation

## Accounts closure verification
- WhatsApp reminder provider/template restrictions
- approval stale-state revalidation and duplicate clicks
- promise fulfillment/broken transitions
- scheduled multi-tenant isolation and retry
- telemetry failure isolation
- audit attribution coverage

## Flutter Accounts & Collections verification
- dashboard metric reconciliation
- invoice filters/search and edit flow
- payment success/partial/full refresh
- promise and dispute refresh
- policy save
- approval outcomes/stale states
- Accounts Agent pause/manual run
- CRM account summary link
- responsive UI and cross-platform builds

## Accounts detail responsive verification
- narrow invoice detail
- tablet/desktop two-column detail
- very-wide constraints
- responsive payment history
- long customer/invoice values
- promise summary and dispute state

## Tender Agent V1

- Tender migration/RLS verification
- Manual source ingestion and duplicate import behavior
- Deadline boundary and expired tender handling
- Requirement extraction and Business Brain matching
- Missing certification and experience evidence handling
- Tender document processing, provenance, and prompt-injection boundaries
- Hybrid company/tender retrieval and draft grounding
- Shared approval flow and agent pause behavior
- Scheduled and manual Tender Agent runs
- Organisation isolation and responsive Flutter Tender screens
- Cross-platform builds and pre-existing Flutter baseline cleanup
- Restore Flutter dependencies, then restore the declared `file_picker` import and verify picker-to-multipart Tender upload.
- Verify unified initial/regenerated draft evidence against live Business Brain and Tender documents.
- Verify shared Tender approval detail, queue refresh, workspace filtering, and internal-only action transitions.
- Verify tablet and desktop Tender workspace layouts with live data.

## Phase 2 verification record — 2026-10-04

- Backend privileged Supabase configuration now resolves `SUPABASE_SECRET_KEY` first, with `SUPABASE_SERVICE_ROLE_KEY` retained as a server-only fallback. Neither variable is exposed to Flutter or responses.
- Two disposable confirmed Auth users were created through Admin Auth, then signed in through normal password sessions. Each created one organisation through `create_initial_workspace`; each has exactly one active owner membership.
- Fixed onboarding defect: the Business Assistant catalogue entry and organisation-scoped active agent are now provisioned atomically for new workspaces; existing workspaces were backfilled.
- Fixed deployed Accounts schema defect: invoices are now unique by `(organisation_id, invoice_number)` instead of incorrectly allowing only one invoice per organisation.
- Normal JWT isolation passed for Business Brain, Tender workspace state, private storage download/signed URLs, and scoped document search. Cross-organisation reads and writes returned no accessible rows or were denied; anonymous scoped RAG execution was denied.
- Normal API smoke reached CRM contact creation (201) and Accounts invoice creation (201). Cross-tenant contact and invoice reads/updates were rejected. The in-process Worker harness does not provide a complete final JSON summary because its local execution context terminates early; this is an environment harness limitation.
- Backend `npm.cmd run typecheck`: PASS.
- Supabase security advisor: no current security lints. Provider-dependent items remain disconnected by design: live Meta WhatsApp, Gmail/Outlook, Paystack, live voice, external Tender submission, Groq/Gemini, and document conversion/embedding services.
- Temporary verification scripts and credentials are not part of the repository; passwords were never written to source, docs, or migrations.

## Phase 2 fast-verification boundary

- Intended API runtime: `services/api` `wrangler dev`, entrypoint `src/index.ts`, bindings from `.env.local` and `wrangler.jsonc`.
- One controlled local runtime attempt produced only Wrangler telemetry output and exited without a usable listener. This is recorded as a local development/runtime tooling issue; the API architecture was not rewritten for testing.
- Provider-independent routes that require a live Worker request context (Unified Inbox conversation lifecycle, Accounts approval execution/revalidation, simulated Voice route, Workforce summary, Billing protection, and telemetry route assertions) remain blocked by the unavailable local runtime harness.
- The exported production Hono app was imported directly and exercised with normal JWTs. CRM creation reached the real route; the Node process terminated while serialising an expected cross-tenant `Contact not found` response, before the harness could produce its aggregate result. This is an in-process runtime/test-context failure, not a security bypass or route substitution.
- Provider-dependent Phase 3 items remain deferred: Meta WhatsApp, Gmail/Outlook, Paystack, live telephony/STT/TTS, external Tender submission, live Groq/Gemini generation, and external document conversion/embedding.
- A remote Wrangler attempt was explicitly authorized for temporary verification, but Wrangler 4.38.0 produced no preview URL or listener output and was stopped after the bounded attempt. No secret values were printed; remote Cloudflare authentication/session setup remains unavailable in this environment.

-- Removes an overlapping RLS policy and adds covering indexes for foreign keys.
-- This is additive and safe to apply to the dedicated OG Workforce development project.

drop policy if exists "profile owner updates profile name" on public.profiles;

create index if not exists agent_actions_organisation_agent_index on public.agent_actions (organisation_id, agent_id);
create index if not exists agent_actions_requested_by_index on public.agent_actions (requested_by);
create index if not exists agent_permissions_organisation_agent_index on public.agent_permissions (organisation_id, agent_id);
create index if not exists agents_agent_type_index on public.agents (agent_type_key);
create index if not exists approvals_decided_by_index on public.approvals (decided_by);
create index if not exists approvals_organisation_action_index on public.approvals (organisation_id, agent_action_id);
create index if not exists approvals_requested_by_index on public.approvals (requested_by);
create index if not exists audit_logs_actor_user_index on public.audit_logs (actor_user_id);
create index if not exists business_profiles_updated_by_index on public.business_profiles (updated_by);
create index if not exists document_chunks_organisation_version_index on public.document_chunks (organisation_id, document_version_id);
create index if not exists document_versions_organisation_document_index on public.document_versions (organisation_id, document_id);
create index if not exists documents_created_by_index on public.documents (created_by);
create index if not exists subscriptions_organisation_index on public.subscriptions (organisation_id);
create index if not exists subscriptions_plan_index on public.subscriptions (plan_id);
create index if not exists usage_events_organisation_index on public.usage_events (organisation_id);
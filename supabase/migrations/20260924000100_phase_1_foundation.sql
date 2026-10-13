-- OG Workforce AI Phase 1 foundation.
-- Draft migration: review and apply only after linking a dedicated Supabase project.

create extension if not exists pgcrypto;
create extension if not exists vector with schema extensions;
create schema if not exists private;

create type public.membership_status as enum ('active', 'invited', 'suspended', 'removed');
create type public.document_status as enum ('pending', 'processing', 'ready', 'failed', 'archived');
create type public.agent_status as enum ('draft', 'active', 'paused', 'archived');
create type public.action_status as enum ('proposed', 'approval_pending', 'approved', 'rejected', 'executing', 'succeeded', 'failed', 'cancelled');
create type public.approval_status as enum ('pending', 'approved', 'rejected', 'expired', 'cancelled');
create type public.action_risk as enum ('allowed', 'approval_required', 'prohibited');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organisations (
  id uuid primary key default gen_random_uuid(),
  legal_name text not null,
  trading_name text,
  timezone text not null default 'Africa/Johannesburg',
  status text not null default 'active' check (status in ('active', 'suspended', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organisation_members (
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role_key text not null check (role_key in ('owner', 'admin', 'manager', 'member', 'viewer')),
  status public.membership_status not null default 'invited',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (organisation_id, user_id)
);

create table public.business_profiles (
  organisation_id uuid primary key references public.organisations(id) on delete cascade,
  registration_number text,
  vat_number text,
  industry text,
  description text,
  email text,
  phone text,
  website text,
  business_hours jsonb not null default '{}'::jsonb,
  communication_tone text,
  data_status text not null default 'draft' check (data_status in ('draft', 'approved')),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  name text not null,
  description text,
  price numeric(14,2),
  currency char(3) not null default 'ZAR',
  status text not null default 'draft' check (status in ('draft', 'approved', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organisation_id, id)
);

create table public.services (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  name text not null,
  description text,
  price numeric(14,2),
  currency char(3) not null default 'ZAR',
  status text not null default 'draft' check (status in ('draft', 'approved', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organisation_id, id)
);

create table public.documents (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  title text not null,
  classification text not null default 'internal' check (classification in ('internal', 'confidential', 'restricted')),
  status public.document_status not null default 'pending',
  storage_path text not null,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  archived_at timestamptz,
  unique (organisation_id, id),
  unique (organisation_id, storage_path)
);

create table public.document_versions (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null,
  document_id uuid not null,
  version_number integer not null check (version_number > 0),
  source_sha256 text not null,
  extracted_text_status public.document_status not null default 'pending',
  created_at timestamptz not null default now(),
  unique (organisation_id, id),
  unique (document_id, version_number),
  foreign key (organisation_id, document_id) references public.documents(organisation_id, id) on delete cascade
);

create table public.document_chunks (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null,
  document_version_id uuid not null,
  chunk_index integer not null check (chunk_index >= 0),
  content text not null,
  source_page integer,
  embedding extensions.vector(1536),
  embedding_model text,
  created_at timestamptz not null default now(),
  unique (organisation_id, id),
  unique (document_version_id, chunk_index),
  foreign key (organisation_id, document_version_id) references public.document_versions(organisation_id, id) on delete cascade
);

create table public.agent_types (
  key text primary key,
  display_name text not null,
  system_managed boolean not null default true,
  description text not null,
  created_at timestamptz not null default now()
);

create table public.agents (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  agent_type_key text not null references public.agent_types(key),
  display_name text not null,
  status public.agent_status not null default 'draft',
  config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organisation_id, id),
  unique (organisation_id, agent_type_key)
);

create table public.agent_permissions (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null,
  agent_id uuid not null,
  tool_key text not null,
  risk public.action_risk not null,
  enabled boolean not null default false,
  constraints jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (agent_id, tool_key),
  foreign key (organisation_id, agent_id) references public.agents(organisation_id, id) on delete cascade
);

create table public.agent_actions (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  agent_id uuid not null,
  requested_by uuid references auth.users(id),
  tool_key text not null,
  risk public.action_risk not null,
  status public.action_status not null default 'proposed',
  input_payload jsonb not null,
  payload_sha256 text not null,
  idempotency_key text not null,
  result_payload jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organisation_id, id),
  unique (organisation_id, idempotency_key),
  foreign key (organisation_id, agent_id) references public.agents(organisation_id, id)
);

create table public.approvals (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null,
  agent_action_id uuid not null,
  requested_by uuid references auth.users(id),
  decided_by uuid references auth.users(id),
  status public.approval_status not null default 'pending',
  payload_sha256 text not null,
  expires_at timestamptz,
  decision_note text,
  created_at timestamptz not null default now(),
  decided_at timestamptz,
  unique (agent_action_id),
  foreign key (organisation_id, agent_action_id) references public.agent_actions(organisation_id, id) on delete cascade
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  actor_user_id uuid references auth.users(id),
  agent_id uuid,
  event_type text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.plans (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  name text not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.plan_entitlements (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.plans(id) on delete cascade,
  entitlement_key text not null,
  limit_value integer,
  unique (plan_id, entitlement_key)
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  plan_id uuid not null references public.plans(id),
  status text not null check (status in ('trial', 'active', 'past_due', 'cancelled')),
  starts_at timestamptz not null,
  ends_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.usage_events (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  entitlement_key text not null,
  quantity integer not null check (quantity > 0),
  occurred_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb
);

create index document_chunks_organisation_index on public.document_chunks (organisation_id);
create index documents_organisation_status_index on public.documents (organisation_id, status);
create index agent_actions_organisation_status_index on public.agent_actions (organisation_id, status, created_at desc);
create index audit_logs_organisation_created_index on public.audit_logs (organisation_id, created_at desc);
create index organisation_members_user_index on public.organisation_members (user_id, status);

alter table public.profiles enable row level security;
alter table public.organisations enable row level security;
alter table public.organisation_members enable row level security;
alter table public.business_profiles enable row level security;
alter table public.products enable row level security;
alter table public.services enable row level security;
alter table public.documents enable row level security;
alter table public.document_versions enable row level security;
alter table public.document_chunks enable row level security;
alter table public.agent_types enable row level security;
alter table public.agents enable row level security;
alter table public.agent_permissions enable row level security;
alter table public.agent_actions enable row level security;
alter table public.approvals enable row level security;
alter table public.audit_logs enable row level security;
alter table public.plans enable row level security;
alter table public.plan_entitlements enable row level security;
alter table public.subscriptions enable row level security;
alter table public.usage_events enable row level security;

create function private.is_active_member(target_organisation_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$ select exists (
  select 1 from public.organisation_members m
  where m.organisation_id = target_organisation_id
    and m.user_id = (select auth.uid())
    and m.status = 'active'
) $$;

create policy "profile owner reads profile" on public.profiles for select to authenticated using ((select auth.uid()) = id);
create policy "profile owner updates profile" on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "members read organisation" on public.organisations for select to authenticated using (private.is_active_member(id));
create policy "members read memberships" on public.organisation_members for select to authenticated using (private.is_active_member(organisation_id));

create policy "members read business profile" on public.business_profiles for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read products" on public.products for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read services" on public.services for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read documents" on public.documents for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read document versions" on public.document_versions for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read document chunks" on public.document_chunks for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read agents" on public.agents for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read agent permissions" on public.agent_permissions for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read agent actions" on public.agent_actions for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read approvals" on public.approvals for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read audit logs" on public.audit_logs for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read subscriptions" on public.subscriptions for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read usage" on public.usage_events for select to authenticated using (private.is_active_member(organisation_id));
create policy "all authenticated read agent catalogue" on public.agent_types for select to authenticated using (true);
create policy "all authenticated read active plans" on public.plans for select to authenticated using (active = true);
create policy "all authenticated read plan entitlements" on public.plan_entitlements for select to authenticated using (true);

-- Explicitly expose only the approved read surface to the authenticated Data API role.
-- All sensitive state transitions remain server-side through the policy service.
grant select on public.profiles, public.organisations, public.organisation_members,
  public.business_profiles, public.products, public.services, public.documents,
  public.document_versions, public.document_chunks, public.agent_types, public.agents,
  public.agent_permissions, public.agent_actions, public.approvals, public.audit_logs,
  public.plans, public.plan_entitlements, public.subscriptions, public.usage_events
  to authenticated;

-- Client writes are intentionally absent for tenant creation, memberships, documents,
-- agents, permissions, actions, approvals, audit logs, subscriptions, and usage.
-- These use narrowly scoped server endpoints after policy validation.

revoke all on schema private from public;
grant usage on schema private to authenticated;
revoke all on function private.is_active_member(uuid) from public;
grant execute on function private.is_active_member(uuid) to authenticated;

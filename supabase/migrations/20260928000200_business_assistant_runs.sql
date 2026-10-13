-- Diagnostic run and usage records for the read-only Business Assistant.
create table if not exists public.agent_runs (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  agent_id uuid not null, session_id uuid references public.agent_sessions(id) on delete set null,
  provider text, model text, status text not null check (status in ('started','succeeded','failed')),
  tools_invoked jsonb not null default '[]'::jsonb, error_code text, started_at timestamptz not null default now(), finished_at timestamptz
);
create table if not exists public.ai_usage_events (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  agent_id uuid not null, provider text not null, model text not null, input_tokens integer, output_tokens integer, request_count integer not null default 1, created_at timestamptz not null default now()
);
alter table public.agent_runs enable row level security;
alter table public.ai_usage_events enable row level security;
create policy "members read agent runs" on public.agent_runs for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read ai usage" on public.ai_usage_events for select to authenticated using (private.is_active_member(organisation_id));
create index if not exists agent_runs_organisation_started_index on public.agent_runs (organisation_id, started_at desc);
create index if not exists ai_usage_organisation_created_index on public.ai_usage_events (organisation_id, created_at desc);

create table if not exists public.voice_calls (
 id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade, agent_id uuid references public.agents(id) on delete set null, contact_id uuid references public.crm_contacts(id) on delete set null, provider_call_id text, caller_number text not null, caller_name text, direction text not null default 'inbound', status text not null default 'completed', category text, summary text, outcome text, escalated boolean not null default false, started_at timestamptz not null default now(), ended_at timestamptz, metadata jsonb not null default '{}'::jsonb, unique(organisation_id, provider_call_id)
);
alter table public.voice_calls enable row level security;
create policy "members read voice calls" on public.voice_calls for select to authenticated using (private.is_active_member(organisation_id));
create index if not exists voice_calls_org_started_idx on public.voice_calls(organisation_id, started_at desc);

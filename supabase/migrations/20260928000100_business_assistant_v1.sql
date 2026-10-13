-- Business Assistant V1 server foundation. Apply through the Supabase plugin.
-- No provider secrets are stored in the database or Flutter.

create table if not exists public.agent_sessions (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  agent_id uuid not null, user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'active' check (status in ('active','closed')), created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  foreign key (organisation_id, agent_id) references public.agents(organisation_id, id) on delete cascade
);
create table if not exists public.agent_messages (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  session_id uuid not null references public.agent_sessions(id) on delete cascade, role text not null check (role in ('user','assistant','tool')),
  content text not null, citations jsonb not null default '[]'::jsonb, confidence text, created_at timestamptz not null default now()
);
create table if not exists public.agent_memories (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  agent_id uuid not null, memory_type text not null, content text not null, metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(), foreign key (organisation_id, agent_id) references public.agents(organisation_id, id) on delete cascade
);
alter table public.documents add column if not exists intelligence_status text not null default 'uploaded' check (intelligence_status in ('uploaded','queued','processing','ready','failed','unsupported','requires_ocr'));
alter table public.documents add column if not exists intelligence_error text;
alter table public.document_versions add column if not exists extraction_metadata jsonb not null default '{}'::jsonb;
create index if not exists agent_sessions_organisation_user_index on public.agent_sessions (organisation_id, user_id, updated_at desc);
create index if not exists agent_messages_session_created_index on public.agent_messages (session_id, created_at);
create index if not exists agent_memories_organisation_agent_index on public.agent_memories (organisation_id, agent_id, created_at desc);
alter table public.agent_sessions enable row level security;
alter table public.agent_messages enable row level security;
alter table public.agent_memories enable row level security;
create policy "members read own agent sessions" on public.agent_sessions for select to authenticated using (private.is_active_member(organisation_id) and user_id = auth.uid());
create policy "members create own agent sessions" on public.agent_sessions for insert to authenticated with check (private.is_active_member(organisation_id) and user_id = auth.uid());
create policy "members read agent messages" on public.agent_messages for select to authenticated using (private.is_active_member(organisation_id) and exists (select 1 from public.agent_sessions s where s.id = session_id and s.organisation_id = agent_messages.organisation_id and s.user_id = auth.uid()));
create policy "members create agent messages" on public.agent_messages for insert to authenticated with check (private.is_active_member(organisation_id) and exists (select 1 from public.agent_sessions s where s.id = session_id and s.organisation_id = agent_messages.organisation_id and s.user_id = auth.uid()));
create policy "members read agent memories" on public.agent_memories for select to authenticated using (private.is_active_member(organisation_id));

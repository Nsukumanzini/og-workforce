insert into public.agent_types (key, display_name, description)
values ('tender_agent', 'Tender Agent', 'Discovers, evaluates and prepares tender opportunities for review.')
on conflict (key) do nothing;

create table if not exists public.tender_opportunities (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  source_provider text not null default 'manual', external_id text, reference text, title text not null, buyer text,
  description text, category text, location text, published_at timestamptz, closing_at timestamptz, estimated_value numeric,
  currency text not null default 'ZAR', eligibility_summary text, submission_method text, source_url text,
  status text not null default 'open' check (status in ('open','closed','cancelled','unknown')), metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (organisation_id, source_provider, external_id)
);

create table if not exists public.tender_workspaces (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  opportunity_id uuid not null references public.tender_opportunities(id) on delete cascade,
  status text not null default 'discovered' check (status in ('discovered','reviewing','shortlisted','not_suitable','preparing','awaiting_information','awaiting_approval','ready','submitted','won','lost','expired','withdrawn')),
  match_score numeric, match_reasons jsonb not null default '[]'::jsonb, interest text check (interest in ('unknown','interested','not_interested')),
  owner_user_id uuid references auth.users(id) on delete set null, notes text, eligibility_status text not null default 'unclear',
  missing_requirements jsonb not null default '[]'::jsonb, draft_state jsonb not null default '{}'::jsonb, deadline_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique (organisation_id, opportunity_id)
);

create table if not exists public.tender_requirements (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  workspace_id uuid not null references public.tender_workspaces(id) on delete cascade, requirement_text text not null,
  category text, mandatory boolean not null default true, evidence_source text, status text not null default 'unclear' check (status in ('satisfied','missing','unclear','not_applicable')),
  business_document_id uuid references public.documents(id) on delete set null, business_brain_reference text, notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.tender_documents (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  workspace_id uuid not null references public.tender_workspaces(id) on delete cascade, document_id uuid references public.documents(id) on delete set null,
  storage_path text, document_role text not null default 'source', trust_level text not null default 'untrusted', metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.tender_drafts (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  workspace_id uuid not null references public.tender_workspaces(id) on delete cascade, draft_type text not null, content text not null,
  status text not null default 'draft' check (status in ('draft','awaiting_approval','approved','rejected','superseded')),
  grounded_sources jsonb not null default '[]'::jsonb, created_by_agent_id uuid references public.agents(id) on delete set null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.tender_missing_information (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  workspace_id uuid not null references public.tender_workspaces(id) on delete cascade, question text not null, reason text,
  status text not null default 'open' check (status in ('open','resolved','dismissed')), requested_from text, created_at timestamptz not null default now()
);

create index if not exists tender_opportunities_org_closing_idx on public.tender_opportunities(organisation_id, closing_at);
create index if not exists tender_workspaces_org_status_idx on public.tender_workspaces(organisation_id, status);
create index if not exists tender_requirements_workspace_status_idx on public.tender_requirements(workspace_id, status);
create index if not exists tender_documents_workspace_idx on public.tender_documents(workspace_id);
create index if not exists tender_drafts_workspace_status_idx on public.tender_drafts(workspace_id, status);
create index if not exists tender_missing_information_workspace_status_idx on public.tender_missing_information(workspace_id, status);

alter table public.tender_opportunities enable row level security;
alter table public.tender_workspaces enable row level security;
alter table public.tender_requirements enable row level security;
alter table public.tender_documents enable row level security;
alter table public.tender_drafts enable row level security;
alter table public.tender_missing_information enable row level security;

do $$ declare t text; begin
  foreach t in array array['tender_opportunities','tender_workspaces','tender_requirements','tender_documents','tender_drafts','tender_missing_information'] loop
    execute format('drop policy if exists %I_member_select on public.%I', t || '_member_select', t);
    execute format('create policy %I_member_select on public.%I for select to authenticated using (private.is_active_member(organisation_id))', t || '_member_select', t);
    execute format('drop policy if exists %I_member_write on public.%I', t || '_member_write', t);
    execute format('create policy %I_member_write on public.%I for all to authenticated using (private.is_active_member(organisation_id)) with check (private.is_active_member(organisation_id))', t || '_member_write', t);
  end loop;
end $$;

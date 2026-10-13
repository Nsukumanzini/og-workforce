-- WhatsApp + CRM foundation. Channel-neutral tables prevent a WhatsApp-only dead end.
create table if not exists public.crm_contacts (
 id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
 full_name text, company_name text, phone text, whatsapp_number text, email text,
 lifecycle_status text not null default 'new' check (lifecycle_status in ('new','contacted','qualified','customer','lost','archived')),
 source text, notes text, assigned_owner uuid references auth.users(id), active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique (organisation_id,id)
);
create table if not exists public.communication_channels (
 id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
 channel_key text not null check (channel_key in ('whatsapp','email','website_chat','voice')), display_name text not null, active boolean not null default true,
 unique (organisation_id, channel_key)
);
create table if not exists public.organisation_integrations (
 id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
 provider text not null, external_account_id text, phone_number_id text, display_phone_number text,
 status text not null default 'disconnected' check (status in ('disconnected','pending','connected','error')),
 webhook_status text, connected_at timestamptz, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique (organisation_id, provider, phone_number_id)
);
create table if not exists public.unified_conversations (
 id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
 contact_id uuid, channel_key text not null, status text not null default 'open' check (status in ('open','waiting','human_takeover','resolved','archived')),
 assigned_human uuid references auth.users(id), assigned_agent uuid, last_activity_at timestamptz not null default now(), unread_count integer not null default 0,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique (organisation_id,id), foreign key (organisation_id,contact_id) references public.crm_contacts(organisation_id,id)
);
create table if not exists public.unified_messages (
 id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
 conversation_id uuid not null, channel_key text not null, direction text not null check (direction in ('inbound','outbound')),
 sender text, recipient text, content text, external_message_id text, message_type text not null default 'text', delivery_status text not null default 'pending',
 agent_generated boolean not null default false, human_generated boolean not null default false, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(),
 unique (organisation_id,id), unique (organisation_id,external_message_id), foreign key (organisation_id,conversation_id) references public.unified_conversations(organisation_id,id) on delete cascade
);
create index if not exists crm_contacts_org_whatsapp_idx on public.crm_contacts(organisation_id,whatsapp_number);
create index if not exists unified_conversations_org_activity_idx on public.unified_conversations(organisation_id,last_activity_at desc);
create index if not exists unified_messages_conversation_created_idx on public.unified_messages(organisation_id,conversation_id,created_at);
alter table public.crm_contacts enable row level security; alter table public.communication_channels enable row level security; alter table public.organisation_integrations enable row level security; alter table public.unified_conversations enable row level security; alter table public.unified_messages enable row level security;
create policy "members read crm contacts" on public.crm_contacts for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read channels" on public.communication_channels for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read integrations" on public.organisation_integrations for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read conversations" on public.unified_conversations for select to authenticated using (private.is_active_member(organisation_id));
create policy "members read messages" on public.unified_messages for select to authenticated using (private.is_active_member(organisation_id));

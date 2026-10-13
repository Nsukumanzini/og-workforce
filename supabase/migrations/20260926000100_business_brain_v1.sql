-- Business Brain V1 structured knowledge. No embeddings, vectors, agents, or AI calls.

alter table public.business_profiles
  add column if not exists slogan text,
  add column if not exists year_established integer check (year_established is null or year_established between 1800 and extract(year from now())::integer),
  add column if not exists physical_address text,
  add column if not exists postal_address text,
  add column if not exists support_email text,
  add column if not exists sales_email text,
  add column if not exists bbbee_status text,
  add column if not exists default_currency char(3) not null default 'ZAR';

create table if not exists public.business_locations (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  name text not null, location_type text not null default 'other' check (location_type in ('head_office','branch','warehouse','store','workshop','other')),
  address text, city text, region text, country_code char(2) not null, postal_code text, phone text, email text,
  is_primary boolean not null default false, active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.business_hours (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  weekday smallint not null check (weekday between 1 and 7), is_open boolean not null default false,
  opens_at time, closes_at time, timezone text not null default 'Africa/Johannesburg',
  unique (organisation_id, weekday), check (not is_open or (opens_at is not null and closes_at is not null and closes_at > opens_at))
);

create table if not exists public.departments (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  name text not null, active boolean not null default true, created_at timestamptz not null default now(), unique (organisation_id, name)
);

create table if not exists public.business_contacts (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  full_name text not null, job_title text, department_id uuid references public.departments(id) on delete set null,
  email text, phone text, location_id uuid references public.business_locations(id) on delete set null,
  preferred_contact_method text, active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.escalation_contacts (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  category text not null, primary_contact_id uuid references public.business_contacts(id) on delete set null,
  secondary_contact_id uuid references public.business_contacts(id) on delete set null, phone text, email text,
  availability_notes text, priority integer not null default 100, active boolean not null default true, created_at timestamptz not null default now()
);

alter table public.products
  add column if not exists category text, add column if not exists tax_behavior text, add column if not exists availability_status text not null default 'available',
  add column if not exists unit text, add column if not exists internal_notes text, add column if not exists customer_notes text,
  add column if not exists negotiable boolean not null default false, add column if not exists minimum_price numeric check (minimum_price is null or minimum_price >= 0),
  add column if not exists maximum_ai_discount_percent numeric check (maximum_ai_discount_percent is null or maximum_ai_discount_percent between 0 and 100);

alter table public.services
  add column if not exists category text, add column if not exists pricing_model text not null default 'quote_required' check (pricing_model in ('fixed','from','quote_required')),
  add column if not exists estimated_duration_minutes integer check (estimated_duration_minutes is null or estimated_duration_minutes > 0),
  add column if not exists deposit_required boolean not null default false, add column if not exists deposit_value numeric check (deposit_value is null or deposit_value >= 0),
  add column if not exists tax_behavior text, add column if not exists negotiable boolean not null default false,
  add column if not exists maximum_discount_percent numeric check (maximum_discount_percent is null or maximum_discount_percent between 0 and 100),
  add column if not exists service_area text, add column if not exists customer_notes text, add column if not exists internal_notes text;

create table if not exists public.packages (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  name text not null, description text, price numeric not null check (price >= 0), currency char(3) not null default 'ZAR',
  tax_behavior text, customer_terms text, valid_from date, valid_until date, active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), check (valid_until is null or valid_from is null or valid_until >= valid_from)
);

create table if not exists public.package_items (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  package_id uuid not null references public.packages(id) on delete cascade, product_id uuid references public.products(id) on delete restrict,
  service_id uuid references public.services(id) on delete restrict, quantity numeric not null default 1 check (quantity > 0),
  check ((product_id is null) <> (service_id is null))
);

create table if not exists public.pricing_rules (
  organisation_id uuid primary key references public.organisations(id) on delete cascade, default_currency char(3) not null default 'ZAR',
  vat_registered boolean not null default false, default_vat_percent numeric check (default_vat_percent is null or default_vat_percent between 0 and 100),
  payment_terms text, deposit_percent numeric check (deposit_percent is null or deposit_percent between 0 and 100), quotation_valid_days integer,
  invoice_due_days integer, discounts_allowed boolean not null default false, maximum_automatic_discount_percent numeric check (maximum_automatic_discount_percent is null or maximum_automatic_discount_percent between 0 and 100),
  negotiation_allowed boolean not null default false, call_out_fee numeric check (call_out_fee is null or call_out_fee >= 0), delivery_fee numeric check (delivery_fee is null or delivery_fee >= 0),
  minimum_order_value numeric check (minimum_order_value is null or minimum_order_value >= 0), cancellation_fee text, late_payment_policy text, updated_at timestamptz not null default now(), updated_by uuid references auth.users(id)
);

create table if not exists public.customer_engagement_profiles (
  organisation_id uuid primary key references public.organisations(id) on delete cascade, customer_types jsonb not null default '[]', target_locations jsonb not null default '[]',
  preferred_channels jsonb not null default '[]', communication_tone text, guidance text, preferred_greeting text, preferred_closing text,
  supported_languages jsonb not null default '[]', follow_up_allowed boolean not null default true, follow_up_interval_hours integer,
  maximum_follow_up_attempts integer, stop_contact_rules text, prices_may_be_discussed boolean not null default true, discounts_may_be_mentioned boolean not null default false,
  complaint_handling_instructions text, vip_handling_notes text, updated_at timestamptz not null default now()
);

create table if not exists public.organisation_languages (
  organisation_id uuid not null references public.organisations(id) on delete cascade, language_code text not null, is_default boolean not null default false,
  primary key (organisation_id, language_code)
);

create table if not exists public.knowledge_entries (
  id uuid primary key default gen_random_uuid(), organisation_id uuid not null references public.organisations(id) on delete cascade,
  entry_type text not null check (entry_type in ('faq','policy')), title text not null, category text, content text not null,
  customer_visible boolean not null default false, active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

alter table public.documents
  add column if not exists filename text, add column if not exists mime_type text, add column if not exists file_size_bytes bigint check (file_size_bytes is null or file_size_bytes between 1 and 10485760),
  add column if not exists category text, add column if not exists expires_at date, add column if not exists notes text,
  add column if not exists restricted boolean not null default false;

create or replace function private.has_org_role(target_organisation_id uuid, allowed_roles text[])
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.organisation_members m where m.organisation_id = target_organisation_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role_key = any (allowed_roles));
$$;
revoke all on function private.has_org_role(uuid,text[]) from public;
grant execute on function private.has_org_role(uuid,text[]) to authenticated;

-- All Business Brain tables are tenant-scoped. Reads are membership-scoped; writes are role-scoped.
do $$ declare t text; begin
  foreach t in array array['business_locations','business_hours','departments','business_contacts','escalation_contacts','packages','package_items','pricing_rules','customer_engagement_profiles','organisation_languages','knowledge_entries'] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

create policy "members read business brain locations" on public.business_locations for select to authenticated using (private.is_active_member(organisation_id));
create policy "managers write business brain locations" on public.business_locations for all to authenticated using (private.has_org_role(organisation_id, array['owner','admin','manager'])) with check (private.has_org_role(organisation_id, array['owner','admin','manager']));
create policy "members read business hours" on public.business_hours for select to authenticated using (private.is_active_member(organisation_id));
create policy "managers write business hours" on public.business_hours for all to authenticated using (private.has_org_role(organisation_id, array['owner','admin','manager'])) with check (private.has_org_role(organisation_id, array['owner','admin','manager']));
create policy "members read departments" on public.departments for select to authenticated using (private.is_active_member(organisation_id));
create policy "managers write departments" on public.departments for all to authenticated using (private.has_org_role(organisation_id, array['owner','admin','manager'])) with check (private.has_org_role(organisation_id, array['owner','admin','manager']));
create policy "members read contacts" on public.business_contacts for select to authenticated using (private.is_active_member(organisation_id));
create policy "managers write contacts" on public.business_contacts for all to authenticated using (private.has_org_role(organisation_id, array['owner','admin','manager'])) with check (private.has_org_role(organisation_id, array['owner','admin','manager']));
create policy "members read escalations" on public.escalation_contacts for select to authenticated using (private.is_active_member(organisation_id));
create policy "admins write escalations" on public.escalation_contacts for all to authenticated using (private.has_org_role(organisation_id, array['owner','admin'])) with check (private.has_org_role(organisation_id, array['owner','admin']));
create policy "members read packages" on public.packages for select to authenticated using (private.is_active_member(organisation_id));
create policy "managers write packages" on public.packages for all to authenticated using (private.has_org_role(organisation_id, array['owner','admin','manager'])) with check (private.has_org_role(organisation_id, array['owner','admin','manager']));
create policy "members read package items" on public.package_items for select to authenticated using (private.is_active_member(organisation_id));
create policy "managers write package items" on public.package_items for all to authenticated using (private.has_org_role(organisation_id, array['owner','admin','manager'])) with check (private.has_org_role(organisation_id, array['owner','admin','manager']));
create policy "members read pricing rules" on public.pricing_rules for select to authenticated using (private.is_active_member(organisation_id));
create policy "admins write pricing rules" on public.pricing_rules for all to authenticated using (private.has_org_role(organisation_id, array['owner','admin'])) with check (private.has_org_role(organisation_id, array['owner','admin']));
create policy "members read engagement" on public.customer_engagement_profiles for select to authenticated using (private.is_active_member(organisation_id));
create policy "admins write engagement" on public.customer_engagement_profiles for all to authenticated using (private.has_org_role(organisation_id, array['owner','admin'])) with check (private.has_org_role(organisation_id, array['owner','admin']));
create policy "members read languages" on public.organisation_languages for select to authenticated using (private.is_active_member(organisation_id));
create policy "admins write languages" on public.organisation_languages for all to authenticated using (private.has_org_role(organisation_id, array['owner','admin'])) with check (private.has_org_role(organisation_id, array['owner','admin']));
create policy "members read knowledge" on public.knowledge_entries for select to authenticated using (private.is_active_member(organisation_id));
create policy "managers write knowledge" on public.knowledge_entries for all to authenticated using (private.has_org_role(organisation_id, array['owner','admin','manager'])) with check (private.has_org_role(organisation_id, array['owner','admin','manager']));

create policy "managers write products" on public.products for all to authenticated using (private.has_org_role(organisation_id, array['owner','admin','manager'])) with check (private.has_org_role(organisation_id, array['owner','admin','manager']));
create policy "managers write services" on public.services for all to authenticated using (private.has_org_role(organisation_id, array['owner','admin','manager'])) with check (private.has_org_role(organisation_id, array['owner','admin','manager']));
create policy "admins update business profile" on public.business_profiles for update to authenticated using (private.has_org_role(organisation_id, array['owner','admin'])) with check (private.has_org_role(organisation_id, array['owner','admin']));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('business-brain-documents','business-brain-documents',false,10485760,array['application/pdf','application/vnd.openxmlformats-officedocument.wordprocessingml.document','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','image/png','image/jpeg'])
on conflict (id) do update set public=false, file_size_limit=10485760, allowed_mime_types=excluded.allowed_mime_types;
create policy "members read brain documents" on storage.objects for select to authenticated using (bucket_id='business-brain-documents' and private.is_active_member((split_part(name,'/',1))::uuid));
create policy "managers upload brain documents" on storage.objects for insert to authenticated with check (bucket_id='business-brain-documents' and private.has_org_role((split_part(name,'/',1))::uuid, array['owner','admin','manager']));
create policy "managers update brain documents" on storage.objects for update to authenticated using (bucket_id='business-brain-documents' and private.has_org_role((split_part(name,'/',1))::uuid, array['owner','admin','manager']));
create policy "admins delete brain documents" on storage.objects for delete to authenticated using (bucket_id='business-brain-documents' and private.has_org_role((split_part(name,'/',1))::uuid, array['owner','admin']));

create or replace function private.audit_business_brain_change() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.audit_logs (organisation_id, actor_user_id, event_type, entity_type, entity_id, metadata)
  values (coalesce(new.organisation_id, old.organisation_id), (select auth.uid()), 'business_brain.' || lower(tg_op), tg_table_name, coalesce(new.id, old.id), jsonb_build_object('operation', tg_op));
  return coalesce(new, old);
end $$;

drop trigger if exists audit_products_change on public.products;
create trigger audit_products_change after insert or update or delete on public.products for each row execute function private.audit_business_brain_change();
drop trigger if exists audit_services_change on public.services;
create trigger audit_services_change after insert or update or delete on public.services for each row execute function private.audit_business_brain_change();
drop trigger if exists audit_knowledge_change on public.knowledge_entries;
create trigger audit_knowledge_change after insert or update or delete on public.knowledge_entries for each row execute function private.audit_business_brain_change();

create index if not exists business_locations_organisation_index on public.business_locations (organisation_id, active);
create index if not exists business_hours_organisation_index on public.business_hours (organisation_id, weekday);
create index if not exists business_contacts_organisation_index on public.business_contacts (organisation_id, active);
create index if not exists escalation_contacts_organisation_index on public.escalation_contacts (organisation_id, active);
create index if not exists packages_organisation_index on public.packages (organisation_id, active);
create index if not exists package_items_package_index on public.package_items (organisation_id, package_id);
create index if not exists knowledge_entries_organisation_index on public.knowledge_entries (organisation_id, entry_type, active);

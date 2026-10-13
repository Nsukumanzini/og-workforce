-- Authentication and workspace onboarding.
-- Apply after 20260924000100_phase_1_foundation.sql.

alter table public.organisation_members
  drop constraint if exists organisation_members_role_key_check;
alter table public.organisation_members
  add constraint organisation_members_role_key_check
  check (role_key in ('owner', 'admin', 'manager', 'staff', 'viewer'));

alter table public.business_profiles
  add column if not exists business_type text,
  add column if not exists country_code char(2),
  add column if not exists region text,
  add column if not exists city text,
  add column if not exists tax_number text,
  add column if not exists csd_number text,
  add column if not exists onboarding_completed_at timestamptz;

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure private.handle_new_user();

insert into public.plans (key, name, active)
values ('starter_trial', 'Starter trial', true)
on conflict (key) do nothing;

create or replace function private.create_initial_workspace(
  p_legal_name text,
  p_trading_name text default null,
  p_business_type text default null,
  p_industry text default null,
  p_description text default null,
  p_country_code char(2) default null,
  p_region text default null,
  p_city text default null,
  p_email text default null,
  p_phone text default null,
  p_website text default null,
  p_registration_number text default null,
  p_vat_number text default null,
  p_tax_number text default null,
  p_csd_number text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_organisation_id uuid;
  v_trial_plan_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentication is required.' using errcode = '42501';
  end if;

  if nullif(trim(p_legal_name), '') is null then
    raise exception 'Business name is required.' using errcode = '22023';
  end if;

  if p_country_code is null or char_length(trim(p_country_code)) <> 2 then
    raise exception 'A two-letter country code is required.' using errcode = '22023';
  end if;

  -- One transaction-scoped lock prevents double-click/retry races for the first workspace.
  perform pg_advisory_xact_lock(hashtextextended(v_user_id::text, 0));

  select organisation_id into v_organisation_id
  from public.organisation_members
  where user_id = v_user_id and status = 'active'
  order by created_at
  limit 1;

  if v_organisation_id is not null then
    return v_organisation_id;
  end if;

  insert into public.organisations (legal_name, trading_name)
  values (trim(p_legal_name), nullif(trim(p_trading_name), ''))
  returning id into v_organisation_id;

  insert into public.organisation_members (organisation_id, user_id, role_key, status)
  values (v_organisation_id, v_user_id, 'owner', 'active');

  insert into public.business_profiles (
    organisation_id, registration_number, vat_number, tax_number, csd_number,
    business_type, industry, description, email, phone, website,
    country_code, region, city, data_status, onboarding_completed_at, updated_by
  ) values (
    v_organisation_id, nullif(trim(p_registration_number), ''), nullif(trim(p_vat_number), ''),
    nullif(trim(p_tax_number), ''), nullif(trim(p_csd_number), ''),
    nullif(trim(p_business_type), ''), nullif(trim(p_industry), ''), nullif(trim(p_description), ''),
    nullif(trim(p_email), ''), nullif(trim(p_phone), ''), nullif(trim(p_website), ''),
    upper(trim(p_country_code)), nullif(trim(p_region), ''), nullif(trim(p_city), ''),
    'draft', now(), v_user_id
  );

  select id into v_trial_plan_id from public.plans where key = 'starter_trial';
  insert into public.subscriptions (organisation_id, plan_id, status, starts_at)
  values (v_organisation_id, v_trial_plan_id, 'trial', now());

  insert into public.audit_logs (organisation_id, actor_user_id, event_type, entity_type, entity_id, metadata)
  values (
    v_organisation_id, v_user_id, 'workspace.created', 'organisation', v_organisation_id,
    jsonb_build_object('source', 'initial_onboarding', 'role', 'owner')
  );

  return v_organisation_id;
end;
$$;

revoke all on function private.create_initial_workspace(
  text, text, text, text, text, char(2), text, text, text, text, text, text, text, text, text
) from public;
grant execute on function private.create_initial_workspace(
  text, text, text, text, text, char(2), text, text, text, text, text, text, text, text, text
) to authenticated;

-- The Data API can call this invoker wrapper, while the privileged transaction
-- stays in the non-exposed private schema.
create or replace function public.create_initial_workspace(
  p_legal_name text,
  p_trading_name text default null,
  p_business_type text default null,
  p_industry text default null,
  p_description text default null,
  p_country_code char(2) default null,
  p_region text default null,
  p_city text default null,
  p_email text default null,
  p_phone text default null,
  p_website text default null,
  p_registration_number text default null,
  p_vat_number text default null,
  p_tax_number text default null,
  p_csd_number text default null
)
returns uuid
language sql
security invoker
set search_path = ''
as $$
  select private.create_initial_workspace(
    p_legal_name, p_trading_name, p_business_type, p_industry, p_description,
    p_country_code, p_region, p_city, p_email, p_phone, p_website,
    p_registration_number, p_vat_number, p_tax_number, p_csd_number
  );
$$;

revoke all on function public.create_initial_workspace(
  text, text, text, text, text, char(2), text, text, text, text, text, text, text, text, text
) from public;
grant execute on function public.create_initial_workspace(
  text, text, text, text, text, char(2), text, text, text, text, text, text, text, text, text
) to authenticated;

-- The app can maintain its own display name; workspace, role and subscription state
-- remain server controlled through create_initial_workspace and future admin RPCs.
create policy "profile owner inserts profile" on public.profiles
  for insert to authenticated
  with check ((select auth.uid()) = id);

create policy "profile owner updates profile name" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

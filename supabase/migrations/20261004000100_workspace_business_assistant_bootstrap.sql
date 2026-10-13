-- Every normal workspace must have the Business Assistant required by the
-- authenticated API request context.  Keep this provisioning inside the
-- existing onboarding transaction so first-use requests do not require a
-- privileged follow-up write.

insert into public.agent_types (key, display_name, system_managed, description)
values (
  'business_assistant',
  'Business Assistant',
  true,
  'Organisation-scoped assistant using approved Business Brain knowledge.'
)
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

  insert into public.agents (organisation_id, agent_type_key, display_name, status, config)
  values (v_organisation_id, 'business_assistant', 'Business Assistant', 'active', '{}'::jsonb);

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

-- Repair workspaces created before the onboarding contract included the agent.
insert into public.agents (organisation_id, agent_type_key, display_name, status, config)
select o.id, 'business_assistant', 'Business Assistant', 'active', '{}'::jsonb
from public.organisations o
where not exists (
  select 1
  from public.agents a
  where a.organisation_id = o.id
    and a.agent_type_key = 'business_assistant'
);

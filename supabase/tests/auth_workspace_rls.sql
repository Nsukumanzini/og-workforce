-- Reproducible verification after the Phase 1 migrations are applied.
-- Run in a non-production Supabase SQL session as postgres. Replace UUIDs with
-- two real authenticated test users created through Supabase Auth.

begin;

-- 1. As User A, create a workspace and retain the returned organisation UUID.
-- select set_config('request.jwt.claim.sub', '<USER_A_UUID>', true);
-- select set_config('request.jwt.claim.role', 'authenticated', true);
-- select public.create_initial_workspace('Organisation A', null, 'Private company', 'Information Technology', 'Test organisation', 'ZA', 'Gauteng', 'Johannesburg', 'a@example.test', '+27110000000');

-- 2. User A can read its own membership and organisation.
-- select count(*) > 0 as user_a_can_read_own_membership from public.organisation_members;

-- 3. As User B, Organisation A must not be visible or writable.
-- select set_config('request.jwt.claim.sub', '<USER_B_UUID>', true);
-- select count(*) = 0 as user_b_cannot_read_organisation_a from public.organisations;
-- update public.organisation_members set role_key = 'owner' where organisation_id = '<ORG_A_UUID>'::uuid;
-- Expected: zero rows updated because no direct update policy exists.

-- 4. User B cannot create an arbitrary owner membership through the Data API.
-- insert into public.organisation_members (organisation_id, user_id, role_key, status)
-- values ('<ORG_A_UUID>'::uuid, '<USER_B_UUID>'::uuid, 'owner', 'active');
-- Expected: permission denied by RLS.

-- 5. User A cannot assign a different owner through create_initial_workspace.
-- The function takes no user ID and reads auth.uid() internally.

rollback;

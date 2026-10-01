-- ============================================================
-- Who attached each supply line — 20261001090001_supply_attached_by
-- Included by rls_test.sql. Every block is rolled back.
--
-- A fresh ops account is used as the attacher, so its name can resolve only
-- through the supply line it attaches: the seeded accounts already resolve
-- through records they captured, which would make the visibility check pass
-- for the wrong reason.
-- ============================================================

\set OPS_NEW   '''80000000-0000-4000-8000-0000000000a1'''
\set LIVE_OPP  '''e2000000-0000-4000-8000-000000000001'''
\set FREE_HARV '''c0000000-0000-4000-8000-000000000004'''

begin;
  -- privileged fixture: an ops account no record names yet
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    created_at, updated_at, raw_app_meta_data, raw_user_meta_data,
    confirmation_token, recovery_token, email_change_token_new, email_change)
  values ('00000000-0000-0000-0000-000000000000', :OPS_NEW, 'authenticated', 'authenticated',
    'ops-new@fixture.ruaha360.test', 'fixture', now(), now(), now(), '{}'::jsonb, '{}'::jsonb, '', '', '', '');
  insert into app_user (id, display_name, locale) values (:OPS_NEW, 'Fixture Ops', 'en');
  insert into membership (user_id, role, project_id, village_id)
  values (:OPS_NEW, 'ops', '20000000-0000-4000-8000-000000000001', null);

  select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
  set local role authenticated;
  select pg_temp.assert_eq((select count(*) from app_actor_names(array[:OPS_NEW]::uuid[])), 0,
    'before attaching, the new ops account is no name the officer may see');

  -- The attacher is the caller, whatever the client sends.
  select set_config('request.jwt.claims', json_build_object('sub', :OPS_NEW)::text, true);
  insert into opportunity_supply (id, opportunity_id, harvest_report_id, crop_cycle_id, contributed_kg, captured_by)
  select 'e3000000-0000-4000-8000-0000000000a1', :LIVE_OPP, id, crop_cycle_id, 100, :OFF_MGA::uuid
  from harvest_report where id = :FREE_HARV;
  select pg_temp.assert_eq((select count(*) from opportunity_supply
    where id = 'e3000000-0000-4000-8000-0000000000a1' and captured_by = :OPS_NEW and captured_at is not null), 1,
    'a supply line records who attached it, not who the client claims');

  -- And it stays that way.
  update opportunity_supply set captured_by = :OFF_MGA::uuid, captured_at = now() - interval '1 year', contributed_kg = 50
  where id = 'e3000000-0000-4000-8000-0000000000a1';
  select pg_temp.assert_eq((select count(*) from opportunity_supply
    where id = 'e3000000-0000-4000-8000-0000000000a1' and captured_by = :OPS_NEW
      and captured_at > now() - interval '1 day' and contributed_kg = 50), 1,
    'an update cannot rewrite who attached a line, or when');

  -- Whoever can read the line can read the attacher's name.
  select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
  select pg_temp.assert_eq((select count(*) from app_actor_names(array[:OPS_NEW]::uuid[])), 1,
    'staff who can read the supply line resolve who attached it');

  -- Whoever cannot, cannot.
  select set_config('request.jwt.claims', json_build_object('sub', :OFF_MGA)::text, true);
  select pg_temp.assert_eq((select count(*) from app_actor_names(array[:OPS_NEW]::uuid[])), 0,
    'an officer outside the village does not resolve the attacher');
  select set_config('request.jwt.claims', json_build_object('sub', :FARM_JOS)::text, true);
  select pg_temp.assert_eq((select count(*) from app_actor_names(array[:OPS_NEW]::uuid[])), 0,
    'a farmer does not resolve the attacher through supply lines');
rollback;

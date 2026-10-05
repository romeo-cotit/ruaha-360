-- ============================================================
-- Ops creates a village — 20261005090001_village_create
-- Included by rls_test.sql. Every block is rolled back.
-- ============================================================

\set PROJECT   '''20000000-0000-4000-8000-000000000001'''
\set OTHER_PRJ '''20000000-0000-4000-8000-0000000000b1'''
\set NEW_VIL   '''30000000-0000-4000-8000-0000000000b1'''

-- ops creates a village with its first planned capacity row
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
  set local role authenticated;

  select app_create_village(jsonb_build_object(
    'id', :NEW_VIL, 'project_id', :PROJECT, 'code', 'TST-V', 'name', 'Test village',
    'latitude', '-7.9', 'longitude', '35.6',
    'capacity', jsonb_build_object('capacity_kw', '120', 'basis', 'planned',
                                   'simultaneity_factor', '0.7')));
  select pg_temp.assert_eq((select count(*) from village where id = :NEW_VIL), 1,
    'ops creates a village in its own project');
  select pg_temp.assert_eq((select count(*) from village_capacity
    where village_id = :NEW_VIL and is_current and basis = 'planned'
      and capacity_kw = 120 and simultaneity_factor = 0.700), 1,
    'the new village carries its first planned capacity row');
  select pg_temp.assert_eq((select count(*) from v_village_energy where village_id = :NEW_VIL), 1,
    'a created village has energy figures from the start');

  -- a retried submit replays
  select pg_temp.assert_eq(
    (select (app_create_village(jsonb_build_object(
       'id', :NEW_VIL, 'project_id', :PROJECT, 'code', 'TST-V', 'name', 'Test village',
       'capacity', jsonb_build_object('capacity_kw', '120')))->>'replayed')::boolean::int), 1,
    'a retried create replays instead of inserting twice');

  select pg_temp.assert_raises($q$ select app_create_village(jsonb_build_object(
    'id', '30000000-0000-4000-8000-0000000000b2', 'project_id', '20000000-0000-4000-8000-000000000001',
    'code', 'TST-V2', 'name', 'No capacity')) $q$,
    'a village without a planned capacity is refused');
  select pg_temp.assert_raises($q$ select app_create_village(jsonb_build_object(
    'id', '30000000-0000-4000-8000-0000000000b3', 'project_id', '20000000-0000-4000-8000-000000000001',
    'code', 'TST-V', 'name', 'Duplicate code', 'capacity', jsonb_build_object('capacity_kw', '10'))) $q$,
    'a duplicate village code in the project is refused', '23505');
  select pg_temp.assert_raises($q$ select app_create_village(jsonb_build_object(
    'id', '30000000-0000-4000-8000-0000000000b4', 'project_id', '20000000-0000-4000-8000-000000000001',
    'code', 'TST-V4', 'name', 'Measured', 'capacity',
    jsonb_build_object('capacity_kw', '10', 'basis', 'measured'))) $q$,
    'capacity can never be recorded as measured', '22P02');
rollback;

-- ops may not create a village in a project it does not manage
begin;
  -- privileged fixture: a second project
  insert into project (id, country_id, code, name, operator, status, started_on)
  values (:OTHER_PRJ, '10000000-0000-4000-8000-000000000001', 'OTHER-TST', 'Other project',
          'Ruaha Energy', 'active', current_date);

  select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
  set local role authenticated;
  select pg_temp.assert_raises($q$ select app_create_village(jsonb_build_object(
    'id', '30000000-0000-4000-8000-0000000000b5', 'project_id', '20000000-0000-4000-8000-0000000000b1',
    'code', 'X', 'name', 'Elsewhere', 'capacity', jsonb_build_object('capacity_kw', '10'))) $q$,
    'ops cannot create a village in another project', '42501');
  select pg_temp.assert_raises($q$ insert into village (project_id, code, name)
    values ('20000000-0000-4000-8000-0000000000b1', 'Y', 'Direct elsewhere') $q$,
    'ops cannot insert a village directly into another project', '42501');
rollback;

-- officers and farmers may not create villages
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
  set local role authenticated;
  select pg_temp.assert_raises($q$ select app_create_village(jsonb_build_object(
    'id', '30000000-0000-4000-8000-0000000000b6', 'project_id', '20000000-0000-4000-8000-000000000001',
    'code', 'OFF', 'name', 'Officer village', 'capacity', jsonb_build_object('capacity_kw', '10'))) $q$,
    'an officer cannot create a village', '42501');

  select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
  select pg_temp.assert_raises($q$ select app_create_village(jsonb_build_object(
    'id', '30000000-0000-4000-8000-0000000000b7', 'project_id', '20000000-0000-4000-8000-000000000001',
    'code', 'FRM', 'name', 'Farmer village', 'capacity', jsonb_build_object('capacity_kw', '10'))) $q$,
    'a farmer cannot create a village', '42501');
  select pg_temp.assert_raises($q$ insert into village_capacity (village_id, capacity_kw)
    values ('30000000-0000-4000-8000-000000000001', 1) $q$,
    'a farmer cannot add a capacity row', '42501');
rollback;

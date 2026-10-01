-- ============================================================
-- Ruaha 360 · RLS assertions
-- Run against the migrated cloud DEMO database: pnpm db:rls
-- Every policy in the schema is a hypothesis. This is where they get tested.
-- Each block runs as `authenticated` inside a transaction that is rolled back.
-- ============================================================

\set ON_ERROR_STOP on

\set OPS       '''80000000-0000-4000-8000-000000000002'''
\set OFF_ILU   '''80000000-0000-4000-8000-000000000003'''
\set OFF_MGA   '''80000000-0000-4000-8000-000000000004'''
\set FARM_NEE  '''80000000-0000-4000-8000-000000000005'''
\set FARM_JOS  '''80000000-0000-4000-8000-000000000006'''

create or replace function pg_temp.assert_eq(actual bigint, expected bigint, label text)
returns void language plpgsql as $$
begin
  if actual is distinct from expected then
    raise exception 'FAIL % : expected %, got %', label, expected, actual;
  end if;
  raise notice 'pass  %', label;
end $$;

create or replace function pg_temp.assert_raises(stmt text, label text, expected_state text default 'P0001')
returns void language plpgsql as $$
begin
  begin
    execute stmt;
  exception when others then
    if sqlstate <> expected_state then raise; end if;
    raise notice 'pass  % (blocked: %)', label, sqlerrm;
    return;
  end;
  raise exception 'FAIL % : statement was ALLOWED and should not have been', label;
end $$;

-- ── 1. farmer sees own farm only ─────────────────────────
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
  set local role authenticated;
  select pg_temp.assert_eq((select count(*) from farm), 1, 'farmer Neema sees exactly her own farm');
  select pg_temp.assert_eq((select count(*) from farm
                    where id = '90000000-0000-4000-8000-000000000002'), 0,
                   'farmer Neema cannot see the Kimaro farm');
  -- Two: Neema herself, plus Rehema, the only other member of the
  -- Mwakalinga household (70...01). person_read_household exposes household
  -- co-members and nothing else, so 2 is the whole of what she may see.
  select pg_temp.assert_eq((select count(*) from person), 2,
                   'farmer Neema sees herself plus her household only');
rollback;

-- ── 2. officer scoping is per village ────────────────────
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
  set local role authenticated;
  select pg_temp.assert_eq((select count(*) from person
                    where village_id = '30000000-0000-4000-8000-000000000001'), 6,
                   'Ilundo officer sees all six Ilundo persons');
  select pg_temp.assert_eq((select count(*) from person
                    where village_id = '30000000-0000-4000-8000-000000000002'), 0,
                   'Ilundo officer sees no Mgama persons');
rollback;

begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OFF_MGA)::text, true);
  set local role authenticated;
  select pg_temp.assert_eq((select count(*) from person
                    where village_id = '30000000-0000-4000-8000-000000000002'), 2,
                   'Mgama officer sees both Mgama persons');
  select pg_temp.assert_eq((select count(*) from farm), 1,
                   'Mgama officer sees only the Mgama farm');
rollback;

-- ── 3. a farmer cannot approve their own request ─────────
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
  set local role authenticated;
  select pg_temp.assert_raises(
    $q$ update pue_request set status = 'approved'
        where id = 'd0000000-0000-4000-8000-000000000005' $q$,
    'farmer cannot approve their own request');
  select pg_temp.assert_raises(
    $q$ update pue_request set status = 'under_review'
        where id = 'd0000000-0000-4000-8000-000000000005' $q$,
    'farmer cannot move their own request to review');
rollback;

-- ── 4. ops cannot escalate to admin ──────────────────────
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
  set local role authenticated;
  select pg_temp.assert_raises(
    $q$ insert into membership (user_id, role, project_id, village_id)
        values ('80000000-0000-4000-8000-000000000005','admin',
                '20000000-0000-4000-8000-000000000001', null) $q$,
    'ops cannot mint an admin membership', '42501');
  select pg_temp.assert_raises(
    $q$ insert into membership (user_id, role, project_id, village_id)
        values ('80000000-0000-4000-8000-000000000002','admin',
                '20000000-0000-4000-8000-000000000001', null) $q$,
    'ops cannot self-elevate', '42501');
  select pg_temp.assert_raises(
    $q$ update membership set role = 'admin'
        where id = '81000000-0000-4000-8000-000000000005' $q$,
    'ops cannot flip a farmer membership to admin', '42501');
rollback;

-- ── 5. the order book is an ops surface ──────────────────
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
  set local role authenticated;
  select pg_temp.assert_eq((select count(*) from buyer_demand), 0, 'farmer sees no buyer demand');
  select pg_temp.assert_eq((select count(*) from buyer), 0, 'farmer sees no buyers');
  select pg_temp.assert_eq((select count(*) from v_village_energy), 0,
                   'Tower energy view is empty for a farmer');
  select pg_temp.assert_eq((select count(*) from v_village_production), 0,
                   'Tower production view is empty for a farmer');
  select pg_temp.assert_eq((select count(*) from opportunity), 1,
                   'farmer DOES see the opportunity her own supply is inside');
rollback;

-- ── 6. estimates are trigger-only ────────────────────────
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
  set local role authenticated;
  select pg_temp.assert_raises(
    $q$ insert into energy_estimate
        (pue_request_id, village_id, rated_power_kw, quantity, hours_per_day, days_per_week)
        values ('d0000000-0000-4000-8000-000000000005',
                '30000000-0000-4000-8000-000000000001', 99, 1, 1, 1) $q$,
    'nobody can hand-write an energy estimate', '42501');
rollback;

-- ── 7. supply cannot be double committed ─────────────────
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
  set local role authenticated;
  insert into buyer_demand (id, project_id, buyer_id, crop_id, quantity_kg, window_start, window_end)
    select 'e1000000-0000-4000-8000-0000000000ff', project_id, buyer_id, crop_id, quantity_kg, window_start, window_end
    from buyer_demand where id = 'e1000000-0000-4000-8000-000000000001';
  insert into opportunity (id, buyer_demand_id, village_id, crop_id, status)
  values ('e2000000-0000-4000-8000-0000000000ff',
          'e1000000-0000-4000-8000-0000000000ff',
          '30000000-0000-4000-8000-000000000001',
          '40000000-0000-4000-8000-000000000001', 'proposed');
  select pg_temp.assert_raises(
    $q$ insert into opportunity_supply
        (opportunity_id, harvest_report_id, crop_cycle_id, contributed_kg)
        values ('e2000000-0000-4000-8000-0000000000ff',
                'c0000000-0000-4000-8000-000000000002',
                'b0000000-0000-4000-8000-000000000001', 100) $q$,
    'already-committed harvest cannot be promised to a second live opportunity');
rollback;

-- ── 8. the Tower arithmetic ──────────────────────────────
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
  set local role authenticated;
  select pg_temp.assert_eq((select count(*) from v_village_energy), 2,
                   'both villages appear in the Tower (each has a current capacity row)');
  select pg_temp.assert_eq(
    (select (approved_peak_kw * 1000)::bigint from v_village_energy
      where village_id = '30000000-0000-4000-8000-000000000001'),
    10800, 'Ilundo approved peak = (15.0 + 2 x 1.5) x 0.600 = 10.800 kW');
  select pg_temp.assert_eq(
    (select expected_kg::bigint from v_village_supply
      where village_id = '30000000-0000-4000-8000-000000000001'
        and crop_id = '40000000-0000-4000-8000-000000000001'),
    12000, 'Ilundo September maize expected = 12000 kg (superseded estimate excluded)');
  select pg_temp.assert_eq(
    (select available_kg::bigint from v_village_supply
      where village_id = '30000000-0000-4000-8000-000000000001'
        and crop_id = '40000000-0000-4000-8000-000000000001'),
    5600, 'available = 12000 - 6400 already committed');
rollback;

-- ── 9. officer verification and correction boundaries ────
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
  set local role authenticated;
  select pg_temp.assert_raises(
    $q$ select app_verify('person', '60000000-0000-4000-8000-000000000001') $q$,
    'farmer cannot verify a record');
  select pg_temp.assert_raises(
    $q$ select app_update_observed_record('person', '60000000-0000-4000-8000-000000000001', '{"given_name":"Neema","family_name":"Mwakalinga"}'::jsonb) $q$,
    'farmer cannot use the officer correction RPC');
  select pg_temp.assert_raises(
    $q$ select app_supersede_harvest('b0000000-0000-4000-8000-000000000001', 'expected', 999, 'field_verified', 'high', date '2026-09-20') $q$,
    'farmer cannot supersede a harvest figure');
rollback;

begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
  set local role authenticated;
  select pg_temp.assert_raises(
    $q$ select app_verify('not_a_table', '60000000-0000-4000-8000-000000000003') $q$,
    'verification rejects invalid tables');
  select pg_temp.assert_raises(
    $q$ select app_verify('person', '60000000-0000-4000-8000-000000000001') $q$,
    'verification rejects already verified rows');
  select pg_temp.assert_raises(
    $q$ select app_verify('person', '60000000-0000-4000-8000-000000000007') $q$,
    'verification rejects an out-of-village row');
  select pg_temp.assert_raises(
    $q$ select app_verify('person', '60000000-0000-4000-8000-0000000000ff') $q$,
    'verification rejects a missing row');

  select app_verify('person', '60000000-0000-4000-8000-000000000003');
  select pg_temp.assert_eq((select count(*) from person
                    where id = '60000000-0000-4000-8000-000000000003'
                      and verification = 'verified'
                      and verified_by = :OFF_ILU
                      and verified_at is not null), 1,
                   'verification stamps the officer and timestamp');

  select pg_temp.assert_raises(
    $q$ select app_update_observed_record('person', '60000000-0000-4000-8000-000000000003', '{"given_name":"Amina","family_name":"Sanga","confidence":"high"}'::jsonb) $q$,
    'correction rejects server-controlled fields');
  select pg_temp.assert_raises(
    $q$ select app_update_observed_record('person', '60000000-0000-4000-8000-000000000003', '{"given_name":"   ","family_name":"Sanga"}'::jsonb) $q$,
    'correction rejects blank required text');
  select pg_temp.assert_raises(
    $q$ select app_update_observed_record('farm', '90000000-0000-4000-8000-000000000001', '{"label":"Farm","latitude":"91"}'::jsonb) $q$,
    'correction rejects invalid GPS');
  select pg_temp.assert_raises(
    $q$ select app_update_observed_record('person', '60000000-0000-4000-8000-000000000007', '{"given_name":"Zawadi","family_name":"Ngowi"}'::jsonb) $q$,
    'correction rejects an out-of-village row');

  select app_update_observed_record(
    'person', '60000000-0000-4000-8000-000000000001',
    '{"given_name":"Neema","family_name":"Mwakalinga","phone":"+255700000199"}'::jsonb);
  select pg_temp.assert_eq((select count(*) from person
                    where id = '60000000-0000-4000-8000-000000000001'
                      and verification = 'unverified'
                      and verified_by is null and verified_at is null
                      and source = 'field_verified'
                      and captured_by = :OFF_ILU), 1,
                   'correction resets verification and stamps provenance');

  select app_supersede_harvest(
    'b0000000-0000-4000-8000-000000000001', 'expected', 999,
    'field_verified', 'high', date '2026-09-20');
  select pg_temp.assert_eq((select count(*) from harvest_report
                    where crop_cycle_id = 'b0000000-0000-4000-8000-000000000001'
                      and kind = 'expected' and is_current), 1,
                   'harvest correction leaves exactly one current row');
  select pg_temp.assert_eq((select count(*) from harvest_report
                    where crop_cycle_id = 'b0000000-0000-4000-8000-000000000001'
                      and quantity_kg = 3200), 1,
                   'harvest correction preserves the old row');
rollback;

-- ── 10. superseded harvest figures stay out of aggregates ─
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
  set local role authenticated;
  select pg_temp.assert_eq((select count(*) from v_harvest_available
                    where crop_cycle_id = 'b0000000-0000-4000-8000-000000000001'), 1,
                   'exactly one current expected figure survives per cycle');
rollback;

\ir mvp_security_test.sql
\ir survey_test.sql
\ir supply_attached_by_test.sql

drop function pg_temp.assert_eq(bigint, bigint, text);
drop function pg_temp.assert_raises(text, text, text);

\echo '--- all RLS assertions passed ---'

-- ============================================================
-- Several crops at registration — 20261005090002_register_many_cycles
-- Included by rls_test.sql. Every block is rolled back.
-- ============================================================

\set MAIZE   '''40000000-0000-4000-8000-000000000001'''
\set AVOCADO '''40000000-0000-4000-8000-000000000002'''

-- two crops on one plot: two cycles, two expected harvests
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
  set local role authenticated;

  create temp table _r on commit drop as
  select app_register_farmer(jsonb_build_object(
    'client_ref', '99000000-0000-4000-8000-0000000000c1',
    'village_id', '30000000-0000-4000-8000-000000000001',
    'person', jsonb_build_object('given_name', 'Multi', 'family_name', 'Crop', 'phone', '0712000931'),
    'household', jsonb_build_object('label', 'Multi crop'),
    'farm', jsonb_build_object('label', 'x', 'latitude', '-8.13', 'longitude', '35.19'),
    'plot', jsonb_build_object('label', 'x', 'area_ha', '1'),
    'cycles', jsonb_build_array(
      jsonb_build_object('crop_id', :MAIZE, 'area_ha', '0.8',
        'harvest_start', '2026-09-01', 'harvest_end', '2026-09-30',
        'harvest', jsonb_build_object('quantity_kg', '2000', 'reported_for', '2026-09-01')),
      jsonb_build_object('crop_id', :AVOCADO, 'tree_count', '40',
        'harvest', jsonb_build_object('quantity_kg', '600'))
    ))) as r;

  select pg_temp.assert_eq((select count(*) from crop_cycle
    where plot_id = (select (r->>'plot_id')::uuid from _r)), 2,
    'two crops register as two cycles on the same plot');
  select pg_temp.assert_eq((select count(*) from harvest_report h
    join crop_cycle c on c.id = h.crop_cycle_id
    where c.plot_id = (select (r->>'plot_id')::uuid from _r) and h.kind = 'expected' and h.is_current), 2,
    'each crop carries its own expected harvest');
  select pg_temp.assert_eq((select jsonb_array_length(r->'crop_cycle_ids') from _r), 2,
    'the result names every cycle it created');
  select pg_temp.assert_eq((select count(*) from _r where r->>'crop_cycle_id' = r->'crop_cycle_ids'->>0), 1,
    'crop_cycle_id stays the first cycle, for older clients');
  select pg_temp.assert_eq((select count(*) from crop_cycle
    where plot_id = (select (r->>'plot_id')::uuid from _r) and crop_id = :AVOCADO and tree_count = 40), 1,
    'each cycle keeps its own measure');
rollback;

-- the same crop twice on one plot is refused
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
  set local role authenticated;
  select pg_temp.assert_raises($q$ select app_register_farmer(jsonb_build_object(
    'client_ref', '99000000-0000-4000-8000-0000000000c2',
    'village_id', '30000000-0000-4000-8000-000000000001',
    'person', jsonb_build_object('given_name', 'Dup', 'family_name', 'Crop', 'phone', '0712000932'),
    'household', jsonb_build_object('label', 'Dup'),
    'farm', jsonb_build_object('label', 'x', 'latitude', '-8.13', 'longitude', '35.19'),
    'plot', jsonb_build_object('label', 'x', 'area_ha', '1'),
    'cycles', jsonb_build_array(
      jsonb_build_object('crop_id', '40000000-0000-4000-8000-000000000001', 'area_ha', '0.5'),
      jsonb_build_object('crop_id', '40000000-0000-4000-8000-000000000001', 'area_ha', '0.5')))) $q$,
    'the same crop twice on one plot is refused');

  -- one crop's missing measure refuses the whole registration
  select pg_temp.assert_raises($q$ select app_register_farmer(jsonb_build_object(
    'client_ref', '99000000-0000-4000-8000-0000000000c3',
    'village_id', '30000000-0000-4000-8000-000000000001',
    'person', jsonb_build_object('given_name', 'NoMeasure', 'family_name', 'Crop', 'phone', '0712000933'),
    'household', jsonb_build_object('label', 'NoMeasure'),
    'farm', jsonb_build_object('label', 'x', 'latitude', '-8.13', 'longitude', '35.19'),
    'plot', jsonb_build_object('label', 'x', 'area_ha', '1'),
    'cycles', jsonb_build_array(
      jsonb_build_object('crop_id', '40000000-0000-4000-8000-000000000001', 'area_ha', '0.5'),
      jsonb_build_object('crop_id', '40000000-0000-4000-8000-000000000002')))) $q$,
    'a second crop without its measure refuses the registration');
  select pg_temp.assert_eq((select count(*) from person where family_name = 'Crop' and given_name = 'NoMeasure'), 0,
    'a refused registration leaves no person behind');
rollback;

-- the single-cycle payload an older client sends still registers
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
  set local role authenticated;
  create temp table _r on commit drop as
  select app_register_farmer(jsonb_build_object(
    'client_ref', '99000000-0000-4000-8000-0000000000c4',
    'village_id', '30000000-0000-4000-8000-000000000001',
    'person', jsonb_build_object('given_name', 'Legacy', 'family_name', 'Crop', 'phone', '0712000934'),
    'household', jsonb_build_object('label', 'Legacy'),
    'farm', jsonb_build_object('label', 'x', 'latitude', '-8.13', 'longitude', '35.19'),
    'plot', jsonb_build_object('label', 'x', 'area_ha', '1'),
    'cycle', jsonb_build_object('crop_id', :MAIZE, 'area_ha', '0.5'),
    'harvest', jsonb_build_object('quantity_kg', '900'))) as r;
  select pg_temp.assert_eq((select count(*) from harvest_report
    where id = (select (r->>'harvest_report_id')::uuid from _r) and quantity_kg = 900), 1,
    'a single cycle + harvest payload still registers');
rollback;

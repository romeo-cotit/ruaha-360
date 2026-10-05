-- ============================================================
-- Resource catalogue — 20261005090004_resource_catalogue
-- Included by rls_test.sql. Every block is rolled back.
-- ============================================================

\set PROJECT  '''20000000-0000-4000-8000-000000000001'''
\set MILLING  '''50000000-0000-4000-8000-000000000001'''
\set BUY_ONLY '''51000000-0000-4000-8000-0000000000d1'''
\set RENTABLE '''51000000-0000-4000-8000-0000000000d2'''
\set BOTH     '''51000000-0000-4000-8000-0000000000d3'''

-- ops adds equipment and loan listings to its own project
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
  set local role authenticated;

  insert into equipment (project_id, category_id, code, name_en, name_sw, rated_power_kw,
                         can_rent, can_buy, indicative_rent_per_day, indicative_price)
  values (:PROJECT, :MILLING, 'TST-RENT', 'Test mill', 'Mashine ya majaribio', 5.5, true, false, 50000, null);
  select pg_temp.assert_eq((select count(*) from equipment where code = 'TST-RENT' and can_rent and not can_buy), 1,
    'ops adds equipment offered for rent only');

  insert into loan_product (project_id, code, name_en, name_sw, indicative_min_amount, indicative_max_amount)
  values (:PROJECT, 'TST-LOAN', 'Test loan', 'Mkopo wa majaribio', 100000, 500000);
  select pg_temp.assert_eq((select count(*) from loan_product where code = 'TST-LOAN'), 1,
    'ops adds a loan listing');

  select pg_temp.assert_raises($q$ insert into equipment (project_id, category_id, code, name_en, name_sw, can_rent, can_buy)
    values ('20000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000001', 'TST-NONE', 'x', 'x', false, false) $q$,
    'equipment must be offered to rent or to buy', '23514');
  select pg_temp.assert_raises($q$ insert into loan_product (project_id, code, name_en, name_sw, indicative_min_amount, indicative_max_amount)
    values ('20000000-0000-4000-8000-000000000001', 'TST-BAD', 'x', 'x', 900, 100) $q$,
    'a loan range cannot run backwards', '23514');
  select pg_temp.assert_raises($q$ delete from loan_product where code = 'TST-LOAN' $q$,
    'a loan listing is retired, never deleted', '42501');

  -- a listing only: the table has nowhere to put finance terms
  select pg_temp.assert_eq((select count(*) from information_schema.columns
    where table_name = 'loan_product'
      and column_name ~ '(interest|rate|deposit|term|schedule|repay|tenor|apr)'), 0,
    'a loan listing carries no finance terms (research item C)');
rollback;

-- officers and farmers read the catalogue but do not write it
begin;
  -- privileged fixture: one listing to read
  insert into loan_product (project_id, code, name_en, name_sw, indicative_min_amount, indicative_max_amount)
  values (:PROJECT, 'TST-READ', 'Readable', 'Inasomeka', 1, 2);

  select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
  set local role authenticated;
  select pg_temp.assert_raises($q$ insert into loan_product (project_id, code, name_en, name_sw, indicative_min_amount, indicative_max_amount)
    values ('20000000-0000-4000-8000-000000000001', 'OFF', 'x', 'x', 1, 2) $q$,
    'an officer cannot add a loan listing', '42501');

  select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
  select pg_temp.assert_raises($q$ insert into equipment (project_id, category_id, code, name_en, name_sw)
    values ('20000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000001', 'FRM', 'x', 'x') $q$,
    'a farmer cannot add equipment', '42501');
  select pg_temp.assert_eq((select count(*) from loan_product where code = 'TST-READ'), 1,
    'a farmer can read the loan listings of their project');
rollback;

-- a request asks for what the catalogue offers, and keeps it once submitted
begin;
  -- privileged fixtures: one machine to buy only, one to rent only
  insert into equipment (id, project_id, category_id, code, name_en, name_sw, rated_power_kw, can_rent, can_buy, indicative_price, indicative_rent_per_day)
  values (:BUY_ONLY, :PROJECT, :MILLING, 'TST-B', 'Buy only', 'Kununua tu', 1, false, true, 1000, null),
         (:RENTABLE, :PROJECT, :MILLING, 'TST-R', 'Rent only', 'Kukodi tu', 1, true, false, null, 100),
         (:BOTH,     :PROJECT, :MILLING, 'TST-2', 'Either',    'Vyote',     1, true, true, 1000, 100);

  select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
  set local role authenticated;

  select pg_temp.assert_raises($q$ insert into pue_request (village_id, person_id, equipment_id, status, source, captured_by, acquisition)
    values ('30000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', '51000000-0000-4000-8000-0000000000d1',
            'submitted', 'farmer_reported', '80000000-0000-4000-8000-000000000005', 'rent') $q$,
    'a machine offered only for sale cannot be requested on rent');
  select pg_temp.assert_raises($q$ insert into pue_request (village_id, person_id, equipment_id, status, source, captured_by, acquisition)
    values ('30000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', '51000000-0000-4000-8000-0000000000d2',
            'submitted', 'farmer_reported', '80000000-0000-4000-8000-000000000005', 'buy') $q$,
    'a machine offered only on rent cannot be requested to buy');

  insert into pue_request (id, village_id, person_id, equipment_id, status, source, captured_by, acquisition)
  values ('d0000000-0000-4000-8000-0000000000d1', '30000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001',
          :BOTH, 'submitted', 'farmer_reported', :FARM_NEE, 'rent');
  select pg_temp.assert_eq((select count(*) from pue_request where id = 'd0000000-0000-4000-8000-0000000000d1' and acquisition = 'rent'), 1,
    'a farmer requests a machine on rent');

  select pg_temp.assert_raises($q$ update pue_request set acquisition = 'buy' where id = 'd0000000-0000-4000-8000-0000000000d1' $q$,
    'a submitted request cannot switch between rent and buy');
  select pg_temp.assert_eq((select count(*) from pue_request where id = 'd0000000-0000-4000-8000-0000000000d1' and acquisition = 'rent'), 1,
    'and stays on rent');

  -- the pipeline does not count a rent as a purchase price
  select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
  select pg_temp.assert_eq((select count(*) from v_village_pue_pipeline
    where village_id = '30000000-0000-4000-8000-000000000001' and status = 'submitted'
      and indicative_rent_per_day = 100), 1,
    'a rent request adds its rent per day, not a price, to the pipeline');
rollback;

-- seeded requests are all to buy, so the Tower's figures are unchanged
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
  set local role authenticated;
  select pg_temp.assert_eq((select count(*) from pue_request
    where id::text like 'd0000000-0000-4000-8000-00000000000%' and acquisition <> 'buy'), 0,
    'every seeded request is a purchase');
rollback;

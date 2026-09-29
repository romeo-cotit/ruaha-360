-- Included by rls_test.sql; every synthetic change rolls back.
begin;
select pg_temp.assert_eq((select count(*) from pg_roles where rolname = 'ruaha_observed_writer'
  and not rolcanlogin and not rolbypassrls and not rolsuper), 1, 'RPC writer cannot login or bypass RLS');
select pg_temp.assert_eq((select count(*) from pg_class c join pg_roles r on r.oid = c.relowner
  where r.rolname = 'ruaha_observed_writer' and c.relkind in ('r','p')), 0, 'RPC writer owns no tables');
select pg_temp.assert_eq(pg_has_role('authenticated','ruaha_observed_writer','MEMBER')::int::bigint,0,'client cannot assume writer');
select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
set local role authenticated;
select pg_temp.assert_eq((select count(*) from app_user),1,'full account profile is self-only');
select pg_temp.assert_raises($q$ update app_user set person_id = '60000000-0000-4000-8000-000000000002' where id = auth.uid() $q$,'identity reassignment denied','42501');
select pg_temp.assert_raises($q$ update person set verification = 'verified' where id = app_person_id() $q$,'farmer verification spoof denied','42501');
select pg_temp.assert_raises($q$ update person set captured_by = auth.uid() where id = app_person_id() $q$,'farmer provenance spoof denied','42501');
update app_user set locale = 'en', display_name = 'Synthetic temporary name' where id = auth.uid();
select pg_temp.assert_eq((select count(*) from app_user where locale = 'en' and display_name = 'Synthetic temporary name'),1,'safe self preferences remain editable');
rollback;

begin;
select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
set local role authenticated;
select pg_temp.assert_eq((select count(*) from buyer_demand),0,'officer cannot read buyer order book');
select pg_temp.assert_raises($q$ update person set verification = 'verified' where id = '60000000-0000-4000-8000-000000000003' $q$,'officer cannot bypass verification RPC','42501');
select pg_temp.assert_raises($q$ insert into household_member(household_id,person_id) values ('70000000-0000-4000-8000-000000000001','60000000-0000-4000-8000-000000000007') $q$,'direct relationship injection denied','42501');
select pg_temp.assert_raises($q$ insert into opportunity_supply(opportunity_id,harvest_report_id,crop_cycle_id,contributed_kg)
values ('e2000000-0000-4000-8000-000000000001','c0000000-0000-4000-8000-000000000002','b0000000-0000-4000-8000-000000000001',1) $q$,'officer supply write denied','42501');
with changed as (update opportunity set status = 'declined' returning id)
select pg_temp.assert_eq((select count(*) from changed),0,'officer opportunity update affects no rows');
-- RPC registration both enforces scope and remains atomic/idempotent.
select app_register_farmer('{"client_ref":"99000000-0000-4000-8000-000000000001","village_id":"30000000-0000-4000-8000-000000000001","person":{"given_name":"MVP","family_name":"Test","phone":"0712000801"},"household":{"label":"MVP fixture"},"farm":{"label":"MVP fixture","latitude":"-8.13","longitude":"35.19"},"plot":{"label":"MVP fixture","area_ha":"1"}}');
select pg_temp.assert_eq((select count(*) from person where family_name = 'Test' and given_name = 'MVP'),1,'RPC registration remains usable');
select app_register_farmer('{"client_ref":"99000000-0000-4000-8000-000000000001","village_id":"30000000-0000-4000-8000-000000000001"}');
select pg_temp.assert_eq((select count(*) from person where family_name = 'Test' and given_name = 'MVP'),1,'registration replay creates no duplicate');
select pg_temp.assert_raises($q$ select app_register_farmer('{"client_ref":"99000000-0000-4000-8000-000000000002","village_id":"30000000-0000-4000-8000-000000000002","person":{"given_name":"MVP","family_name":"Denied","phone":"0712000802"},"farm":{"label":"x","latitude":"-8.13","longitude":"35.19"}}') $q$,'out-of-village registration denied','42501');
rollback;

begin;
select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
set local role authenticated;
select pg_temp.assert_raises($q$ update opportunity set offered_quantity_kg = 1 $q$,'offered total is server-only','42501');
select pg_temp.assert_eq((select committed_kg::bigint from v_demand_match where buyer_demand_id = 'e1000000-0000-4000-8000-000000000001' and village_id = '30000000-0000-4000-8000-000000000001'),6400,'demand view owns committed total');
insert into buyer_demand(id,project_id,buyer_id,crop_id,quantity_kg,window_start,window_end,captured_by,verification)
select 'e1000000-0000-4000-8000-0000000000fe',project_id,buyer_id,crop_id,quantity_kg,window_start,window_end,
  '80000000-0000-4000-8000-000000000005','verified' from buyer_demand where id = 'e1000000-0000-4000-8000-000000000001';
select pg_temp.assert_eq((select count(*) from buyer_demand where id = 'e1000000-0000-4000-8000-0000000000fe'
  and captured_by = auth.uid() and verification = 'unverified'),1,'demand capture cannot be forged');
insert into opportunity(id,buyer_demand_id,village_id,crop_id) values
('e2000000-0000-4000-8000-0000000000fe','e1000000-0000-4000-8000-0000000000fe','30000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001');
select pg_temp.assert_raises($q$ update opportunity set status = 'accepted' where id = 'e2000000-0000-4000-8000-0000000000fe' $q$,'cannot accept before sharing');
update opportunity set status = 'shared' where id = 'e2000000-0000-4000-8000-0000000000fe';
update opportunity set status = 'accepted' where id = 'e2000000-0000-4000-8000-0000000000fe';
update opportunity set status = 'declined' where id = 'e2000000-0000-4000-8000-0000000000fe';
select pg_temp.assert_raises($q$ update opportunity set status = 'proposed' where id = 'e2000000-0000-4000-8000-0000000000fe' $q$,'terminal opportunity cannot reopen');
rollback;

-- A farmer's own request cannot carry forged provenance, and provenance names
-- resolve only for actors on records the caller can already see.
begin;
select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
set local role authenticated;
insert into pue_request(id,village_id,person_id,equipment_id,quantity,hours_per_day,days_per_week,status,
  source,captured_by,verification,verified_by,verified_at)
values ('d0000000-0000-4000-8000-0000000000fe','30000000-0000-4000-8000-000000000001','60000000-0000-4000-8000-000000000001',
  '51000000-0000-4000-8000-000000000001',1,1,1,'submitted',
  'field_verified','80000000-0000-4000-8000-000000000003','verified','80000000-0000-4000-8000-000000000003',now());
select pg_temp.assert_eq((select count(*) from pue_request where id = 'd0000000-0000-4000-8000-0000000000fe'
  and captured_by = auth.uid() and source = 'farmer_reported' and verification = 'unverified'
  and verified_by is null and verified_at is null),1,'farmer request provenance is normalised, not trusted');
select pg_temp.assert_eq((select count(*) from app_actor_names(array[:OFF_ILU]::uuid[])),1,'farmer resolves the officer on her own records');
select pg_temp.assert_eq((select count(*) from app_actor_names(array[:FARM_JOS, :OFF_MGA]::uuid[])),0,'farmer cannot resolve unrelated account names');
select pg_temp.assert_raises($q$ insert into opportunity(buyer_demand_id,village_id,crop_id) values
  ('e1000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001') $q$,
  'farmer opportunity write denied','42501');
rollback;

-- Protected RPCs are not reachable without a session.
begin;
set local role anon;
select pg_temp.assert_raises($q$ select app_register_farmer('{"client_ref":"99000000-0000-4000-8000-000000000003","village_id":"30000000-0000-4000-8000-000000000001"}') $q$,'anonymous registration denied','42501');
select pg_temp.assert_raises($q$ select app_verify('person','60000000-0000-4000-8000-000000000003') $q$,'anonymous verification denied','42501');
select pg_temp.assert_raises($q$ select app_actor_names(array['80000000-0000-4000-8000-000000000003']::uuid[]) $q$,'anonymous name lookup denied','42501');
rollback;

-- Relationship endpoints must share a village, even for whole-project staff.
begin;
select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
set local role authenticated;
select pg_temp.assert_raises($q$ select app_register_farmer('{"client_ref":"99000000-0000-4000-8000-000000000004","village_id":"30000000-0000-4000-8000-000000000001","person":{"given_name":"MVP","family_name":"Crossing","phone":"0712000803"},"household":{"existing_household_id":"70000000-0000-4000-8000-000000000004"},"farm":{"label":"x","latitude":"-8.13","longitude":"35.19"},"plot":{"label":"x","area_ha":"1"}}') $q$,
  'officer cannot join another village''s household','42501');
rollback;
begin;
select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
set local role authenticated;
select pg_temp.assert_raises($q$ select app_register_farmer('{"client_ref":"99000000-0000-4000-8000-000000000005","village_id":"30000000-0000-4000-8000-000000000001","person":{"given_name":"MVP","family_name":"Crossing","phone":"0712000803"},"household":{"existing_household_id":"70000000-0000-4000-8000-000000000004"},"farm":{"label":"x","latitude":"-8.13","longitude":"35.19"},"plot":{"label":"x","area_ha":"1"}}') $q$,
  'cross-village household join denied for project staff','42501');
select pg_temp.assert_raises($q$ select app_register_farmer('{"client_ref":"99000000-0000-4000-8000-000000000006","village_id":"30000000-0000-4000-8000-000000000001","person":{"given_name":"MVP","family_name":"Crossing","phone":"0712000803"},"household":{"label":"x"},"farm":{"existing_farm_id":"90000000-0000-4000-8000-000000000005"},"plot":{"label":"x","area_ha":"1"}}') $q$,
  'cross-village farm join denied for project staff','42501');
select pg_temp.assert_eq((select count(*) from person where family_name = 'Crossing'),0,'a denied registration leaves nothing behind');
rollback;

-- Legitimate ops work passes, the offered total is server-maintained, and a
-- demand spanning several months counts each current harvest once.
begin;
select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
set local role authenticated;
insert into buyer_demand(id,project_id,buyer_id,crop_id,quantity_kg,window_start,window_end)
select 'e1000000-0000-4000-8000-0000000000fd',project_id,buyer_id,crop_id,quantity_kg,date '2026-06-01',date '2026-11-30'
from buyer_demand where id = 'e1000000-0000-4000-8000-000000000001';
select pg_temp.assert_eq((select available_kg::bigint from v_demand_match where buyer_demand_id = 'e1000000-0000-4000-8000-0000000000fd'
  and village_id = '30000000-0000-4000-8000-000000000001'),5600,'multi-month demand counts Ilundo availability once');
select pg_temp.assert_eq((select committed_kg::bigint from v_demand_match where buyer_demand_id = 'e1000000-0000-4000-8000-0000000000fd'
  and village_id = '30000000-0000-4000-8000-000000000001'),6400,'multi-month demand counts Ilundo commitments once');
select pg_temp.assert_eq((select count(*) from v_demand_match where buyer_demand_id = 'e1000000-0000-4000-8000-0000000000fd'),2,'one row per village, never per harvest');
insert into opportunity(id,buyer_demand_id,village_id,crop_id) values
('e2000000-0000-4000-8000-0000000000fd','e1000000-0000-4000-8000-0000000000fd','30000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001');
insert into opportunity_supply(opportunity_id,harvest_report_id,crop_cycle_id,contributed_kg)
select 'e2000000-0000-4000-8000-0000000000fd',id,crop_cycle_id,100 from harvest_report where id = 'c0000000-0000-4000-8000-000000000004';
select pg_temp.assert_eq((select offered_quantity_kg::bigint from opportunity where id = 'e2000000-0000-4000-8000-0000000000fd'),100,'ops attaches supply and the database sums it');
select pg_temp.assert_raises($q$ insert into opportunity_supply(opportunity_id,harvest_report_id,crop_cycle_id,contributed_kg)
  select 'e2000000-0000-4000-8000-0000000000fd',id,crop_cycle_id,1 from harvest_report where id = 'c0000000-0000-4000-8000-000000000009' $q$,
  'supply from another village is refused');
select pg_temp.assert_raises($q$ insert into opportunity(buyer_demand_id,village_id,crop_id,status) values
  ('e1000000-0000-4000-8000-0000000000fd','30000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001','shared') $q$,
  'an opportunity cannot be born shared');
update opportunity set status = 'lapsed' where id = 'e2000000-0000-4000-8000-0000000000fd';
select pg_temp.assert_raises($q$ update opportunity set status = 'shared' where id = 'e2000000-0000-4000-8000-0000000000fd' $q$,'lapsed is terminal');
rollback;

-- Staff reads are scoped to STAFF villages everywhere, not just in the
-- policies 20260925090001 rewrote. farm_manager, and the two helpers behind
-- household_member and opportunity_supply, still trusted app_is_staff() plus
-- app_villages() — a farmer membership's village included.
begin;
select set_config('request.jwt.claims', json_build_object('sub', :OFF_MGA)::text, true);
set local role authenticated;
select pg_temp.assert_eq((select count(*) from farm_manager where farm_id in ('90000000-0000-4000-8000-000000000001',
  '90000000-0000-4000-8000-000000000002','90000000-0000-4000-8000-000000000003','90000000-0000-4000-8000-000000000004')),
  0,'Mgama officer reads no Ilundo farm managers');
select pg_temp.assert_eq((select count(*) from farm_manager),1,'Mgama officer reads exactly Mgama farm managers');
rollback;
begin;
select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
set local role authenticated;
select pg_temp.assert_eq((select count(*) from farm_manager where farm_id in ('90000000-0000-4000-8000-000000000001',
  '90000000-0000-4000-8000-000000000002','90000000-0000-4000-8000-000000000003','90000000-0000-4000-8000-000000000004')),
  4,'Ilundo officer still reads Ilundo farm managers');
select pg_temp.assert_eq((select count(*) from farm_manager where farm_id = '90000000-0000-4000-8000-000000000005'),
  0,'Ilundo officer reads no Mgama farm managers');
rollback;
begin;
select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
set local role authenticated;
select pg_temp.assert_eq((select count(*) from farm_manager where farm_id::text like '90000000-0000-4000-8000-00000000000_'),
  5,'project-wide ops still reads every seeded farm manager');
rollback;
begin;
select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
set local role authenticated;
select pg_temp.assert_eq((select count(*) from farm_manager where farm_id = '90000000-0000-4000-8000-000000000001'),
  1,'farmer still reads her own farm manager');
rollback;

-- Mixed membership: Joseph farms in Ilundo and is made a field officer in
-- Mgama only. Staff reach must stop at Mgama; his Ilundo view stays a
-- farmer's. A Mgama opportunity with supply is added so the staff read of
-- opportunity_supply has something legitimate to find.
begin;
insert into membership(user_id,role,project_id,village_id) values
  (:FARM_JOS,'field_officer','20000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000002');
insert into opportunity(id,buyer_demand_id,village_id,crop_id) values
  ('e2000000-0000-4000-8000-0000000000fc','e1000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000002','40000000-0000-4000-8000-000000000001');
insert into opportunity_supply(opportunity_id,harvest_report_id,crop_cycle_id,contributed_kg)
  select 'e2000000-0000-4000-8000-0000000000fc',id,crop_cycle_id,100 from harvest_report where id = 'c0000000-0000-4000-8000-000000000009';
select set_config('request.jwt.claims', json_build_object('sub', :FARM_JOS)::text, true);
set local role authenticated;
select pg_temp.assert_eq((select count(*) from household_member where household_id not in
  ('70000000-0000-4000-8000-000000000002','70000000-0000-4000-8000-000000000004')),
  0,'mixed membership: no staff read of other Ilundo household members');
select pg_temp.assert_eq((select count(*) from household_member where household_id = '70000000-0000-4000-8000-000000000002'),
  2,'mixed membership: own household still read as a farmer');
select pg_temp.assert_eq((select count(*) from household_member where household_id = '70000000-0000-4000-8000-000000000004'),
  1,'mixed membership: Mgama household members read as staff');
select pg_temp.assert_eq((select count(*) from opportunity_supply s where s.opportunity_id <> 'e2000000-0000-4000-8000-0000000000fc'),
  0,'mixed membership: no staff read of Ilundo opportunity supply');
select pg_temp.assert_eq((select count(*) from opportunity_supply where opportunity_id = 'e2000000-0000-4000-8000-0000000000fc'),
  1,'mixed membership: Mgama opportunity supply read as staff');
select pg_temp.assert_eq((select count(*) from farm_manager where farm_id in ('90000000-0000-4000-8000-000000000001',
  '90000000-0000-4000-8000-000000000003','90000000-0000-4000-8000-000000000004')),
  0,'mixed membership: no staff read of other Ilundo farm managers');
select pg_temp.assert_eq((select count(*) from farm_manager where farm_id = '90000000-0000-4000-8000-000000000002'),
  1,'mixed membership: own household farm manager still read');
select pg_temp.assert_eq((select count(*) from farm_manager where farm_id = '90000000-0000-4000-8000-000000000005'),
  1,'mixed membership: Mgama farm manager read as staff');
rollback;

-- Removes only browser-suite records, in foreign-key dependency order.
--
-- Matches on the E2E- marker that e2e/support/marker.ts writes into every
-- name and label. Seeded demo records carry no marker, so they are out of
-- reach of every statement here. Runs as postgres, which bypasses RLS ---
-- there are no DELETE policies by design.

begin;

-- The suite has privileged DELETE access. Reject a wrong or empty project
-- before identifying any fixture rows, matching the seed's DEMO safety rail.
do $$
begin
  if not exists (select 1 from project where code like '%-DEMO')
     or exists (select 1 from project where code not like '%-DEMO') then
    raise exception 'refusing E2E cleanup: database is not demo-only';
  end if;
end $$;

create temporary table _e2e_person on commit drop as
  select id from person where family_name like 'E2E-%';

-- Both conditions are required: never delete an unrelated login merely
-- because its email resembles a fixture, or a real account linked to a
-- marked person by mistake. Keep ids before deleting their person rows.
create temporary table _e2e_auth_user on commit drop as
  select u.id from auth.users u
  join app_user a on a.id = u.id
  where u.email like 'e2e-journey-%@demo.ruaha360.test'
    and a.person_id in (select id from _e2e_person);

create temporary table _e2e_receipt on commit drop as
  select client_ref from registration_receipt
  where result->>'person_id' in (select id::text from _e2e_person);

create temporary table _e2e_household on commit drop as
  select distinct hm.household_id as id
  from household_member hm join _e2e_person p on p.id = hm.person_id
  union
  select id from household where label like 'E2E-%';

create temporary table _e2e_farm on commit drop as
  select distinct f.id
  from farm f
  where f.label like 'E2E-%'
     or f.household_id in (select id from _e2e_household)
     or f.id in (select fm.farm_id from farm_manager fm
                 join _e2e_person p on p.id = fm.person_id);

create temporary table _e2e_plot on commit drop as
  select id from plot where farm_id in (select id from _e2e_farm);

create temporary table _e2e_cycle on commit drop as
  select id from crop_cycle where plot_id in (select id from _e2e_plot);

-- Demands and opportunities the suite created, marked through their own free
-- text: quality_note on buyer_demand and note on opportunity. Both are
-- created against SEEDED crops and villages, so there is no person to trace
-- them from.
create temporary table _e2e_demand on commit drop as
  select id from buyer_demand where quality_note like 'E2E-%';

create temporary table _e2e_opportunity on commit drop as
  select id from opportunity
  where note like 'E2E-%' or buyer_demand_id in (select id from _e2e_demand);

-- leaves first
delete from opportunity_supply where opportunity_id in (select id from _e2e_opportunity);
delete from opportunity where id in (select id from _e2e_opportunity);
delete from buyer_demand where id in (select id from _e2e_demand);

delete from opportunity_supply where crop_cycle_id in (select id from _e2e_cycle);
delete from harvest_report where crop_cycle_id in (select id from _e2e_cycle);
-- PUE requests are marked through `purpose`, because the suite submits them
-- as SEEDED farmers: a request left behind by Neema would shift the Tower's
-- prospective demand for good, and the seeded figures are specification.
delete from energy_estimate where pue_request_id in (
  select id from pue_request
  where person_id in (select id from _e2e_person) or purpose like 'E2E-%'
);
delete from pue_request
 where person_id in (select id from _e2e_person) or purpose like 'E2E-%';
delete from crop_cycle where id in (select id from _e2e_cycle);
delete from plot where id in (select id from _e2e_plot);
delete from farm_manager where farm_id in (select id from _e2e_farm);
delete from farm where id in (select id from _e2e_farm);
delete from household_member where household_id in (select id from _e2e_household);
delete from household where id in (select id from _e2e_household);
delete from person where id in (select id from _e2e_person);

delete from registration_receipt where client_ref in (select client_ref from _e2e_receipt);

-- Requests and observed rows have been removed, so no provenance FK points
-- at the synthetic login. Membership is removed before the auth identity.
delete from membership where user_id in (select id from _e2e_auth_user);

-- Check every current FK to app_user, including future migration additions.
-- A failed check rolls back this whole cleanup instead of deleting an actor
-- that remains attached to any record.
do $$
declare fk record; still_referenced boolean;
begin
  for fk in
    select c.conrelid::regclass as table_name, a.attname as column_name
    from pg_constraint c
    join pg_attribute a on a.attrelid = c.conrelid and a.attnum = c.conkey[1]
    where c.contype = 'f' and c.confrelid = 'app_user'::regclass
      and array_length(c.conkey, 1) = 1
  loop
    execute format(
      'select exists (select 1 from %s where %I in (select id from _e2e_auth_user))',
      fk.table_name, fk.column_name
    ) into still_referenced;
    if still_referenced then
      raise exception 'refusing E2E account cleanup: %.% still references synthetic account',
        fk.table_name, fk.column_name;
    end if;
  end loop;
end $$;

delete from app_user where id in (select id from _e2e_auth_user);
delete from auth.identities where user_id in (select id from _e2e_auth_user);
delete from auth.users where id in (select id from _e2e_auth_user);

commit;

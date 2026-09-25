-- Follow-up to 20260925090001_mvp_security: finish scoping staff reads to
-- STAFF villages.
--
-- That migration rewrote every policy that mentions app_is_staff() to use
-- app_staff_villages(), so a person who is a farmer in one village and staff
-- in another gets staff access only where they are staff. Three reads escaped
-- the rewrite because the staff check is not written in the policy text:
--
--   app_staff_households()    behind household_member.hm_read
--   app_staff_opportunities() behind opportunity_supply.opp_supply_read
--   farm_manager.fm_read      app_is_staff() with no village filter at all,
--                             so any staff user read every farm_manager row
--
-- The helpers keep their signatures, so existing policies and grants stand.
-- app_staff_villages() returns villages only for staff memberships, which
-- makes the separate app_is_staff() guard redundant; it is dropped.

create or replace function app_staff_households() returns setof uuid
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select h.id
  from public.household h
  where h.village_id in (select public.app_staff_villages())
$$;

create or replace function app_staff_opportunities() returns setof uuid
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select o.id
  from public.opportunity o
  where o.village_id in (select public.app_staff_villages())
$$;

-- `create or replace` keeps the existing ACL; restate it so this file alone
-- says who may call them.
revoke all on function app_staff_households() from public, anon;
revoke all on function app_staff_opportunities() from public, anon;
grant execute on function app_staff_households() to authenticated;
grant execute on function app_staff_opportunities() to authenticated;

-- The farm subquery runs under the caller's farm policies, which already scope
-- staff to app_staff_villages(); the explicit filter keeps this policy correct
-- on its own rather than by inheritance.
alter policy fm_read on farm_manager
  using (
    farm_id in (select app_farms())
    or farm_id in (select f.id from farm f where f.village_id in (select app_staff_villages()))
  );

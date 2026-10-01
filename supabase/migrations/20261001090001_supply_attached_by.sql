-- Ruaha 360 · who attached each supply line
--
-- Picking a harvest on an opportunity is picking a farmer, and a supply line
-- cannot be detached. The audit log already records who attached each line,
-- but audit_log has no read policy, so the screen could not say. This puts the
-- attacher on the line itself, the way opportunity and buyer_demand carry
-- captured_by, and lets anyone who can read the line resolve that name.
--
-- Requested and approved on 1 Oct 2026.

alter table opportunity_supply
  add column captured_by uuid references app_user(id),
  add column captured_at timestamptz;

-- Backfill from the audit log's insert row. Seeded lines were written with no
-- signed-in actor and stay null: no name is invented for them.
-- The guard and the re-sum are not part of a backfill (the guard would refuse
-- lines on declined opportunities); the audit trigger stays on, so the
-- backfill is itself on the record.
alter table opportunity_supply disable trigger opportunity_supply_guard_trg;
alter table opportunity_supply disable trigger opportunity_resum_trg;

update opportunity_supply s
set captured_by = a.actor, captured_at = a.at
from (
  select distinct on (record_id) record_id, actor, occurred_at as at
  from audit_log
  where table_name = 'opportunity_supply' and action = 'insert'
    and (actor is null or actor in (select id from app_user))
  order by record_id, occurred_at
) a
where a.record_id = s.id;

update opportunity_supply set captured_at = created_at where captured_at is null;

alter table opportunity_supply enable trigger opportunity_supply_guard_trg;
alter table opportunity_supply enable trigger opportunity_resum_trg;

alter table opportunity_supply
  alter column captured_at set default now(),
  alter column captured_at set not null;

-- The attacher is the caller, whatever the client sends, and it never changes.
-- stamp_captured_input is not reused: it also stamps `verification`, which a
-- supply line does not have.
create function stamp_supply_attached() returns trigger
language plpgsql set search_path = pg_catalog, public, pg_temp as $$
begin
  if tg_op = 'INSERT' then
    if auth.uid() is not null then -- null is the privileged path (seed, fixtures)
      new.captured_by := auth.uid();
      new.captured_at := now();
    end if;
  else
    new.captured_by := old.captured_by;
    new.captured_at := old.captured_at;
  end if;
  return new;
end $$;
create trigger opportunity_supply_capture before insert or update on opportunity_supply
  for each row execute function stamp_supply_attached();

-- Same body as 20260929090003, plus one line: whoever attached a supply line
-- the caller may read (opp_supply_read's own scope).
create or replace function app_actor_names(p_ids uuid[]) returns table(id uuid, display_name text)
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select u.id, u.display_name from public.app_user u
  where u.id = any(p_ids) and (
    u.id = auth.uid() or u.id in (
      select captured_by from public.person where id = app_person_id() or id in (select app_household_persons()) or village_id in (select app_staff_villages())
      union select verified_by from public.person where id = app_person_id() or id in (select app_household_persons()) or village_id in (select app_staff_villages())
      union select captured_by from public.farm where id in (select app_farms()) or village_id in (select app_staff_villages())
      union select verified_by from public.farm where id in (select app_farms()) or village_id in (select app_staff_villages())
      union select captured_by from public.pue_request where person_id = app_person_id() or village_id in (select app_staff_villages())
      union select captured_by from public.household where id in (select app_households()) or village_id in (select app_staff_villages())
      union select verified_by from public.household where id in (select app_households()) or village_id in (select app_staff_villages())
      union select created_by from public.survey where project_id in (select app_projects()) and app_manages_project(project_id)
      union select published_by from public.survey where project_id in (select app_projects())
      union select captured_by from public.opportunity_supply where opportunity_id in (select app_staff_opportunities())
    )
  )
$$;

-- Protected writes use a non-login, non-owner role. JWT identity still drives
-- RLS inside each RPC; clients cannot assume this role or write around RPCs.
create role ruaha_observed_writer nologin noinherit nobypassrls;
grant ruaha_observed_writer to postgres;
grant usage on schema public to ruaha_observed_writer;
grant create on schema public to ruaha_observed_writer;
revoke create on schema public from public, anon, authenticated;

-- Managed auth schema cannot grant USAGE to custom roles through postgres.
-- Project only the request actor, without giving the writer any auth access.
create function app_actor_id() returns uuid
language sql stable security definer set search_path = pg_catalog as $$ select auth.uid() $$;
revoke all on function app_actor_id() from public, anon;
grant execute on function app_actor_id() to authenticated, ruaha_observed_writer;

create function app_staff_villages() returns setof uuid
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select distinct v.id from public.membership m join public.village v
    on v.project_id = m.project_id and (m.village_id is null or m.village_id = v.id)
  where m.user_id = auth.uid() and m.revoked_at is null
    and m.role in ('field_officer','ops','admin')
$$;
revoke all on function app_staff_villages() from public, anon;
grant execute on function app_staff_villages() to authenticated, ruaha_observed_writer;

revoke update on app_user from authenticated, anon;
grant update (locale, display_name) on app_user to authenticated;
alter policy app_user_read on app_user using (id = auth.uid());
drop policy person_update_self on person;

do $$
declare t text; p record;
begin
  foreach t in array array['person','household','farm','plot','crop_cycle','harvest_report'] loop
    execute format('revoke insert, update, delete on %I from authenticated, anon', t);
    execute format('grant select, insert, update on %I to ruaha_observed_writer', t);
    execute format('create policy rpc_writer on %I for all to ruaha_observed_writer
      using (village_id in (select app_staff_villages()))
      with check (village_id in (select app_staff_villages()))', t);
  end loop;
  -- Mixed memberships must not give an officer staff access to their farmer village.
  for p in select * from pg_policies where schemaname = 'public'
    and (qual like '%%app_is_staff%%' or with_check like '%%app_is_staff%%') loop
    execute format('alter policy %I on %I %s %s', p.policyname, p.tablename,
      case when p.qual is null then '' else 'using (' || replace(p.qual, 'app_villages()', 'app_staff_villages()') || ')' end,
      case when p.with_check is null then '' else 'with check (' || replace(p.with_check, 'app_villages()', 'app_staff_villages()') || ')' end);
  end loop;
end $$;

revoke insert, update, delete on household_member, farm_manager, registration_receipt from authenticated, anon;
grant select, insert, update on household_member, farm_manager to ruaha_observed_writer;
grant select, insert on registration_receipt to ruaha_observed_writer;
grant select on village, crop to ruaha_observed_writer;
create policy rpc_reference_read on village for select to ruaha_observed_writer using (true);
create policy rpc_reference_read on crop for select to ruaha_observed_writer using (true);
create policy rpc_receipt_read on registration_receipt for select to ruaha_observed_writer using (created_by = app_actor_id());
create policy rpc_receipt_write on registration_receipt for insert to ruaha_observed_writer with check (created_by = app_actor_id());

-- Only this role can write these relationships. Endpoint reads use its scoped
-- RLS policies; no reciprocal policy joins are introduced for client roles.
create policy rpc_household_member on household_member for all to ruaha_observed_writer
  using (household_id in (select id from household))
  with check (exists (select 1 from household h join person p on p.village_id = h.village_id
    where h.id = household_id and p.id = person_id and h.deleted_at is null and p.deleted_at is null));
create policy rpc_farm_manager on farm_manager for all to ruaha_observed_writer
  using (farm_id in (select id from farm))
  with check (exists (select 1 from farm f join person p on p.village_id = f.village_id
    where f.id = farm_id and p.id = person_id and f.deleted_at is null and p.deleted_at is null));

-- EXECUTE does not set PL/pgSQL FOUND. Check the returned value instead.
create or replace function app_verify(p_table text, p_id uuid) returns void
language plpgsql security invoker set search_path = pg_catalog, public, pg_temp as $$
declare v_status verification_status;
begin
  if p_table not in ('person','household','farm','plot','crop_cycle','harvest_report') then
    raise exception 'not a verifiable table: %', p_table;
  end if;
  if not app_is_staff() then raise exception 'only field staff may verify records'; end if;
  execute format('select verification from public.%I where id = $1 and deleted_at is null for update', p_table)
    into v_status using p_id;
  if v_status is null then raise exception 'record not found or outside your villages'; end if;
  if v_status not in ('unverified','pending') then raise exception 'record is not awaiting verification'; end if;
  execute format('update public.%I set verification = ''verified'', verified_by = auth.uid(), verified_at = now() where id = $1', p_table) using p_id;
end $$;

do $$
declare f regprocedure;
begin
  foreach f in array array[
    'app_register_farmer(jsonb)'::regprocedure,
    'app_update_observed_record(text,uuid,jsonb)'::regprocedure,
    'app_verify(text,uuid)'::regprocedure,
    'app_supersede_harvest(uuid,harvest_kind,numeric,source_type,confidence_level,date)'::regprocedure
  ] loop
    -- Preserve complete existing validation and signatures, replacing only the
    -- managed-auth accessor with its narrowly granted equivalent.
    execute replace(pg_get_functiondef(f), 'auth.uid()', 'public.app_actor_id()');
    execute format('alter function %s security definer', f);
    execute format('alter function %s set search_path = pg_catalog, public, pg_temp', f);
    execute format('alter function %s owner to ruaha_observed_writer', f);
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- Provenance names are projected only for actors on caller-visible records.
revoke create on schema public from ruaha_observed_writer;
-- This helper exposes names only, and checks scope before lookup.
create function app_actor_names(p_ids uuid[]) returns table(id uuid, display_name text)
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select u.id, u.display_name from public.app_user u
  where u.id = any(p_ids) and (
    u.id = auth.uid() or u.id in (
      select captured_by from public.person where id = app_person_id() or id in (select app_household_persons()) or village_id in (select app_staff_villages())
      union select verified_by from public.person where id = app_person_id() or id in (select app_household_persons()) or village_id in (select app_staff_villages())
      union select captured_by from public.farm where id in (select app_farms()) or village_id in (select app_staff_villages())
      union select verified_by from public.farm where id in (select app_farms()) or village_id in (select app_staff_villages())
      union select captured_by from public.pue_request where person_id = app_person_id() or village_id in (select app_staff_villages())
    )
  )
$$;
revoke all on function app_actor_names(uuid[]) from public, anon;
grant execute on function app_actor_names(uuid[]) to authenticated;

create function app_manage_village(p_village uuid) returns boolean
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select exists (select 1 from public.village v where v.id = p_village and app_manages_project(v.project_id))
$$;
create function app_manage_opportunity(p_opportunity uuid) returns boolean
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select exists (select 1 from public.opportunity o where o.id = p_opportunity and app_manage_village(o.village_id))
$$;
revoke all on function app_manage_village(uuid), app_manage_opportunity(uuid) from public, anon;
grant execute on function app_manage_village(uuid), app_manage_opportunity(uuid) to authenticated;
alter policy opportunity_write on opportunity with check (app_manage_village(village_id));
alter policy opportunity_update on opportunity using (app_manage_village(village_id)) with check (app_manage_village(village_id));
alter policy opp_supply_write on opportunity_supply with check (app_manage_opportunity(opportunity_id));
alter policy opp_supply_update on opportunity_supply using (app_manage_opportunity(opportunity_id)) with check (app_manage_opportunity(opportunity_id));
alter policy buyer_read on buyer using (app_manages_project(project_id));
alter policy demand_read on buyer_demand using (app_manages_project(project_id));

-- Restrict client columns; triggers remain sole writers of computed metadata.
revoke update on opportunity from authenticated;
grant update (status, note) on opportunity to authenticated;
revoke insert on opportunity from authenticated;
grant insert (id, buyer_demand_id, village_id, crop_id, note, status) on opportunity to authenticated;

create function stamp_captured_input() returns trigger
language plpgsql set search_path = pg_catalog, public, pg_temp as $$
begin
  if auth.uid() is null then return new; end if; -- privileged synthetic fixtures
  if tg_op = 'INSERT' then
    new.captured_by := auth.uid(); new.captured_at := now();
    new.verification := 'unverified';
    if tg_table_name = 'pue_request' then
      new.source := 'farmer_reported'; new.verified_by := null; new.verified_at := null;
    end if;
  else
    new.captured_by := old.captured_by; new.captured_at := old.captured_at;
    new.verification := old.verification;
    if tg_table_name = 'pue_request' then
      new.source := old.source; new.verified_by := old.verified_by; new.verified_at := old.verified_at;
    end if;
  end if;
  return new;
end $$;
create trigger pue_capture before insert or update on pue_request for each row execute function stamp_captured_input();
create trigger demand_capture before insert or update on buyer_demand for each row execute function stamp_captured_input();

create function opportunity_guard() returns trigger
language plpgsql set search_path = pg_catalog, public, pg_temp as $$
begin
  if auth.uid() is not null and not app_manage_village(new.village_id) then
    raise exception 'only project ops or admin may write opportunities' using errcode = '42501';
  end if;
  if tg_op = 'INSERT' then
    if new.status <> 'proposed' then raise exception 'an opportunity must start as proposed'; end if;
    new.offered_quantity_kg := 0;
    new.captured_by := auth.uid(); new.captured_at := now();
  elsif new.status is distinct from old.status then
    if not ((old.status = 'proposed' and new.status in ('shared','declined','lapsed'))
      or (old.status = 'shared' and new.status in ('accepted','declined','lapsed'))
      or (old.status = 'accepted' and new.status in ('declined','lapsed'))) then
      raise exception 'illegal opportunity transition % -> %', old.status, new.status;
    end if;
  end if;
  if not exists (select 1 from buyer_demand d join village v on v.project_id = d.project_id
    where d.id = new.buyer_demand_id and v.id = new.village_id and d.crop_id = new.crop_id) then
    raise exception 'opportunity must match the demand crop and project';
  end if;
  return new;
end $$;
create trigger opportunity_guard_trg before insert or update on opportunity for each row execute function opportunity_guard();

create or replace function opportunity_supply_guard() returns trigger
language plpgsql security definer set search_path = pg_catalog, public, pg_temp as $$
declare h harvest_report; c crop_cycle; o opportunity; committed numeric;
begin
  if auth.uid() is not null and not app_manage_opportunity(new.opportunity_id) then
    raise exception 'only project ops or admin may attach supply' using errcode = '42501';
  end if;
  -- Lock opportunity before harvest consistently with opportunity_resum.
  select * into o from opportunity where id = new.opportunity_id for update;
  select * into h from harvest_report where id = new.harvest_report_id for update;
  select * into c from crop_cycle where id = h.crop_cycle_id;
  if h.id is null or h.deleted_at is not null or not h.is_current or h.kind <> 'expected' then
    raise exception 'supply must reference a current, undeleted expected harvest report';
  end if;
  if o.id is null or o.deleted_at is not null or o.status not in ('proposed','shared','accepted') then
    raise exception 'supply requires a live opportunity';
  end if;
  if new.crop_cycle_id <> h.crop_cycle_id or o.village_id <> h.village_id or o.crop_id <> c.crop_id then
    raise exception 'supply must match the opportunity village, crop and harvest cycle';
  end if;
  select coalesce(sum(s.contributed_kg),0) into committed
    from opportunity_supply s join opportunity other on other.id = s.opportunity_id
    where s.harvest_report_id = h.id and s.id <> new.id and other.deleted_at is null
      and other.status in ('proposed','shared','accepted');
  if committed + new.contributed_kg > h.quantity_kg then
    raise exception 'over-commitment: % kg available, % kg already committed, % kg requested', h.quantity_kg, committed, new.contributed_kg;
  end if;
  return new;
end $$;

create or replace view v_demand_match with (security_invoker = true) as
select bd.id as buyer_demand_id, bd.buyer_id, bd.crop_id, bd.quantity_kg as demand_kg,
  bd.window_start, bd.window_end, supply.village_id, supply.available_kg,
  least(bd.quantity_kg, supply.available_kg) as coverable_kg,
  round(100 * least(bd.quantity_kg, supply.available_kg) / nullif(bd.quantity_kg,0),1) as coverage_pct,
  o.id as opportunity_id, o.status as opportunity_status, supply.committed_kg
from buyer_demand bd
join lateral (
  select ha.village_id, sum(ha.available_kg) as available_kg, sum(ha.committed_kg) as committed_kg
  from v_harvest_available ha where ha.crop_id = bd.crop_id
    and ha.harvest_start <= bd.window_end and ha.harvest_end >= bd.window_start
  group by ha.village_id
) supply on true
left join opportunity o on o.buyer_demand_id = bd.id and o.village_id = supply.village_id and o.deleted_at is null
where bd.deleted_at is null and bd.status = 'open' and app_is_staff();

-- Ruaha 360 · ops creates a village
--
-- Ops can add a village from the Villages screen, together with its first
-- capacity row. The two are written in one call because a village with no
-- capacity row has no energy figures: v_village_energy inner-joins
-- village_capacity, so it would vanish from the Tower.
--
-- Also closes a scoping gap: village and village_capacity writes checked
-- app_has_role('ops'|'admin') in ANY project. Every other ops write was moved
-- to app_manages_project(project_id) in 20260925090001_mvp_security; these
-- two were not.
--
-- Requested and approved on 5 Oct 2026.

drop policy village_write  on village;
drop policy village_update on village;
create policy village_write  on village for insert to authenticated
  with check (app_manages_project(project_id));
create policy village_update on village for update to authenticated
  using (app_manages_project(project_id))
  with check (app_manages_project(project_id));

drop policy capacity_write  on village_capacity;
drop policy capacity_update on village_capacity;
create policy capacity_write  on village_capacity for insert to authenticated
  with check (exists (select 1 from village v
                      where v.id = village_capacity.village_id
                        and app_manages_project(v.project_id)));
create policy capacity_update on village_capacity for update to authenticated
  using (exists (select 1 from village v
                 where v.id = village_capacity.village_id
                   and app_manages_project(v.project_id)))
  with check (exists (select 1 from village v
                      where v.id = village_capacity.village_id
                        and app_manages_project(v.project_id)));

-- Village + first capacity row, in one transaction.
--
-- SECURITY INVOKER: the caller's own policies decide. The village id is the
-- client's draft id, so a retried submit replays instead of creating a second
-- village. Capacity is planned or nameplate, never measured — the enum has no
-- 'measured' value on purpose.
create function app_create_village(payload jsonb) returns jsonb
language plpgsql security invoker set search_path = pg_catalog, public, pg_temp as $$
declare
  v_id      uuid := (payload->>'id')::uuid;
  v_project uuid := (payload->>'project_id')::uuid;
  v_cap     jsonb := payload->'capacity';
begin
  if v_id is null or v_project is null then
    raise exception 'id and project_id are required';
  end if;

  if exists (select 1 from village where id = v_id) then
    return jsonb_build_object('village_id', v_id, 'replayed', true);
  end if;

  if v_cap is null or nullif(v_cap->>'capacity_kw', '') is null then
    raise exception 'a planned capacity is required';
  end if;

  insert into village (id, project_id, code, name, latitude, longitude)
  values (v_id, v_project,
          nullif(btrim(payload->>'code'), ''),
          nullif(btrim(payload->>'name'), ''),
          nullif(payload->>'latitude', '')::numeric,
          nullif(payload->>'longitude', '')::numeric);

  insert into village_capacity (village_id, capacity_kw, basis, simultaneity_factor,
                                source_note, effective_from, is_current)
  values (v_id,
          (v_cap->>'capacity_kw')::numeric,
          coalesce(nullif(v_cap->>'basis', '')::capacity_basis, 'planned'),
          coalesce(nullif(v_cap->>'simultaneity_factor', '')::numeric, 1.000),
          nullif(btrim(v_cap->>'source_note'), ''),
          coalesce(nullif(v_cap->>'effective_from', '')::date, current_date),
          true);

  return jsonb_build_object('village_id', v_id, 'replayed', false);
end $$;

revoke all on function app_create_village(jsonb) from public, anon;
grant execute on function app_create_village(jsonb) to authenticated;

-- Ruaha 360 · officer record corrections
-- Keep observed-record writes allowlisted and server-stamped. The client never
-- writes provenance or verification columns directly.

create or replace function app_update_observed_record(
  p_table text,
  p_id uuid,
  p_payload jsonb
) returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_village uuid;
  v_measure crop_measure;
  v_area numeric;
  v_trees integer;
  v_units integer;
  v_lat numeric;
  v_lon numeric;
  v_start date;
  v_end date;
begin
  if not app_is_staff() then
    raise exception 'only field staff may edit records';
  end if;

  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'record changes must be an object';
  end if;

  if p_table not in ('person', 'household', 'farm', 'plot', 'crop_cycle') then
    raise exception 'record table cannot be edited: %', p_table;
  end if;

  if p_table = 'person' then
    if exists (select 1 from jsonb_object_keys(p_payload) k where k not in ('given_name', 'family_name', 'phone')) then
      raise exception 'person contains an unknown editable field';
    end if;
    if nullif(btrim(p_payload->>'given_name'), '') is null
       or nullif(btrim(p_payload->>'family_name'), '') is null then
      raise exception 'first name and family name are required';
    end if;
    select village_id into v_village from person
    where id = p_id and deleted_at is null;
    if not found then raise exception 'record not found or outside your villages'; end if;

    update person set
      given_name = btrim(p_payload->>'given_name'),
      family_name = btrim(p_payload->>'family_name'),
      phone = nullif(btrim(p_payload->>'phone'), ''),
      source = 'field_verified', captured_at = now(), captured_by = auth.uid(),
      verification = 'unverified', verified_by = null, verified_at = null
    where id = p_id;

  elsif p_table = 'household' then
    if exists (select 1 from jsonb_object_keys(p_payload) k where k not in ('label')) then
      raise exception 'household contains an unknown editable field';
    end if;
    if nullif(btrim(p_payload->>'label'), '') is null then
      raise exception 'household name is required';
    end if;
    select village_id into v_village from household
    where id = p_id and deleted_at is null;
    if not found then raise exception 'record not found or outside your villages'; end if;

    update household set
      label = btrim(p_payload->>'label'),
      source = 'field_verified', captured_at = now(), captured_by = auth.uid(),
      verification = 'unverified', verified_by = null, verified_at = null
    where id = p_id;

  elsif p_table = 'farm' then
    if exists (select 1 from jsonb_object_keys(p_payload) k where k not in ('label', 'latitude', 'longitude')) then
      raise exception 'farm contains an unknown editable field';
    end if;
    if nullif(btrim(p_payload->>'label'), '') is null then
      raise exception 'farm name is required';
    end if;
    v_lat := nullif(p_payload->>'latitude', '')::numeric;
    v_lon := nullif(p_payload->>'longitude', '')::numeric;
    if v_lat is not null and (v_lat < -90 or v_lat > 90) then raise exception 'latitude must be between -90 and 90'; end if;
    if v_lon is not null and (v_lon < -180 or v_lon > 180) then raise exception 'longitude must be between -180 and 180'; end if;
    select village_id into v_village from farm
    where id = p_id and deleted_at is null;
    if not found then raise exception 'record not found or outside your villages'; end if;

    update farm set
      label = btrim(p_payload->>'label'), latitude = v_lat, longitude = v_lon,
      source = 'field_verified', captured_at = now(), captured_by = auth.uid(),
      verification = 'unverified', verified_by = null, verified_at = null
    where id = p_id;

  elsif p_table = 'plot' then
    if exists (select 1 from jsonb_object_keys(p_payload) k where k not in ('label', 'area_ha', 'latitude', 'longitude')) then
      raise exception 'plot contains an unknown editable field';
    end if;
    if nullif(btrim(p_payload->>'label'), '') is null then
      raise exception 'plot name is required';
    end if;
    v_area := nullif(p_payload->>'area_ha', '')::numeric;
    v_lat := nullif(p_payload->>'latitude', '')::numeric;
    v_lon := nullif(p_payload->>'longitude', '')::numeric;
    if v_area is not null and (v_area < 0 or v_area > 999999.9999) then raise exception 'plot area is outside the allowed range'; end if;
    if v_lat is not null and (v_lat < -90 or v_lat > 90) then raise exception 'latitude must be between -90 and 90'; end if;
    if v_lon is not null and (v_lon < -180 or v_lon > 180) then raise exception 'longitude must be between -180 and 180'; end if;
    select village_id into v_village from plot
    where id = p_id and deleted_at is null;
    if not found then raise exception 'record not found or outside your villages'; end if;

    update plot set
      label = btrim(p_payload->>'label'), area_ha = v_area, latitude = v_lat, longitude = v_lon,
      source = 'field_verified', captured_at = now(), captured_by = auth.uid(),
      verification = 'unverified', verified_by = null, verified_at = null
    where id = p_id;

  elsif p_table = 'crop_cycle' then
    if exists (select 1 from jsonb_object_keys(p_payload) k where k not in ('crop_id', 'season_label', 'area_ha', 'tree_count', 'unit_count', 'planted_on', 'harvest_start', 'harvest_end', 'status')) then
      raise exception 'crop cycle contains an unknown editable field';
    end if;
    select village_id into v_village from crop_cycle
    where id = p_id and deleted_at is null;
    if not found then raise exception 'record not found or outside your villages'; end if;
    if nullif(btrim(p_payload->>'crop_id'), '') is null then
      raise exception 'crop is required';
    end if;
    select measured_by into v_measure from crop
      where id = (p_payload->>'crop_id')::uuid and is_active;
    if not found then raise exception 'crop does not exist or is inactive'; end if;

    v_area := nullif(p_payload->>'area_ha', '')::numeric;
    v_trees := nullif(p_payload->>'tree_count', '')::integer;
    v_units := nullif(p_payload->>'unit_count', '')::integer;
    v_start := nullif(p_payload->>'harvest_start', '')::date;
    v_end := nullif(p_payload->>'harvest_end', '')::date;
    if v_area is not null and (v_area < 0 or v_area > 999999.9999) then raise exception 'planted area is outside the allowed range'; end if;
    if v_trees is not null and v_trees < 0 then raise exception 'tree count cannot be negative'; end if;
    if v_units is not null and v_units < 0 then raise exception 'unit count cannot be negative'; end if;
    if v_start is not null and v_end is not null and v_end < v_start then raise exception 'harvest window must end on or after it starts'; end if;
    if v_measure = 'area' and (v_trees is not null or v_units is not null) then raise exception 'only area is valid for this crop'; end if;
    if v_measure = 'tree_count' and (v_area is not null or v_units is not null) then raise exception 'only tree count is valid for this crop'; end if;
    if v_measure = 'unit_count' and (v_area is not null or v_trees is not null) then raise exception 'only unit count is valid for this crop'; end if;
    if v_measure = 'area' and v_area is null then raise exception 'area is required for this crop'; end if;
    if v_measure = 'tree_count' and v_trees is null then raise exception 'tree count is required for this crop'; end if;
    if v_measure = 'unit_count' and v_units is null then raise exception 'unit count is required for this crop'; end if;

    update crop_cycle set
      crop_id = (p_payload->>'crop_id')::uuid,
      season_label = nullif(btrim(p_payload->>'season_label'), ''),
      area_ha = case when v_measure = 'area' then v_area else null end,
      tree_count = case when v_measure = 'tree_count' then v_trees else null end,
      unit_count = case when v_measure = 'unit_count' then v_units else null end,
      planted_on = nullif(p_payload->>'planted_on', '')::date,
      harvest_start = v_start, harvest_end = v_end,
      status = (p_payload->>'status')::crop_cycle_status,
      source = 'field_verified', captured_at = now(), captured_by = auth.uid(),
      verification = 'unverified', verified_by = null, verified_at = null
    where id = p_id;
  end if;

  return jsonb_build_object('table', p_table, 'id', p_id, 'village_id', v_village);
end $$;

grant execute on function app_update_observed_record(text, uuid, jsonb) to authenticated;

-- Keep the history-preserving harvest correction explicitly staff-only.
create or replace function app_supersede_harvest(
  p_cycle uuid, p_kind harvest_kind, p_quantity_kg numeric,
  p_source source_type, p_confidence confidence_level default null,
  p_reported_for date default null
) returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_village uuid;
  v_new uuid;
begin
  if not app_is_staff() then
    raise exception 'only field staff may correct harvest records';
  end if;

  select village_id into v_village from crop_cycle
  where id = p_cycle and deleted_at is null;
  if v_village is null then
    raise exception 'unknown crop cycle';
  end if;

  update harvest_report
     set is_current = false, updated_at = now()
   where crop_cycle_id = p_cycle and kind = p_kind
     and is_current and deleted_at is null;

  insert into harvest_report (crop_cycle_id, village_id, kind, quantity_kg,
                              reported_for, is_current, source, captured_at,
                              captured_by, verification, confidence)
  values (p_cycle, v_village, p_kind, p_quantity_kg, p_reported_for, true,
          p_source, now(), auth.uid(), 'unverified', p_confidence)
  returning id into v_new;

  return v_new;
end $$;

grant execute on function app_supersede_harvest(uuid, harvest_kind, numeric, source_type, confidence_level, date) to authenticated;

-- app_verify is deliberately one-way. Reject stale or disputed rows instead of
-- silently overwriting their verification history.
create or replace function app_verify(p_table text, p_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_status verification_status;
begin
  if p_table not in ('person','household','farm','plot','crop_cycle','harvest_report') then
    raise exception 'not a verifiable table: %', p_table;
  end if;
  if not app_is_staff() then
    raise exception 'only field staff may verify records';
  end if;

  execute format(
    'select verification from %I where id = $1 and deleted_at is null for update',
    p_table
  ) into v_status using p_id;
  if not found then raise exception 'record not found or outside your villages'; end if;
  if v_status not in ('unverified', 'pending') then
    raise exception 'record is not awaiting verification';
  end if;

  execute format(
    'update %I set verification = %L, verified_by = %L, verified_at = now(), updated_at = now() where id = %L',
    p_table, 'verified', auth.uid(), p_id
  );
end $$;

grant execute on function app_verify(text, uuid) to authenticated;

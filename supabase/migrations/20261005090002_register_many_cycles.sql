-- Ruaha 360 · several crops at registration
--
-- A farmer grows more than one crop, often on the same plot. The schema has
-- always allowed several concurrent crop_cycle rows per plot (intercropping;
-- the reason planted area across cycles can exceed land area), but
-- app_register_farmer took a single `cycle`. It now takes `cycles`, a list,
-- each element carrying its own measure, window and expected `harvest`.
--
-- The single `cycle` + `harvest` payload is still accepted, so a draft typed
-- before this deploy submits unchanged. The result keeps `crop_cycle_id` and
-- `harvest_report_id` (the first of each) and adds the full id lists, plus
-- `village_id` so the client can file plot documents under it.
--
-- Same body otherwise, same owner (ruaha_observed_writer), SECURITY DEFINER.
-- Requested and approved on 5 Oct 2026.

create or replace function app_register_farmer(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
declare
  v_ref       uuid := (payload->>'client_ref')::uuid;
  v_village   uuid := (payload->>'village_id')::uuid;
  v_actor     uuid := public.app_actor_id();
  v_existing  jsonb;

  p           jsonb := payload->'person';
  hh          jsonb := payload->'household';
  fa          jsonb := payload->'farm';
  pl          jsonb := payload->'plot';
  cycles      jsonb := payload->'cycles';
  cy          jsonb;
  hv          jsonb;
  v_cycle_ids   uuid[] := '{}';
  v_harvest_ids uuid[] := '{}';

  v_phone     text;
  v_person    uuid;
  v_household uuid;
  v_farm      uuid;
  v_plot      uuid;
  v_cycle     uuid;
  v_harvest   uuid;
  v_measure   crop_measure;
begin
  if v_ref is null then
    raise exception 'client_ref is required so a retry cannot create a duplicate farmer';
  end if;

  -- idempotent replay
  select result into v_existing from registration_receipt where client_ref = v_ref;
  if v_existing is not null then
    return v_existing || jsonb_build_object('replayed', true);
  end if;

  if not app_is_staff() then
    raise exception 'only field staff may register a farmer';
  end if;

  if v_village is null then
    raise exception 'village_id is required';
  end if;

  -- The phone is the farmer's login name.
  if nullif(btrim(p->>'phone'), '') is null then
    raise exception 'a phone number is required so the farmer can sign in';
  end if;
  v_phone := app_normalize_phone(p->>'phone');

  -- A new farm is located by the officer's GPS read, never left blank.
  if coalesce(not (fa ? 'existing_farm_id'), true)
     and (nullif(fa->>'latitude', '') is null or nullif(fa->>'longitude', '') is null) then
    raise exception 'the farm location is required: capture the GPS position before saving';
  end if;

  -- ---- person -------------------------------------------------
  insert into person (village_id, given_name, family_name, phone,
                      source, captured_at, captured_by, verification, confidence)
  values (v_village, p->>'given_name', p->>'family_name', v_phone,
          'field_verified', now(), v_actor, 'unverified',
          nullif(p->>'confidence','')::confidence_level)
  returning id into v_person;

  -- ---- household ----------------------------------------------
  if hh ? 'existing_household_id' then
    v_household := (hh->>'existing_household_id')::uuid;
  else
    insert into household (village_id, label, source, captured_at, captured_by, verification)
    values (v_village, coalesce(nullif(hh->>'label',''), p->>'family_name' || ' household'),
            'field_verified', now(), v_actor, 'unverified')
    returning id into v_household;
  end if;

  insert into household_member (household_id, person_id, is_head)
  values (v_household, v_person, coalesce((hh->>'is_head')::boolean, true))
  on conflict do nothing;

  -- ---- farm ---------------------------------------------------
  if fa ? 'existing_farm_id' then
    v_farm := (fa->>'existing_farm_id')::uuid;
  else
    insert into farm (village_id, household_id, label, latitude, longitude,
                      source, captured_at, captured_by, verification, confidence)
    values (v_village, v_household, fa->>'label',
            nullif(fa->>'latitude','')::numeric, nullif(fa->>'longitude','')::numeric,
            'field_verified', now(), v_actor, 'unverified',
            nullif(fa->>'confidence','')::confidence_level)
    returning id into v_farm;
  end if;

  insert into farm_manager (farm_id, person_id, is_primary)
  values (v_farm, v_person, not exists (select 1 from farm_manager where farm_id = v_farm and is_primary))
  on conflict do nothing;

  -- ---- plot ---------------------------------------------------
  insert into plot (farm_id, village_id, label, area_ha, latitude, longitude,
                    source, captured_at, captured_by, verification, confidence)
  values (v_farm, v_village, pl->>'label', nullif(pl->>'area_ha','')::hectares,
          nullif(pl->>'latitude','')::numeric, nullif(pl->>'longitude','')::numeric,
          'field_verified', now(), v_actor, 'unverified',
          nullif(pl->>'confidence','')::confidence_level)
  returning id into v_plot;

  -- ---- crop cycles ------------------------------------------
  -- One plot carries several concurrent cycles (intercropping). A payload
  -- from an older client sends one `cycle` + `harvest`; it is the same as a
  -- one-element `cycles` array whose element carries its harvest.
  if cycles is null and payload->'cycle' ? 'crop_id' then
    cycles := jsonb_build_array(
      (payload->'cycle') || jsonb_build_object('harvest', payload->'harvest'));
  end if;
  if cycles is not null and jsonb_typeof(cycles) <> 'array' then
    raise exception 'cycles must be a list';
  end if;

  if (select count(*) <> count(distinct e->>'crop_id')
      from jsonb_array_elements(coalesce(cycles, '[]'::jsonb)) e) then
    raise exception 'each crop may be registered once per plot';
  end if;

  for cy in select value from jsonb_array_elements(coalesce(cycles, '[]'::jsonb)) loop
    select measured_by into v_measure from crop where id = (cy->>'crop_id')::uuid;
    if v_measure is null then
      raise exception 'unknown crop';
    end if;

    -- the measure must match how this crop is measured
    if v_measure = 'area'       and nullif(cy->>'area_ha','')    is null then
      raise exception 'this crop is measured by area: area_ha is required';
    elsif v_measure = 'tree_count'  and nullif(cy->>'tree_count','')  is null then
      raise exception 'this crop is measured by tree count: tree_count is required';
    elsif v_measure = 'unit_count'  and nullif(cy->>'unit_count','')  is null then
      raise exception 'this crop is measured by unit count: unit_count is required';
    end if;

    insert into crop_cycle (plot_id, village_id, crop_id, season_label,
                            area_ha, tree_count, unit_count,
                            planted_on, harvest_start, harvest_end, status,
                            source, captured_at, captured_by, verification, confidence)
    values (v_plot, v_village, (cy->>'crop_id')::uuid, nullif(cy->>'season_label',''),
            nullif(cy->>'area_ha','')::hectares,
            nullif(cy->>'tree_count','')::integer,
            nullif(cy->>'unit_count','')::integer,
            nullif(cy->>'planted_on','')::date,
            nullif(cy->>'harvest_start','')::date,
            nullif(cy->>'harvest_end','')::date,
            coalesce(nullif(cy->>'status','')::crop_cycle_status, 'growing'),
            'field_verified', now(), v_actor, 'unverified',
            nullif(cy->>'confidence','')::confidence_level)
    returning id into v_cycle;
    v_cycle_ids := v_cycle_ids || v_cycle;

    -- ---- expected harvest -------------------------------------
    hv := cy->'harvest';
    if hv is not null and jsonb_typeof(hv) = 'object' and nullif(hv->>'quantity_kg','') is not null then
      insert into harvest_report (crop_cycle_id, village_id, kind, quantity_kg,
                                  reported_for, is_current,
                                  source, captured_at, captured_by, verification, confidence)
      values (v_cycle, v_village, 'expected', (hv->>'quantity_kg')::numeric,
              nullif(hv->>'reported_for','')::date, true,
              'farmer_reported', now(), v_actor, 'unverified',
              nullif(hv->>'confidence','')::confidence_level)
      returning id into v_harvest;
      v_harvest_ids := v_harvest_ids || v_harvest;
    end if;
  end loop;

  v_existing := jsonb_build_object(
    'person_id', v_person, 'household_id', v_household, 'farm_id', v_farm,
    'plot_id', v_plot,
    -- the first of each, for clients written before several crops
    'crop_cycle_id', v_cycle_ids[1], 'harvest_report_id', v_harvest_ids[1],
    'crop_cycle_ids', to_jsonb(v_cycle_ids), 'harvest_report_ids', to_jsonb(v_harvest_ids),
    'village_id', v_village,
    'replayed', false
  );

  insert into registration_receipt (client_ref, created_by, result)
  values (v_ref, v_actor, v_existing);

  return v_existing;
end $$;

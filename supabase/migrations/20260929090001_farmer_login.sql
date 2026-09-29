-- Ruaha 360 · farmer logins
-- An officer registers a farmer, then issues an app login: the farmer's phone
-- number plus a temporary password, shown once. The farmer must choose their
-- own password at first sign-in. No email, no SMS, no third party.
--
-- DOCUMENTED EXCEPTION. app_farmer_login_issue and app_password_changed are
-- owned by postgres, not ruaha_observed_writer: the writer role has no access
-- to the auth schema by design, and these two must write auth.users. postgres
-- bypasses RLS, so every scope rule is checked explicitly inside them.

-- ── schema ───────────────────────────────────────────────
alter table app_user add column must_change_password boolean not null default false;

-- One login per person. The same person behind two logins would be two tries
-- at every survey.
create unique index app_user_person_unique on app_user (person_id) where person_id is not null;

-- Every temporary password ever issued, and by whom. Append-only; no client
-- access at all. Not audited through write_audit: that would copy the hash
-- into audit_log, and this table is already the audit record.
create table login_issue (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references app_user(id) on delete cascade,
  person_id           uuid not null references person(id) on delete restrict,
  issued_by           uuid not null references app_user(id),
  kind                text not null check (kind in ('initial', 'reset')),
  temp_password_hash  text not null,
  issued_at           timestamptz not null default now()
);
create index login_issue_user_idx on login_issue (user_id, issued_at desc);
create index login_issue_person_idx on login_issue (person_id, issued_at desc);
alter table login_issue enable row level security;
revoke all on login_issue from public, anon, authenticated;

create function login_issue_append_only() returns trigger
language plpgsql set search_path = pg_catalog, public, pg_temp as $$
begin
  if tg_op = 'DELETE' and current_setting('ruaha.cleanup', true) = 'on' then return old; end if;
  raise exception 'login history cannot be changed';
end $$;
create trigger login_issue_append_only before update or delete on login_issue
  for each row execute function login_issue_append_only();

-- ── phone numbers ────────────────────────────────────────
-- Tanzanian mobiles only, stored as +255 followed by nine digits. The phone
-- is the login name, so two spellings of one number must be one number.
create function app_normalize_phone(p_phone text) returns text
language plpgsql immutable set search_path = pg_catalog as $$
declare d text := regexp_replace(coalesce(p_phone, ''), '[\s().-]', '', 'g');
begin
  if d ~ '^\+255[0-9]{9}$' then d := substr(d, 5);
  elsif d ~ '^255[0-9]{9}$' then d := substr(d, 4);
  elsif d ~ '^0[0-9]{9}$' then d := substr(d, 2);
  end if;
  if d !~ '^[67][0-9]{8}$' then
    raise exception 'phone number must be a Tanzanian mobile number, for example +255 712 345 678';
  end if;
  return '+255' || d;
end $$;

-- ── registration: phone and farm location now required ───
-- Same body as the live definition (20260909090009 as rewritten by
-- 20260925090001), plus two requirements. The function stays owned by
-- ruaha_observed_writer; postgres is a member of that role, so it may replace it.
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
  cy          jsonb := payload->'cycle';
  hv          jsonb := payload->'harvest';

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

  -- ---- crop cycle ---------------------------------------------
  if cy is not null and cy ? 'crop_id' then
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

    -- ---- expected harvest -------------------------------------
    if hv is not null and nullif(hv->>'quantity_kg','') is not null then
      insert into harvest_report (crop_cycle_id, village_id, kind, quantity_kg,
                                  reported_for, is_current,
                                  source, captured_at, captured_by, verification, confidence)
      values (v_cycle, v_village, 'expected', (hv->>'quantity_kg')::numeric,
              nullif(hv->>'reported_for','')::date, true,
              'farmer_reported', now(), v_actor, 'unverified',
              nullif(hv->>'confidence','')::confidence_level)
      returning id into v_harvest;
    end if;
  end if;

  v_existing := jsonb_build_object(
    'person_id', v_person, 'household_id', v_household, 'farm_id', v_farm,
    'plot_id', v_plot, 'crop_cycle_id', v_cycle, 'harvest_report_id', v_harvest,
    'replayed', false
  );

  insert into registration_receipt (client_ref, created_by, result)
  values (v_ref, v_actor, v_existing);

  return v_existing;
end $$;

-- ── temporary passwords ──────────────────────────────────
-- 8 characters from a 32-symbol alphabet (Crockford base32, lower case):
-- 40 bits, typeable on a phone keypad, no i/l/o/u to misread. gen_random_uuid
-- is in pg_catalog; its bytes 0-5, 7, 9-11 carry no version or variant bits.
create function app_random_crockford(p_length int) returns text
language plpgsql volatile set search_path = pg_catalog as $$
declare
  alphabet constant text := '0123456789abcdefghjkmnpqrstvwxyz';
  positions constant int[] := array[0,1,2,3,4,5,7,9,10,11];
  b bytea := uuid_send(gen_random_uuid());
  out text := '';
  i int;
begin
  if p_length < 1 or p_length > array_length(positions, 1) then
    raise exception 'random length must be between 1 and %', array_length(positions, 1);
  end if;
  for i in 1..p_length loop
    out := out || substr(alphabet, (get_byte(b, positions[i]) % 32) + 1, 1);
  end loop;
  return out;
end $$;
revoke all on function app_random_crockford(int) from public, anon, authenticated;

-- The login email for a phone: never shown, never mailed. The farmer types
-- the phone; src/lib/phone.ts maps it to the same address before sign-in.
create function app_login_email_for_phone(p_phone text) returns text
language sql immutable set search_path = pg_catalog, public as $$
  select substr(app_normalize_phone(p_phone), 2) || '@farmers.ruaha360.test'
$$;

create function app_farmer_login_issue(p_person_id uuid) returns jsonb
language plpgsql security definer set search_path = pg_catalog, public, pg_temp as $$
declare
  v_actor    uuid := auth.uid();
  v_person   public.person;
  v_phone    text;
  v_email    text;
  v_user     uuid;
  v_kind     text;
  v_password text;
  v_hash     text;
  v_project  uuid;
begin
  if v_actor is null or not public.app_is_staff() then
    raise exception 'only field staff may issue a farmer login' using errcode = '42501';
  end if;

  select * into v_person from public.person where id = p_person_id and deleted_at is null;
  if v_person.id is null or v_person.village_id not in (select public.app_staff_villages()) then
    raise exception 'person not found or outside your villages';
  end if;
  if nullif(btrim(v_person.phone), '') is null then
    raise exception 'add a phone number before issuing a login';
  end if;

  v_phone := public.app_normalize_phone(v_person.phone);
  v_email := public.app_login_email_for_phone(v_phone);

  -- Two officers pressing the button at once must not create two logins.
  perform pg_advisory_xact_lock(hashtext('ruaha.login:' || p_person_id::text));

  select id into v_user from public.app_user where person_id = p_person_id;

  if v_user is not null and exists (
    select 1 from public.membership m
    where m.user_id = v_user and m.revoked_at is null and m.role <> 'farmer'
  ) then
    raise exception 'this person signs in as staff: their password cannot be reset here';
  end if;

  if exists (select 1 from auth.users u where lower(u.email) = v_email
             and (v_user is null or u.id <> v_user)) then
    raise exception 'this phone number already has an app login';
  end if;

  v_password := public.app_random_crockford(8);
  v_hash := extensions.crypt(v_password, extensions.gen_salt('bf'));

  if v_user is null then
    v_kind := 'initial';
    v_user := gen_random_uuid();

    -- Same row shape as seed_user (supabase/seed.sql): empty token strings,
    -- not NULL, or GoTrue fails to scan the row at sign-in.
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) values (
      '00000000-0000-0000-0000-000000000000', v_user, 'authenticated', 'authenticated',
      v_email, v_hash, now(), now(), now(),
      '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
      '', '', '', ''
    );
    insert into auth.identities (
      id, user_id, identity_data, provider, provider_id,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), v_user,
      jsonb_build_object('sub', v_user::text, 'email', v_email),
      'email', v_user::text, null, now(), now()
    );

    insert into public.app_user (id, person_id, display_name, locale, must_change_password)
    values (v_user, p_person_id, v_person.given_name || ' ' || v_person.family_name, 'sw', true);

    select project_id into v_project from public.village where id = v_person.village_id;
    insert into public.membership (user_id, role, project_id, village_id)
    values (v_user, 'farmer', v_project, v_person.village_id)
    on conflict do nothing;
  else
    v_kind := 'reset';
    update auth.users
       set encrypted_password = v_hash, email = v_email, updated_at = now()
     where id = v_user;
    update auth.identities
       set identity_data = jsonb_build_object('sub', v_user::text, 'email', v_email), updated_at = now()
     where user_id = v_user and provider = 'email';
    -- Whoever held the old password is signed out.
    delete from auth.sessions where user_id = v_user;
    update public.app_user set must_change_password = true where id = v_user;
  end if;

  insert into public.login_issue (user_id, person_id, issued_by, kind, temp_password_hash)
  values (v_user, p_person_id, v_actor, v_kind, v_hash);

  -- The only place the temporary password ever exists in plain text.
  return jsonb_build_object('phone', v_phone, 'temp_password', v_password, 'kind', v_kind);
end $$;
revoke all on function app_farmer_login_issue(uuid) from public, anon;
grant execute on function app_farmer_login_issue(uuid) to authenticated;

-- The client calls this after supabase.auth.updateUser({ password }). It
-- cannot be faked: while the stored hash is still the temporary one, the
-- password has not changed.
create function app_password_changed() returns void
language plpgsql security definer set search_path = pg_catalog, public, pg_temp as $$
declare
  v_actor   uuid := auth.uid();
  v_current text;
  v_temp    text;
begin
  if v_actor is null then
    raise exception 'sign in first' using errcode = '42501';
  end if;
  select encrypted_password into v_current from auth.users where id = v_actor;
  select temp_password_hash into v_temp from public.login_issue
   where user_id = v_actor order by issued_at desc limit 1;
  if v_temp is not null and v_current = v_temp then
    raise exception 'choose a new password first';
  end if;
  update public.app_user set must_change_password = false where id = v_actor;
end $$;
revoke all on function app_password_changed() from public, anon;
grant execute on function app_password_changed() to authenticated;

-- Readable by the writer role, which has no grant on app_user.
create function app_must_change_password() returns boolean
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select coalesce((select must_change_password from public.app_user where id = auth.uid()), false)
$$;
revoke all on function app_must_change_password() from public, anon;
grant execute on function app_must_change_password() to authenticated, ruaha_observed_writer;

-- Officer view of a person's login: whether one exists, and who issued or
-- reset it. Never the password.
create function app_person_login_history(p_person_id uuid)
returns table (issued_at timestamptz, kind text, issued_by_name text, must_change_password boolean)
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select li.issued_at, li.kind, iu.display_name, u.must_change_password
  from public.person p
  join public.app_user u on u.person_id = p.id
  join public.login_issue li on li.user_id = u.id
  join public.app_user iu on iu.id = li.issued_by
  where p.id = p_person_id and p.deleted_at is null
    and p.village_id in (select public.app_staff_villages())
  order by li.issued_at desc
$$;
revoke all on function app_person_login_history(uuid) from public, anon;
grant execute on function app_person_login_history(uuid) to authenticated;

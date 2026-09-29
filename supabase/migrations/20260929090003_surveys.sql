-- Ruaha 360 · surveys and cash-incentive vouchers
-- Admin authors a survey and publishes it. A farmer answers once per
-- household and receives a single-use voucher, shown as a QR code. At the
-- office a staff member scans it and marks it redeemed. Every step leaves a
-- named record.
--
-- The rules that stop payout farming all live here, not in the client:
--   one response per household per survey (unique constraint)
--   the respondent belongs to exactly one household
--   the household was verified by someone other than its registrar, and
--     existed before the survey went live
--   nobody answers on a temporary password
--   whoever registered or verified a household cannot redeem its vouchers
--   a random share of vouchers is held for ops/admin to redeem in person
--   the redeemer records which ID document they checked (type only)
--   voucher codes are readable only by the household that owns them
--
-- An incentive is a fixed cash amount per household per survey. It is not a
-- wage, a wallet balance or a payment instrument.

-- ── enums ────────────────────────────────────────────────
create type survey_status        as enum ('draft', 'live', 'closed');
create type survey_question_kind as enum ('single_choice', 'multi_choice', 'number', 'text', 'yes_no');
create type voucher_status       as enum ('issued', 'redeemed', 'void');   -- expired is derived from expires_at
create type id_document_type     as enum ('nida', 'voter', 'driving_licence', 'village_letter');
create type voucher_event_kind   as enum ('issued', 'scanned', 'refused', 'redeemed', 'voided');

-- ── survey (config: authored, no provenance) ─────────────
-- village_id NULL -> every village in the project, as in membership.
create table survey (
  id              uuid primary key default gen_random_uuid(),
  project_id      uuid not null references project(id) on delete restrict,
  village_id      uuid,
  title_en        text not null check (btrim(title_en) <> ''),
  title_sw        text,
  description_en  text,
  description_sw  text,
  reward_amount   numeric(14,2) not null check (reward_amount > 0),
  currency        char(3) not null default 'TZS',
  max_households  integer check (max_households > 0),
  audit_rate      numeric(3,2) not null default 0.15 check (audit_rate between 0 and 1),
  closes_at       timestamptz,
  status          survey_status not null default 'draft',
  published_at    timestamptz,
  published_by    uuid references app_user(id),
  closed_at       timestamptz,
  created_by      uuid references app_user(id),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint survey_village_in_project
    foreign key (village_id, project_id) references village (id, project_id)
);
create index survey_project_idx on survey (project_id, status);

create table survey_question (
  id          uuid primary key default gen_random_uuid(),
  survey_id   uuid not null references survey(id) on delete cascade,
  position    integer not null check (position > 0),
  kind        survey_question_kind not null,
  prompt_en   text not null check (btrim(prompt_en) <> ''),
  prompt_sw   text,
  required    boolean not null default true,
  -- [{ "value": "...", "label_en": "...", "label_sw": "..." }], choice kinds only
  options     jsonb not null default '[]'::jsonb check (jsonb_typeof(options) = 'array'),
  deleted_at  timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index survey_question_survey_idx on survey_question (survey_id, position) where deleted_at is null;

-- ── survey_response (observed: full provenance block) ────
create table survey_response (
  id            uuid primary key default gen_random_uuid(),
  survey_id     uuid not null references survey(id) on delete restrict,
  household_id  uuid not null references household(id) on delete restrict,
  person_id     uuid not null references person(id) on delete restrict,
  village_id    uuid not null references village(id) on delete restrict,
  client_ref    uuid not null unique,
  submitted_at  timestamptz not null default now(),

  source        source_type         not null,
  captured_at   timestamptz         not null default now(),
  captured_by   uuid references app_user(id),
  verification  verification_status not null default 'unverified',
  verified_by   uuid references app_user(id),
  verified_at   timestamptz,
  confidence    confidence_level,
  evidence_ref  text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz,

  constraint survey_response_one_per_household unique (survey_id, household_id)
);
create index survey_response_village_idx on survey_response (village_id);

create table survey_answer (
  id           uuid primary key default gen_random_uuid(),
  response_id  uuid not null references survey_response(id) on delete cascade,
  question_id  uuid not null references survey_question(id) on delete restrict,
  value        jsonb not null,
  created_at   timestamptz not null default now(),
  constraint survey_answer_one_per_question unique (response_id, question_id)
);

-- ── survey_voucher ───────────────────────────────────────
-- code: 10 Crockford base32 symbols (50 bits). Never readable by staff.
create table survey_voucher (
  id              uuid primary key default gen_random_uuid(),
  response_id     uuid not null unique references survey_response(id) on delete restrict,
  survey_id       uuid not null references survey(id) on delete restrict,
  household_id    uuid not null references household(id) on delete restrict,
  village_id      uuid not null references village(id) on delete restrict,
  code            text not null unique check (code ~ '^[0-9A-HJKMNP-TV-Z]{10}$'),
  amount          numeric(14,2) not null check (amount > 0),
  currency        char(3) not null,
  status          voucher_status not null default 'issued',
  audit_required  boolean not null default false,
  issued_at       timestamptz not null default now(),
  expires_at      timestamptz not null,
  redeemed_by     uuid references app_user(id),
  redeemed_at     timestamptz,
  id_type_seen    id_document_type,
  voided_by       uuid references app_user(id),
  voided_at       timestamptz,
  void_reason     text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint survey_voucher_redeemed_complete check (
    status <> 'redeemed' or (redeemed_by is not null and redeemed_at is not null and id_type_seen is not null)),
  constraint survey_voucher_void_complete check (
    status <> 'void' or (voided_by is not null and voided_at is not null and nullif(btrim(void_reason), '') is not null))
);
create index survey_voucher_household_idx on survey_voucher (household_id);
create index survey_voucher_village_idx on survey_voucher (village_id, status);
create index survey_voucher_survey_idx on survey_voucher (survey_id);
create index survey_voucher_redeemed_idx on survey_voucher (redeemed_at) where status = 'redeemed';

-- ── voucher_event: the append-only audit trail ───────────
-- actor_name and actor_role are snapshots: renaming an account later never
-- rewrites who did what.
create table voucher_event (
  id           uuid primary key default gen_random_uuid(),
  voucher_id   uuid not null references survey_voucher(id) on delete restrict,
  kind         voucher_event_kind not null,
  actor_id     uuid references app_user(id),
  actor_name   text not null,
  actor_role   text not null,
  occurred_at  timestamptz not null default clock_timestamp(),
  detail       jsonb not null default '{}'::jsonb
);
create index voucher_event_voucher_idx on voucher_event (voucher_id, occurred_at);

create function voucher_event_append_only() returns trigger
language plpgsql set search_path = pg_catalog, public, pg_temp as $$
begin
  if tg_op = 'DELETE' and current_setting('ruaha.cleanup', true) = 'on' then return old; end if;
  raise exception 'voucher events cannot be changed';
end $$;
create trigger voucher_event_append_only before update or delete on voucher_event
  for each row execute function voucher_event_append_only();

-- ── housekeeping triggers ────────────────────────────────
create trigger survey_updated_at          before update on survey          for each row execute function set_updated_at();
create trigger survey_question_updated_at before update on survey_question for each row execute function set_updated_at();
create trigger survey_response_updated_at before update on survey_response for each row execute function set_updated_at();
create trigger survey_voucher_updated_at  before update on survey_voucher  for each row execute function set_updated_at();

create trigger survey_audit          after insert or update or delete on survey          for each row execute function write_audit();
create trigger survey_question_audit after insert or update or delete on survey_question for each row execute function write_audit();
create trigger survey_response_audit after insert or update or delete on survey_response for each row execute function write_audit();
create trigger survey_answer_audit   after insert or update or delete on survey_answer   for each row execute function write_audit();
create trigger survey_voucher_audit  after insert or update or delete on survey_voucher  for each row execute function write_audit();

-- ── guards ───────────────────────────────────────────────
-- Admin-only authoring, the status machine, and content frozen once live.
-- auth.uid() IS NULL is the privileged path (seed impersonates admin anyway;
-- rls_test fixtures run as postgres).
create function survey_guard() returns trigger
language plpgsql set search_path = pg_catalog, public, pg_temp as $$
begin
  if auth.uid() is not null and not app_admins_project(new.project_id) then
    raise exception 'only an admin may author surveys' using errcode = '42501';
  end if;

  if tg_op = 'INSERT' then
    if new.status <> 'draft' then raise exception 'a survey must start as a draft'; end if;
    new.created_by := auth.uid();
    new.created_at := now();
    new.published_at := null; new.published_by := null; new.closed_at := null;
    return new;
  end if;

  if new.project_id is distinct from old.project_id then
    raise exception 'a survey cannot move to another project';
  end if;
  if old.status <> 'draft' and
     (new.village_id, new.title_en, new.title_sw, new.description_en, new.description_sw,
      new.reward_amount, new.currency, new.max_households, new.audit_rate, new.closes_at)
     is distinct from
     (old.village_id, old.title_en, old.title_sw, old.description_en, old.description_sw,
      old.reward_amount, old.currency, old.max_households, old.audit_rate, old.closes_at) then
    raise exception 'a live survey cannot be edited';
  end if;
  new.created_by := old.created_by;
  new.created_at := old.created_at;

  if new.status is distinct from old.status then
    if not ((old.status = 'draft' and new.status = 'live')
         or (old.status = 'live' and new.status = 'closed')) then
      raise exception 'illegal survey transition % -> %', old.status, new.status;
    end if;
    if new.status = 'live' then
      if not exists (select 1 from survey_question q where q.survey_id = new.id and q.deleted_at is null) then
        raise exception 'a survey needs at least one question before it goes live';
      end if;
      if exists (select 1 from survey_question q where q.survey_id = new.id and q.deleted_at is null
                 and q.kind in ('single_choice', 'multi_choice') and jsonb_array_length(q.options) < 2) then
        raise exception 'every choice question needs at least two options';
      end if;
      if exists (select 1 from survey_question q, jsonb_array_elements(q.options) o
                 where q.survey_id = new.id and q.deleted_at is null
                   and (nullif(btrim(o->>'value'), '') is null or nullif(btrim(o->>'label_en'), '') is null)) then
        raise exception 'every option needs a value and an English label';
      end if;
      if new.closes_at is not null and new.closes_at <= now() then
        raise exception 'the closing date must be in the future';
      end if;
      -- clock_timestamp, not now(): the seed creates households and publishes
      -- surveys in one transaction, where now() never moves.
      new.published_at := clock_timestamp();
      new.published_by := auth.uid();
      new.closed_at := null;
    else
      new.closed_at := clock_timestamp();
      new.published_at := old.published_at;
      new.published_by := old.published_by;
    end if;
  else
    new.published_at := old.published_at;
    new.published_by := old.published_by;
    new.closed_at := old.closed_at;
  end if;
  return new;
end $$;
create trigger survey_guard_trg before insert or update on survey
  for each row execute function survey_guard();

create function survey_question_guard() returns trigger
language plpgsql set search_path = pg_catalog, public, pg_temp as $$
declare
  v_status  survey_status;
  v_project uuid;
begin
  if tg_op = 'UPDATE' and new.survey_id is distinct from old.survey_id then
    raise exception 'a question cannot move to another survey';
  end if;
  select status, project_id into v_status, v_project from survey where id = new.survey_id;
  if auth.uid() is not null and (v_project is null or not app_admins_project(v_project)) then
    raise exception 'only an admin may author surveys' using errcode = '42501';
  end if;
  if v_status is distinct from 'draft' then
    raise exception 'questions can only change while the survey is a draft';
  end if;
  return new;
end $$;
create trigger survey_question_guard_trg before insert or update on survey_question
  for each row execute function survey_question_guard();

-- ── client access ────────────────────────────────────────
alter table survey          enable row level security;
alter table survey_question enable row level security;
alter table survey_response enable row level security;
alter table survey_answer   enable row level security;
alter table survey_voucher  enable row level security;
alter table voucher_event   enable row level security;

revoke all on survey, survey_question, survey_response, survey_answer, survey_voucher, voucher_event
  from public, anon, authenticated;

grant select on survey, survey_question, survey_response, survey_answer to authenticated;
grant insert (id, project_id, village_id, title_en, title_sw, description_en, description_sw,
              reward_amount, currency, max_households, audit_rate, closes_at)
  on survey to authenticated;
grant update (village_id, title_en, title_sw, description_en, description_sw,
              reward_amount, currency, max_households, audit_rate, closes_at, status)
  on survey to authenticated;
grant insert (id, survey_id, position, kind, prompt_en, prompt_sw, required, options)
  on survey_question to authenticated;
grant update (position, kind, prompt_en, prompt_sw, required, options, deleted_at)
  on survey_question to authenticated;
-- Everything except code and audit_required. The household reads its code
-- through app_voucher_code(); the audit flag is revealed only at scan.
grant select (id, response_id, survey_id, household_id, village_id, amount, currency, status,
              issued_at, expires_at, redeemed_by, redeemed_at, id_type_seen,
              voided_by, voided_at, void_reason, created_at, updated_at)
  on survey_voucher to authenticated;
-- voucher_event: no client access at all. Read through app_voucher_timeline.

create policy survey_read on survey for select to authenticated using (
  project_id in (select app_projects())
  and (village_id is null or village_id in (select app_villages()))
  and (status <> 'draft' or app_manages_project(project_id)));
create policy survey_insert on survey for insert to authenticated
  with check (app_admins_project(project_id));
create policy survey_update on survey for update to authenticated
  using (app_admins_project(project_id)) with check (app_admins_project(project_id));

create policy survey_question_read on survey_question for select to authenticated
  using (survey_id in (select id from survey));
create policy survey_question_insert on survey_question for insert to authenticated
  with check (exists (select 1 from survey s where s.id = survey_id and app_admins_project(s.project_id)));
create policy survey_question_update on survey_question for update to authenticated
  using (exists (select 1 from survey s where s.id = survey_id and app_admins_project(s.project_id)))
  with check (exists (select 1 from survey s where s.id = survey_id and app_admins_project(s.project_id)));

create policy survey_response_read on survey_response for select to authenticated
  using (household_id in (select app_households()) or village_id in (select app_staff_villages()));
create policy survey_answer_read on survey_answer for select to authenticated
  using (response_id in (select id from survey_response));
create policy survey_voucher_read on survey_voucher for select to authenticated
  using (household_id in (select app_households()) or village_id in (select app_staff_villages()));

-- ── writer access (RPCs run as ruaha_observed_writer) ────
grant select on survey, survey_question to ruaha_observed_writer;
grant select, insert on survey_response, survey_answer to ruaha_observed_writer;
grant select, insert, update on survey_voucher to ruaha_observed_writer;
grant select, insert on voucher_event to ruaha_observed_writer;

create policy rpc_survey_read on survey for select to ruaha_observed_writer
  using (project_id in (select app_projects()));
create policy rpc_question_read on survey_question for select to ruaha_observed_writer
  using (survey_id in (select id from survey));
create policy rpc_response_read on survey_response for select to ruaha_observed_writer
  using (household_id in (select app_households()) or village_id in (select app_staff_villages()));
create policy rpc_response_insert on survey_response for insert to ruaha_observed_writer
  with check (household_id in (select app_households())
              and person_id = app_person_id() and captured_by = app_actor_id());
create policy rpc_answer_read on survey_answer for select to ruaha_observed_writer
  using (response_id in (select id from survey_response));
create policy rpc_answer_insert on survey_answer for insert to ruaha_observed_writer
  with check (response_id in (select id from survey_response));
create policy rpc_voucher_read on survey_voucher for select to ruaha_observed_writer
  using (household_id in (select app_households()) or village_id in (select app_staff_villages()));
create policy rpc_voucher_insert on survey_voucher for insert to ruaha_observed_writer
  with check (household_id in (select app_households()));
create policy rpc_voucher_update on survey_voucher for update to ruaha_observed_writer
  using (village_id in (select app_staff_villages())) with check (village_id in (select app_staff_villages()));
create policy rpc_event_read on voucher_event for select to ruaha_observed_writer
  using (voucher_id in (select id from survey_voucher));
create policy rpc_event_insert on voucher_event for insert to ruaha_observed_writer
  with check (actor_id = app_actor_id());
-- The farmer's own household, which the submit RPC checks for eligibility.
create policy rpc_self_household on household for select to ruaha_observed_writer
  using (id in (select app_households()));

grant execute on function app_manage_village(uuid) to ruaha_observed_writer;
grant execute on function app_random_crockford(int) to ruaha_observed_writer;

-- ── small helpers (postgres-owned, read-only) ────────────
create function app_voucher_normalize(p_code text) returns text
language sql immutable set search_path = pg_catalog as $$
  select translate(
    regexp_replace(upper(regexp_replace(coalesce(p_code, ''), '^\s*R360V:', '', 'i')), '[^0-9A-Z]', '', 'g'),
    'OIL', '011')
$$;

create function app_actor_display_name() returns text
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select coalesce((select display_name from public.app_user where id = auth.uid()), 'unknown account')
$$;

create function app_user_role_label(p_user uuid) returns text
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select coalesce((
    select m.role::text from public.membership m
    where m.user_id = p_user and m.revoked_at is null
    order by case m.role when 'admin' then 1 when 'ops' then 2 when 'field_officer' then 3 else 4 end
    limit 1), 'unknown')
$$;

create function app_actor_role() returns text
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select public.app_user_role_label(auth.uid())
$$;

-- Unscoped on purpose, and executable ONLY by the writer role: the lookup RPC
-- must be able to log a refused scan against a voucher the officer cannot see.
create function app_voucher_resolve(p_code text) returns uuid
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select id from public.survey_voucher where code = public.app_voucher_normalize(p_code)
$$;

-- The survey budget counts every household, not just the caller's.
create function app_survey_household_count(p_survey uuid) returns bigint
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select count(*) from public.survey_response where survey_id = p_survey and deleted_at is null
$$;

revoke all on function app_actor_display_name(), app_user_role_label(uuid), app_actor_role(),
  app_voucher_resolve(text), app_survey_household_count(uuid) from public, anon, authenticated;
grant execute on function app_actor_display_name(), app_actor_role(), app_voucher_resolve(text),
  app_survey_household_count(uuid) to ruaha_observed_writer;

-- Provenance names now also resolve for survey authors and for whoever
-- registered or verified a household the caller can see.
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
    )
  )
$$;

-- ── eligibility (writer-owned, shared by list and submit) ─
-- One function answers "may this caller's household answer this survey?", so
-- the farmer list and the submit can never disagree.
create function survey_block_reason(p_survey_id uuid) returns text
language plpgsql stable security definer set search_path = pg_catalog, public, pg_temp as $$
declare
  s           public.survey;
  h           public.household;
  v_person    uuid := public.app_person_id();
  v_house_ids uuid[];
begin
  select * into s from public.survey where id = p_survey_id;
  if s.id is null or s.status = 'draft' then return 'survey not found'; end if;
  if s.status <> 'live' or (s.closes_at is not null and s.closes_at <= now()) then
    return 'this survey is closed';
  end if;
  if v_person is null then return 'your account is not linked to a registered farmer'; end if;
  if public.app_must_change_password() then return 'set your own password before answering surveys'; end if;

  select array_agg(hm.household_id) into v_house_ids
    from public.household_member hm
    join public.household hh on hh.id = hm.household_id and hh.deleted_at is null
   where hm.person_id = v_person;
  if coalesce(array_length(v_house_ids, 1), 0) <> 1 then
    return 'your household record needs checking by an officer';
  end if;

  select * into h from public.household where id = v_house_ids[1];
  if s.village_id is not null and s.village_id <> h.village_id then
    return 'this survey is not open in your village';
  end if;
  if exists (select 1 from public.survey_response r where r.survey_id = s.id and r.household_id = h.id) then
    return 'your household has already answered this survey';
  end if;
  if h.verification <> 'verified' then return 'your household has not been verified yet'; end if;
  if h.verified_by is null or h.verified_by = h.captured_by then
    return 'your household must be verified by a second staff member';
  end if;
  if h.created_at >= s.published_at then
    return 'this survey opened before your household was registered';
  end if;
  if s.max_households is not null and public.app_survey_household_count(s.id) >= s.max_households then
    return 'this survey has reached its limit';
  end if;
  return null;
end $$;

create function app_survey_eligibility()
returns table (survey_id uuid, eligible boolean, reason text, response_id uuid, voucher_id uuid)
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select s.id,
         r.id is null and b.reason is null,
         case when r.id is null then b.reason end,
         r.id,
         v.id
  from public.survey s
  left join public.survey_response r
    on r.survey_id = s.id and r.household_id in (select public.app_households())
  left join public.survey_voucher v on v.response_id = r.id
  cross join lateral (select public.survey_block_reason(s.id) as reason) b
  where s.status in ('live', 'closed')
    and (s.village_id is null or s.village_id in (select public.app_villages()))
$$;

-- ── submit (writer-owned) ────────────────────────────────
create function app_survey_submit(p_survey_id uuid, p_answers jsonb, p_client_ref uuid) returns jsonb
language plpgsql security definer set search_path = pg_catalog, public, pg_temp as $$
declare
  v_actor     uuid := public.app_actor_id();
  v_person    uuid := public.app_person_id();
  v_reason    text;
  s           public.survey;
  q           public.survey_question;
  v_existing  public.survey_response;
  v_voucher   public.survey_voucher;
  v_household uuid;
  v_village   uuid;
  v_response  uuid;
  v_value     jsonb;
  v_clean     jsonb := '{}'::jsonb;
  v_code      text;
begin
  if v_actor is null then raise exception 'sign in first' using errcode = '42501'; end if;
  if p_client_ref is null then
    raise exception 'client_ref is required so a retry cannot answer twice';
  end if;
  if p_answers is null or jsonb_typeof(p_answers) <> 'object' then
    raise exception 'answers must be an object keyed by question';
  end if;

  -- idempotent replay: a retry after a timeout returns the same voucher
  select * into v_existing from public.survey_response where client_ref = p_client_ref;
  if v_existing.id is not null then
    if v_existing.captured_by is distinct from v_actor then
      raise exception 'this answer reference belongs to someone else';
    end if;
    select * into v_voucher from public.survey_voucher where response_id = v_existing.id;
    return jsonb_build_object(
      'response_id', v_existing.id, 'voucher_id', v_voucher.id, 'code', v_voucher.code,
      'amount', v_voucher.amount, 'currency', v_voucher.currency,
      'expires_at', v_voucher.expires_at, 'replayed', true);
  end if;

  -- one submit per survey at a time, so the budget count cannot race
  perform pg_advisory_xact_lock(hashtext('ruaha.survey:' || p_survey_id::text));

  v_reason := public.survey_block_reason(p_survey_id);
  if v_reason is not null then raise exception '%', v_reason; end if;

  select * into s from public.survey where id = p_survey_id;
  select hm.household_id, hh.village_id into v_household, v_village
    from public.household_member hm
    join public.household hh on hh.id = hm.household_id and hh.deleted_at is null
   where hm.person_id = v_person;

  if exists (select 1 from jsonb_object_keys(p_answers) k
             where k not in (select q2.id::text from public.survey_question q2
                             where q2.survey_id = s.id and q2.deleted_at is null)) then
    raise exception 'an answer does not match any question in this survey';
  end if;

  for q in select * from public.survey_question
            where survey_id = s.id and deleted_at is null order by position loop
    v_value := p_answers -> q.id::text;
    if v_value is null or v_value = 'null'::jsonb
       or (jsonb_typeof(v_value) = 'string' and btrim(v_value #>> '{}') = '')
       or (jsonb_typeof(v_value) = 'array' and jsonb_array_length(v_value) = 0) then
      if q.required then raise exception 'question % is required', q.position; end if;
      continue;
    end if;

    if q.kind = 'single_choice' then
      if jsonb_typeof(v_value) <> 'string' or not exists (
           select 1 from jsonb_array_elements(q.options) o where o->>'value' = v_value #>> '{}') then
        raise exception 'question %: choose one of the listed options', q.position;
      end if;
    elsif q.kind = 'multi_choice' then
      if jsonb_typeof(v_value) <> 'array' or exists (
           select 1 from jsonb_array_elements(v_value) a
            where jsonb_typeof(a) <> 'string' or not exists (
              select 1 from jsonb_array_elements(q.options) o where o->>'value' = a #>> '{}')) then
        raise exception 'question %: choose from the listed options', q.position;
      end if;
    elsif q.kind = 'number' then
      if jsonb_typeof(v_value) = 'string' then
        begin
          v_value := to_jsonb((btrim(v_value #>> '{}'))::numeric);
        exception when others then
          raise exception 'question %: enter a number', q.position;
        end;
      elsif jsonb_typeof(v_value) <> 'number' then
        raise exception 'question %: enter a number', q.position;
      end if;
    elsif q.kind = 'text' then
      if jsonb_typeof(v_value) <> 'string' or length(v_value #>> '{}') > 2000 then
        raise exception 'question %: answer in at most 2000 characters', q.position;
      end if;
      v_value := to_jsonb(btrim(v_value #>> '{}'));
    elsif q.kind = 'yes_no' then
      if jsonb_typeof(v_value) <> 'boolean' then
        raise exception 'question %: answer yes or no', q.position;
      end if;
    end if;
    v_clean := v_clean || jsonb_build_object(q.id::text, v_value);
  end loop;

  insert into public.survey_response (survey_id, household_id, person_id, village_id, client_ref,
                                      source, captured_at, captured_by, verification)
  values (s.id, v_household, v_person, v_village, p_client_ref,
          'farmer_reported', now(), v_actor, 'unverified')
  returning id into v_response;

  insert into public.survey_answer (response_id, question_id, value)
  select v_response, e.key::uuid, e.value from jsonb_each(v_clean) e;

  loop
    v_code := upper(public.app_random_crockford(10));
    exit when public.app_voucher_resolve(v_code) is null;
  end loop;

  insert into public.survey_voucher (response_id, survey_id, household_id, village_id, code,
                                     amount, currency, audit_required, expires_at)
  values (v_response, s.id, v_household, v_village, v_code,
          s.reward_amount, s.currency, random() < s.audit_rate, now() + interval '30 days')
  returning * into v_voucher;

  insert into public.voucher_event (voucher_id, kind, actor_id, actor_name, actor_role, detail)
  values (v_voucher.id, 'issued', v_actor, public.app_actor_display_name(), public.app_actor_role(),
          jsonb_build_object('audit_required', v_voucher.audit_required,
                             'amount', v_voucher.amount, 'currency', v_voucher.currency));

  return jsonb_build_object(
    'response_id', v_response, 'voucher_id', v_voucher.id, 'code', v_voucher.code,
    'amount', v_voucher.amount, 'currency', v_voucher.currency,
    'expires_at', v_voucher.expires_at, 'replayed', false);
end $$;

-- ── the household's own code (writer-owned) ──────────────
-- NULL for anyone outside the household, staff included.
create function app_voucher_code(p_voucher_id uuid) returns text
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select v.code from public.survey_voucher v
  where v.id = p_voucher_id and v.household_id in (select public.app_households())
$$;

-- ── redeem rules (writer-owned, shared by lookup and redeem) ─
create function voucher_block_reason(p_voucher public.survey_voucher) returns text
language plpgsql stable security definer set search_path = pg_catalog, public, pg_temp as $$
declare
  h          public.household;
  v_actor    uuid := public.app_actor_id();
  v_redeemer text;
begin
  if p_voucher.status = 'redeemed' then
    select actor_name into v_redeemer from public.voucher_event
     where voucher_id = p_voucher.id and kind = 'redeemed' order by occurred_at desc limit 1;
    return format('voucher already redeemed on %s by %s',
      to_char(p_voucher.redeemed_at at time zone 'Africa/Dar_es_Salaam', 'DD Mon YYYY HH24:MI'),
      coalesce(v_redeemer, 'another staff member'));
  end if;
  if p_voucher.status = 'void' then
    return 'this voucher was voided: ' || p_voucher.void_reason;
  end if;
  if p_voucher.expires_at <= now() then
    return format('this voucher expired on %s',
      to_char(p_voucher.expires_at at time zone 'Africa/Dar_es_Salaam', 'DD Mon YYYY'));
  end if;

  select * into h from public.household where id = p_voucher.household_id;
  if h.captured_by = v_actor then
    return 'you registered this household, so another staff member must redeem this voucher';
  end if;
  if h.verified_by = v_actor then
    return 'you verified this household, so another staff member must redeem this voucher';
  end if;
  if exists (select 1 from public.household_member hm
             where hm.household_id = h.id and hm.person_id = public.app_person_id()) then
    return 'you cannot redeem a voucher for your own household';
  end if;
  if p_voucher.audit_required and not public.app_manage_village(p_voucher.village_id) then
    return 'this voucher is held for an audit: ops or admin must redeem it in person';
  end if;
  return null;
end $$;

-- ── lookup (writer-owned): every scan leaves an event ────
create function app_voucher_lookup(p_code text) returns jsonb
language plpgsql volatile security definer set search_path = pg_catalog, public, pg_temp as $$
declare
  v_actor  uuid := public.app_actor_id();
  v_id     uuid;
  v        public.survey_voucher;
  h        public.household;
  s        public.survey;
  v_block  text;
  v_result jsonb;
begin
  if v_actor is null or not public.app_is_staff() then
    raise exception 'only staff may look up vouchers' using errcode = '42501';
  end if;

  v_id := public.app_voucher_resolve(p_code);
  if v_id is null then return jsonb_build_object('found', false); end if;

  select * into v from public.survey_voucher where id = v_id;
  if v.id is null then
    -- A real code, outside this officer's villages: same answer as an unknown
    -- code, but ops can see the attempt.
    insert into public.voucher_event (voucher_id, kind, actor_id, actor_name, actor_role, detail)
    values (v_id, 'refused', v_actor, public.app_actor_display_name(), public.app_actor_role(),
            jsonb_build_object('reason', 'outside your villages'));
    return jsonb_build_object('found', false);
  end if;

  select * into h from public.household where id = v.household_id;
  select * into s from public.survey where id = v.survey_id;
  v_block := public.voucher_block_reason(v);

  v_result := jsonb_build_object(
    'found', true,
    'voucher_id', v.id,
    'status', v.status,
    'expired', v.status = 'issued' and v.expires_at <= now(),
    'amount', v.amount,
    'currency', v.currency,
    'issued_at', v.issued_at,
    'expires_at', v.expires_at,
    'redeemed_at', v.redeemed_at,
    'redeemed_by_name', (select e.actor_name from public.voucher_event e
                          where e.voucher_id = v.id and e.kind = 'redeemed'
                          order by e.occurred_at desc limit 1),
    'void_reason', v.void_reason,
    'survey_title_en', s.title_en,
    'survey_title_sw', s.title_sw,
    'household_label', h.label,
    'head_name', (select p.given_name || ' ' || p.family_name
                    from public.household_member hm join public.person p on p.id = hm.person_id
                   where hm.household_id = h.id and hm.is_head limit 1),
    'respondent_name', (select p.given_name || ' ' || p.family_name
                          from public.survey_response r join public.person p on p.id = r.person_id
                         where r.id = v.response_id),
    'needs_ops', v.audit_required,
    'can_redeem', v_block is null,
    'blocked_reason', v_block);

  insert into public.voucher_event (voucher_id, kind, actor_id, actor_name, actor_role, detail)
  values (v.id, 'scanned', v_actor, public.app_actor_display_name(), public.app_actor_role(),
          jsonb_build_object('status_seen', v.status, 'can_redeem', v_block is null,
                             'blocked_reason', v_block, 'needs_ops', v.audit_required));
  return v_result;
end $$;

-- ── redeem (writer-owned) ────────────────────────────────
create function app_voucher_redeem(p_code text, p_id_type id_document_type, p_name_confirmed boolean)
returns jsonb
language plpgsql security definer set search_path = pg_catalog, public, pg_temp as $$
declare
  v_actor uuid := public.app_actor_id();
  v_id    uuid;
  v       public.survey_voucher;
  v_block text;
  v_name  text := public.app_actor_display_name();
begin
  if v_actor is null or not public.app_is_staff() then
    raise exception 'only staff may redeem vouchers' using errcode = '42501';
  end if;
  v_id := public.app_voucher_resolve(p_code);
  if v_id is not null then
    select * into v from public.survey_voucher where id = v_id for update;
  end if;
  if v.id is null then raise exception 'voucher not found'; end if;

  -- A retry after a dropped connection is not a double redeem.
  if v.status = 'redeemed' and v.redeemed_by = v_actor then
    return jsonb_build_object('voucher_id', v.id, 'status', v.status, 'redeemed_at', v.redeemed_at,
      'redeemed_by_name', v_name, 'amount', v.amount, 'currency', v.currency, 'replayed', true);
  end if;

  v_block := public.voucher_block_reason(v);
  if v_block is not null then raise exception '%', v_block; end if;
  if p_id_type is null then
    raise exception 'record which ID document you checked';
  end if;
  if p_name_confirmed is not true then
    raise exception 'confirm that the name on the ID matches the household';
  end if;

  update public.survey_voucher
     set status = 'redeemed', redeemed_by = v_actor, redeemed_at = now(), id_type_seen = p_id_type
   where id = v.id
  returning * into v;

  insert into public.voucher_event (voucher_id, kind, actor_id, actor_name, actor_role, detail)
  values (v.id, 'redeemed', v_actor, v_name, public.app_actor_role(),
          jsonb_build_object('id_type_seen', p_id_type, 'audit_required', v.audit_required,
                             'amount', v.amount, 'currency', v.currency));

  return jsonb_build_object('voucher_id', v.id, 'status', v.status, 'redeemed_at', v.redeemed_at,
    'redeemed_by_name', v_name, 'amount', v.amount, 'currency', v.currency, 'replayed', false);
end $$;

-- ── void (writer-owned) ──────────────────────────────────
create function app_voucher_void(p_voucher_id uuid, p_reason text) returns void
language plpgsql security definer set search_path = pg_catalog, public, pg_temp as $$
declare
  v_actor uuid := public.app_actor_id();
  v       public.survey_voucher;
begin
  if v_actor is null then raise exception 'sign in first' using errcode = '42501'; end if;
  select * into v from public.survey_voucher where id = p_voucher_id for update;
  if v.id is null then raise exception 'voucher not found'; end if;
  if not public.app_manage_village(v.village_id) then
    raise exception 'only ops or admin may void a voucher' using errcode = '42501';
  end if;
  if v.status <> 'issued' then raise exception 'only an unredeemed voucher can be voided'; end if;
  if nullif(btrim(p_reason), '') is null then raise exception 'give a reason for voiding this voucher'; end if;

  update public.survey_voucher
     set status = 'void', voided_by = v_actor, voided_at = now(), void_reason = btrim(p_reason)
   where id = v.id;
  insert into public.voucher_event (voucher_id, kind, actor_id, actor_name, actor_role, detail)
  values (v.id, 'voided', v_actor, public.app_actor_display_name(), public.app_actor_role(),
          jsonb_build_object('reason', btrim(p_reason)));
end $$;

-- ── hand the RPCs to the writer role ─────────────────────
grant create on schema public to ruaha_observed_writer;
do $$
declare f regprocedure;
begin
  foreach f in array array[
    'survey_block_reason(uuid)'::regprocedure,
    'app_survey_eligibility()'::regprocedure,
    'app_survey_submit(uuid,jsonb,uuid)'::regprocedure,
    'app_voucher_code(uuid)'::regprocedure,
    'voucher_block_reason(survey_voucher)'::regprocedure,
    'app_voucher_lookup(text)'::regprocedure,
    'app_voucher_redeem(text,id_document_type,boolean)'::regprocedure,
    'app_voucher_void(uuid,text)'::regprocedure
  ] loop
    execute format('alter function %s owner to ruaha_observed_writer', f);
    execute format('revoke all on function %s from public, anon, authenticated', f);
  end loop;
end $$;
revoke create on schema public from ruaha_observed_writer;

grant execute on function
  app_survey_eligibility(),
  app_survey_submit(uuid, jsonb, uuid),
  app_voucher_code(uuid),
  app_voucher_lookup(text),
  app_voucher_redeem(text, id_document_type, boolean),
  app_voucher_void(uuid, text)
to authenticated;

-- ── the audit timeline (postgres-owned, read-only) ───────
-- One ordered list per voucher, filtered by who is asking:
--   farmer (own household): issued, answered, redeemed, voided
--   field staff (village):  plus registration, verification, publish, scans
--   ops/admin (project):    everything: audit hold, refused scans, logins
create function app_voucher_timeline(p_voucher_id uuid)
returns table (occurred_at timestamptz, kind text, actor_name text, actor_role text, detail jsonb)
language plpgsql stable security definer set search_path = pg_catalog, public, pg_temp as $$
#variable_conflict use_column
declare
  v     public.survey_voucher;
  h     public.household;
  s     public.survey;
  r     public.survey_response;
  lvl   text;
begin
  select * into v from public.survey_voucher where id = p_voucher_id;
  if v.id is null then return; end if;
  if public.app_manage_village(v.village_id) then lvl := 'full';
  elsif v.village_id in (select public.app_staff_villages()) then lvl := 'staff';
  elsif v.household_id in (select public.app_households()) then lvl := 'farmer';
  else return;
  end if;

  select * into h from public.household where id = v.household_id;
  select * into s from public.survey where id = v.survey_id;
  select * into r from public.survey_response where id = v.response_id;

  return query
  with trail as (
    select h.captured_at as at, 'household_registered'::text as k,
           (select u.display_name from public.app_user u where u.id = h.captured_by) as nm,
           public.app_user_role_label(h.captured_by) as rl, '{}'::jsonb as dt
     where lvl <> 'farmer' and h.captured_by is not null
    union all
    select h.verified_at, 'household_verified',
           (select u.display_name from public.app_user u where u.id = h.verified_by),
           public.app_user_role_label(h.verified_by), '{}'::jsonb
     where lvl <> 'farmer' and h.verified_by is not null
    union all
    select li.issued_at, 'login_' || li.kind, iu.display_name,
           public.app_user_role_label(li.issued_by), '{}'::jsonb
      from public.login_issue li
      join public.app_user fu on fu.id = li.user_id and fu.person_id = r.person_id
      join public.app_user iu on iu.id = li.issued_by
     where lvl = 'full'
    union all
    select s.published_at, 'survey_published',
           (select u.display_name from public.app_user u where u.id = s.published_by),
           public.app_user_role_label(s.published_by), '{}'::jsonb
     where lvl <> 'farmer' and s.published_by is not null
    union all
    select r.submitted_at, 'answered',
           (select u.display_name from public.app_user u where u.id = r.captured_by),
           'farmer', '{}'::jsonb
    union all
    select e.occurred_at, e.kind::text, e.actor_name, e.actor_role,
           case
             when lvl = 'full' then e.detail
             when lvl = 'staff' then e.detail - 'audit_required' - 'needs_ops'
             when e.kind = 'voided' then e.detail
             else '{}'::jsonb
           end
      from public.voucher_event e
     where e.voucher_id = v.id
       and (lvl = 'full'
            or (lvl = 'staff' and e.kind <> 'refused')
            or (lvl = 'farmer' and e.kind in ('issued', 'redeemed', 'voided')))
  )
  select t.at, t.k, t.nm, t.rl, t.dt from trail t where t.at is not null order by t.at;
end $$;
revoke all on function app_voucher_timeline(uuid) from public, anon;
grant execute on function app_voucher_timeline(uuid) to authenticated;

-- ── ops views over vouchers (postgres-owned, ops/admin only) ─
create function app_survey_vouchers(p_survey_id uuid)
returns table (
  voucher_id uuid, household_label text, respondent_name text, submitted_at timestamptz,
  status voucher_status, expired boolean, amount numeric, currency char(3), audit_required boolean,
  issued_at timestamptz, expires_at timestamptz, redeemed_at timestamptz, redeemed_by_name text,
  id_type_seen id_document_type, void_reason text)
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select v.id, h.label, p.given_name || ' ' || p.family_name, r.submitted_at,
         v.status, v.status = 'issued' and v.expires_at <= now(), v.amount, v.currency, v.audit_required,
         v.issued_at, v.expires_at, v.redeemed_at, ru.display_name, v.id_type_seen, v.void_reason
  from public.survey s
  join public.survey_voucher v on v.survey_id = s.id
  join public.survey_response r on r.id = v.response_id
  join public.household h on h.id = v.household_id
  join public.person p on p.id = r.person_id
  left join public.app_user ru on ru.id = v.redeemed_by
  where s.id = p_survey_id and public.app_manages_project(s.project_id)
  order by r.submitted_at desc
$$;

-- Every redemption, for cash reconciliation. Dates are Tanzanian calendar days.
create function app_redemption_log(p_from date, p_to date)
returns table (
  voucher_id uuid, redeemed_at timestamptz, redeemed_by uuid, redeemed_by_name text,
  village_name text, household_label text, survey_title_en text, survey_title_sw text,
  amount numeric, currency char(3), id_type_seen id_document_type, audit_required boolean)
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select v.id, v.redeemed_at, v.redeemed_by, ru.display_name, vi.name, h.label, s.title_en, s.title_sw,
         v.amount, v.currency, v.id_type_seen, v.audit_required
  from public.survey_voucher v
  join public.survey s on s.id = v.survey_id
  join public.household h on h.id = v.household_id
  join public.village vi on vi.id = v.village_id
  left join public.app_user ru on ru.id = v.redeemed_by
  where v.status = 'redeemed'
    and public.app_manage_village(v.village_id)
    and (v.redeemed_at at time zone 'Africa/Dar_es_Salaam')::date between p_from and p_to
  order by v.redeemed_at desc
$$;

create function app_redemption_totals(p_from date, p_to date)
returns table (day date, redeemed_by uuid, redeemed_by_name text, vouchers bigint, amount numeric, currency char(3))
language sql stable security definer set search_path = pg_catalog, public, pg_temp as $$
  select (v.redeemed_at at time zone 'Africa/Dar_es_Salaam')::date, v.redeemed_by, ru.display_name,
         count(*), sum(v.amount), v.currency
  from public.survey_voucher v
  left join public.app_user ru on ru.id = v.redeemed_by
  where v.status = 'redeemed'
    and public.app_manage_village(v.village_id)
    and (v.redeemed_at at time zone 'Africa/Dar_es_Salaam')::date between p_from and p_to
  group by 1, 2, 3, 6
  order by 1 desc, 3
$$;

revoke all on function app_survey_vouchers(uuid), app_redemption_log(date, date), app_redemption_totals(date, date)
  from public, anon;
grant execute on function app_survey_vouchers(uuid), app_redemption_log(date, date), app_redemption_totals(date, date)
  to authenticated;

-- ── staff summaries (security_invoker, like every view) ──
create view v_survey_summary with (security_invoker = true) as
select s.id as survey_id, s.project_id,
       count(r.id)                                                                  as responses,
       count(v.id)                                                                  as issued_count,
       coalesce(sum(v.amount), 0)                                                   as issued_amount,
       count(v.id) filter (where v.status = 'redeemed')                             as redeemed_count,
       coalesce(sum(v.amount) filter (where v.status = 'redeemed'), 0)              as redeemed_amount,
       count(v.id) filter (where v.status = 'issued' and v.expires_at > now())      as outstanding_count,
       coalesce(sum(v.amount) filter (where v.status = 'issued' and v.expires_at > now()), 0) as outstanding_amount,
       count(v.id) filter (where v.status = 'issued' and v.expires_at <= now())     as expired_count,
       count(v.id) filter (where v.status = 'void')                                 as void_count
from survey s
left join survey_response r on r.survey_id = s.id and r.deleted_at is null
left join survey_voucher v on v.response_id = r.id
where app_is_staff()
group by s.id, s.project_id;

-- Choice and yes/no answers, counted per option.
create view v_survey_answer_tally with (security_invoker = true) as
select q.survey_id, q.id as question_id, q.position, q.kind, x.option_value, count(*) as answer_count
from survey_question q
join survey_answer a on a.question_id = q.id
cross join lateral (
  select e #>> '{}' as option_value
    from jsonb_array_elements(case when jsonb_typeof(a.value) = 'array' then a.value else '[]'::jsonb end) e
  union all
  select a.value #>> '{}' where jsonb_typeof(a.value) in ('string', 'boolean')
) x
where q.kind in ('single_choice', 'multi_choice', 'yes_no') and app_is_staff()
group by q.survey_id, q.id, q.position, q.kind, x.option_value;

-- Number answers, summarised.
create view v_survey_number_summary with (security_invoker = true) as
select q.survey_id, q.id as question_id, q.position,
       count(*) as answer_count,
       round(avg((a.value #>> '{}')::numeric), 2) as average,
       min((a.value #>> '{}')::numeric) as minimum,
       max((a.value #>> '{}')::numeric) as maximum
from survey_question q
join survey_answer a on a.question_id = q.id
where q.kind = 'number' and jsonb_typeof(a.value) = 'number' and app_is_staff()
group by q.survey_id, q.id, q.position;

grant select on v_survey_summary, v_survey_answer_tally, v_survey_number_summary to authenticated;
revoke all on v_survey_summary, v_survey_answer_tally, v_survey_number_summary from anon;

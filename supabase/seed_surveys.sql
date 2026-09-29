-- ============================================================
-- Ruaha 360 · DEMO SEED · surveys and incentive vouchers
-- Run after seed.sql. Re-runnable: every write is idempotent.
--
--   psql "$(node scripts/db-url.mjs)" -v ON_ERROR_STOP=1 -f supabase/seed_surveys.sql
--
-- Synthetic data, conspicuously labelled. Survey titles are English only:
-- Swahili copy needs a native reviewer and is left NULL, which falls back
-- to English in the app.
--
-- The demo story this sets up:
--   Salima (officer) registered the Ilundo households; Asha (ops) verified
--   them — a household is never verified by its own registrar; Juma (second
--   Ilundo officer) redeems vouchers, because the registrar and the verifier
--   may not.
--
-- Answers and redemptions go through the real RPCs, so every voucher carries
-- the same audit trail a real one would.
-- ============================================================

do $$
begin
  if exists (select 1 from project where code not like '%-DEMO') then
    raise exception
      'refusing to seed: this database holds a non-demo project. Seed is for demo instances only.';
  end if;
end $$;

-- ── a second Ilundo officer ──────────────────────────────
-- Same GoTrue row shape as seed_user in seed.sql. Password: demo1234
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data,
  confirmation_token, recovery_token, email_change_token_new, email_change
) values (
  '00000000-0000-0000-0000-000000000000', '80000000-0000-4000-8000-000000000007',
  'authenticated', 'authenticated', 'officer2.ilundo@demo.ruaha360.test',
  extensions.crypt('demo1234', extensions.gen_salt('bf')),
  now(), now(), now(),
  '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
  '', '', '', ''
) on conflict (id) do nothing;

insert into auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
select gen_random_uuid(), '80000000-0000-4000-8000-000000000007',
       jsonb_build_object('sub', '80000000-0000-4000-8000-000000000007', 'email', 'officer2.ilundo@demo.ruaha360.test'),
       'email', '80000000-0000-4000-8000-000000000007', now(), now(), now()
where not exists (select 1 from auth.identities where user_id = '80000000-0000-4000-8000-000000000007');

insert into app_user (id, display_name, locale)
values ('80000000-0000-4000-8000-000000000007', 'Juma Officer', 'sw')
on conflict (id) do nothing;

insert into membership (id, user_id, role, project_id, village_id) values
  ('81000000-0000-4000-8000-000000000007', '80000000-0000-4000-8000-000000000007', 'field_officer',
   '20000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

-- ── four eyes on the seeded households ───────────────────
-- seed.sql marks them verified but names no verifier. Asha (ops) is the
-- second pair of eyes; the registrar was Salima or Peter.
update household
   set verified_by = '80000000-0000-4000-8000-000000000002', verified_at = coalesce(verified_at, now())
 where id in ('70000000-0000-4000-8000-000000000001',
              '70000000-0000-4000-8000-000000000002',
              '70000000-0000-4000-8000-000000000004')
   and verification = 'verified' and verified_by is null;

-- ── surveys, authored and published by the demo admin ────
do $$
declare
  admin constant uuid := '80000000-0000-4000-8000-000000000001';
  project constant uuid := '20000000-0000-4000-8000-000000000001';
begin
  perform set_config('request.jwt.claims', json_build_object('sub', admin)::text, true);

  if not exists (select 1 from survey where id = 'f1000000-0000-4000-8000-000000000001') then
    insert into survey (id, project_id, title_en, description_en, reward_amount, max_households, audit_rate)
    values ('f1000000-0000-4000-8000-000000000001', project, 'Maize post-harvest storage — DEMO',
            'How your household stores maize after harvest, and what is lost. DEMO survey.', 5000, 200, 0.15);
    insert into survey_question (id, survey_id, position, kind, prompt_en, required, options) values
      ('f2000000-0000-4000-8000-000000000011', 'f1000000-0000-4000-8000-000000000001', 1, 'single_choice',
       'Where do you store your maize after harvest?', true,
       '[{"value":"granary","label_en":"A granary at home"},{"value":"sacks","label_en":"Sacks in the house"},{"value":"village_store","label_en":"A village store"},{"value":"sold","label_en":"I sell it straight away"}]'),
      ('f2000000-0000-4000-8000-000000000012', 'f1000000-0000-4000-8000-000000000001', 2, 'number',
       'How many 100 kg bags did you store last season?', false, '[]'),
      ('f2000000-0000-4000-8000-000000000013', 'f1000000-0000-4000-8000-000000000001', 3, 'yes_no',
       'Did you lose any maize to pests or damp last season?', true, '[]'),
      ('f2000000-0000-4000-8000-000000000014', 'f1000000-0000-4000-8000-000000000001', 4, 'text',
       'What would help you store maize better?', false, '[]');
    update survey set status = 'live' where id = 'f1000000-0000-4000-8000-000000000001';
  end if;

  if not exists (select 1 from survey where id = 'f1000000-0000-4000-8000-000000000002') then
    insert into survey (id, project_id, title_en, description_en, reward_amount, audit_rate)
    values ('f1000000-0000-4000-8000-000000000002', project, 'Household energy use — DEMO',
            'What your household uses for light and cooling today. DEMO survey.', 3000, 0.15);
    insert into survey_question (id, survey_id, position, kind, prompt_en, required, options) values
      ('f2000000-0000-4000-8000-000000000021', 'f1000000-0000-4000-8000-000000000002', 1, 'multi_choice',
       'What do you use for light at night?', true,
       '[{"value":"kerosene","label_en":"Kerosene lamp"},{"value":"solar","label_en":"Solar lamp"},{"value":"torch","label_en":"Torch or phone light"},{"value":"grid","label_en":"Grid electricity"}]'),
      ('f2000000-0000-4000-8000-000000000022', 'f1000000-0000-4000-8000-000000000002', 2, 'number',
       'Roughly how much do you spend on lighting each week, in TZS?', false, '[]'),
      ('f2000000-0000-4000-8000-000000000023', 'f1000000-0000-4000-8000-000000000002', 3, 'yes_no',
       'Would you use a shared cold room if one were nearby?', true, '[]');
    update survey set status = 'live' where id = 'f1000000-0000-4000-8000-000000000002';
  end if;

  if not exists (select 1 from survey where id = 'f1000000-0000-4000-8000-000000000003') then
    insert into survey (id, project_id, title_en, description_en, reward_amount, audit_rate)
    values ('f1000000-0000-4000-8000-000000000003', project, 'Irrigation interest — DEMO',
            'Whether your household would irrigate, and how far the water is. DEMO survey.', 2000, 0);
    insert into survey_question (id, survey_id, position, kind, prompt_en, required, options) values
      ('f2000000-0000-4000-8000-000000000031', 'f1000000-0000-4000-8000-000000000003', 1, 'yes_no',
       'Would you irrigate if a pump were available?', true, '[]'),
      ('f2000000-0000-4000-8000-000000000032', 'f1000000-0000-4000-8000-000000000003', 2, 'single_choice',
       'How far is your nearest water source?', true,
       '[{"value":"near","label_en":"Under 100 m"},{"value":"mid","label_en":"100 to 500 m"},{"value":"far","label_en":"Over 500 m"}]');
    update survey set status = 'live' where id = 'f1000000-0000-4000-8000-000000000003';
  end if;

  if not exists (select 1 from survey where id = 'f1000000-0000-4000-8000-000000000004') then
    insert into survey (id, project_id, title_en, description_en, reward_amount)
    values ('f1000000-0000-4000-8000-000000000004', project, 'Seed varieties — DEMO',
            'Draft, not yet published. DEMO survey.', 2500);
    insert into survey_question (id, survey_id, position, kind, prompt_en, required, options) values
      ('f2000000-0000-4000-8000-000000000041', 'f1000000-0000-4000-8000-000000000004', 1, 'text',
       'Which maize variety did you plant this season?', true, '[]');
  end if;

  -- Every voucher from this one is held for an in-person ops redemption, so
  -- the demo can show the audit hold on demand.
  if not exists (select 1 from survey where id = 'f1000000-0000-4000-8000-000000000005') then
    insert into survey (id, project_id, title_en, description_en, reward_amount, audit_rate)
    values ('f1000000-0000-4000-8000-000000000005', project, 'Harvest labour — DEMO',
            'Who helped with your last harvest. DEMO survey; every voucher is held for audit.', 4000, 1);
    insert into survey_question (id, survey_id, position, kind, prompt_en, required, options) values
      ('f2000000-0000-4000-8000-000000000051', 'f1000000-0000-4000-8000-000000000005', 1, 'number',
       'How many people helped with your last harvest?', true, '[]'),
      ('f2000000-0000-4000-8000-000000000052', 'f1000000-0000-4000-8000-000000000005', 2, 'yes_no',
       'Were any of them paid?', true, '[]');
    update survey set status = 'live' where id = 'f1000000-0000-4000-8000-000000000005';
  end if;

  perform set_config('request.jwt.claims', '', true);
end $$;

-- ── answers, through the real RPC ────────────────────────
-- random() decides each voucher's audit hold. A fixed seed keeps the demo
-- reproducible without bypassing the rule: these draws come out unheld.
select setseed(0.42);

do $$
declare
  neema  constant uuid := '80000000-0000-4000-8000-000000000005';
  joseph constant uuid := '80000000-0000-4000-8000-000000000006';
  juma   constant uuid := '80000000-0000-4000-8000-000000000007';
  v_result jsonb;
  v_status voucher_status;
begin
  -- Neema's household: irrigation (to be redeemed) and energy use (issued).
  perform set_config('request.jwt.claims', json_build_object('sub', neema)::text, true);
  if (select status from survey where id = 'f1000000-0000-4000-8000-000000000003') = 'live' then
    v_result := app_survey_submit('f1000000-0000-4000-8000-000000000003',
      '{"f2000000-0000-4000-8000-000000000031": true, "f2000000-0000-4000-8000-000000000032": "mid"}',
      'f7000000-0000-4000-8000-000000000001');
  end if;
  perform app_survey_submit('f1000000-0000-4000-8000-000000000002',
    '{"f2000000-0000-4000-8000-000000000021": ["kerosene", "torch"], "f2000000-0000-4000-8000-000000000022": 3500, "f2000000-0000-4000-8000-000000000023": true}',
    'f7000000-0000-4000-8000-000000000002');

  -- Joseph's household: maize storage (issued).
  perform set_config('request.jwt.claims', json_build_object('sub', joseph)::text, true);
  perform app_survey_submit('f1000000-0000-4000-8000-000000000001',
    '{"f2000000-0000-4000-8000-000000000011": "sacks", "f2000000-0000-4000-8000-000000000012": 14, "f2000000-0000-4000-8000-000000000013": true, "f2000000-0000-4000-8000-000000000014": "A dry store with a raised floor."}',
    'f7000000-0000-4000-8000-000000000003');

  -- The irrigation survey closes; its voucher is still good for 30 days.
  perform set_config('request.jwt.claims', json_build_object('sub', '80000000-0000-4000-8000-000000000001')::text, true);
  update survey set status = 'closed' where id = 'f1000000-0000-4000-8000-000000000003' and status = 'live';

  -- Juma scans and redeems Neema's irrigation voucher, NIDA card seen.
  select v.status into v_status from survey_voucher v
    join survey_response r on r.id = v.response_id
   where r.client_ref = 'f7000000-0000-4000-8000-000000000001';
  if v_status = 'issued' then
    perform set_config('request.jwt.claims', json_build_object('sub', juma)::text, true);
    perform app_voucher_lookup((select v.code from survey_voucher v join survey_response r on r.id = v.response_id
                                 where r.client_ref = 'f7000000-0000-4000-8000-000000000001'));
    perform app_voucher_redeem((select v.code from survey_voucher v join survey_response r on r.id = v.response_id
                                 where r.client_ref = 'f7000000-0000-4000-8000-000000000001'), 'nida', true);
  end if;

  perform set_config('request.jwt.claims', '', true);
end $$;

-- ── what you should see ──────────────────────────────────
--  Neema (farmer): Surveys tab badge 2 — maize storage and harvest labour.
--    Irrigation: redeemed by Juma Officer. Energy use: voucher issued.
--  Joseph (farmer): maize storage answered, voucher issued.
--  Salima scanning Joseph's voucher: refused — she registered his household.
--  Asha (ops): refused too — she verified it. Juma: may redeem.
--  Any harvest-labour voucher: held; only ops or admin redeem it, in person.
--  Seeded voucher totals: 3 issued (TZS 10,000), 1 redeemed (TZS 2,000),
--    2 outstanding (TZS 8,000).

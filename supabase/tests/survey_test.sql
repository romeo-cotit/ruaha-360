-- Included by rls_test.sql. Farmer logins, four eyes on households, surveys,
-- vouchers and the audit trail. Every fixture rolls back.

\set ADMIN     '''80000000-0000-4000-8000-000000000001'''
\set OFF_ILU2  '''8f000000-0000-4000-8000-000000000001'''
\set REHEMA_U  '''8f000000-0000-4000-8000-000000000002'''

-- ── fixtures (run as postgres, before any `set local role`) ─
create or replace function pg_temp.fixture_auth_user(p_id uuid, p_email text) returns void
language plpgsql as $$
begin
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    created_at, updated_at, raw_app_meta_data, raw_user_meta_data,
    confirmation_token, recovery_token, email_change_token_new, email_change)
  values ('00000000-0000-0000-0000-000000000000', p_id, 'authenticated', 'authenticated', p_email,
    'fixture', now(), now(), now(), '{}'::jsonb, '{}'::jsonb, '', '', '', '');
end $$;

create or replace function pg_temp.fixture_staff(p_id uuid, p_role app_role, p_village uuid, p_name text)
returns void language plpgsql as $$
begin
  perform pg_temp.fixture_auth_user(p_id, p_id::text || '@fixture.ruaha360.test');
  insert into app_user (id, display_name, locale) values (p_id, p_name, 'en');
  insert into membership (user_id, role, project_id, village_id)
  values (p_id, p_role, '20000000-0000-4000-8000-000000000001', p_village);
end $$;

create or replace function pg_temp.fixture_farmer_login(p_id uuid, p_person uuid) returns void
language plpgsql as $$
begin
  perform pg_temp.fixture_auth_user(p_id, p_id::text || '@fixture.ruaha360.test');
  insert into app_user (id, person_id, display_name, locale) values (p_id, p_person, 'Fixture farmer', 'sw');
  insert into membership (user_id, role, project_id, village_id)
  select p_id, 'farmer', v.project_id, v.id from person p join village v on v.id = p.village_id where p.id = p_person;
end $$;

-- A live survey authored and published by the seeded admin: one required
-- single-choice question (a/b) and one optional number question.
create or replace function pg_temp.fixture_survey(p_id uuid, p_audit numeric, p_max int default null)
returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', '80000000-0000-4000-8000-000000000001')::text, true);
  insert into survey (id, project_id, title_en, reward_amount, audit_rate, max_households)
  values (p_id, '20000000-0000-4000-8000-000000000001', 'Fixture survey', 5000, p_audit, p_max);
  insert into survey_question (survey_id, position, kind, prompt_en, required, options) values
    (p_id, 1, 'single_choice', 'Pick one', true, '[{"value":"a","label_en":"A"},{"value":"b","label_en":"B"}]'),
    (p_id, 2, 'number', 'How many', false, '[]');
  update survey set status = 'live' where id = p_id;
  perform set_config('request.jwt.claims', '', true);
end $$;

create or replace function pg_temp.answers(p_survey uuid, p_choice text) returns jsonb
language sql as $$
  select jsonb_build_object(id::text, p_choice) from survey_question where survey_id = p_survey and position = 1
$$;

-- Seeded households are verified, but by nobody on record. Give them a second
-- staff verifier, as seed.sql does.
create or replace function pg_temp.fixture_four_eyes() returns void language sql as $$
  update household set verified_by = '80000000-0000-4000-8000-000000000002', verified_at = now()
  where id in ('70000000-0000-4000-8000-000000000001', '70000000-0000-4000-8000-000000000002')
$$;

-- ── A. farmer logins ─────────────────────────────────────
begin;
update person set phone = '0712 000 301' where id = '60000000-0000-4000-8000-000000000003';  -- Amina
update person set phone = '+255712000301' where id = '60000000-0000-4000-8000-000000000005'; -- Rehema, same number
select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
set local role authenticated;
select pg_temp.assert_eq((app_farmer_login_issue('60000000-0000-4000-8000-000000000003')->>'kind' = 'initial')::int::bigint,
  1, 'officer issues a first login from the registered phone');
reset role;
select pg_temp.assert_eq((select count(*) from app_user where person_id = '60000000-0000-4000-8000-000000000003' and must_change_password),
  1, 'a new login must change its temporary password');
select pg_temp.assert_eq((select count(*) from membership m join app_user u on u.id = m.user_id
  where u.person_id = '60000000-0000-4000-8000-000000000003' and m.role = 'farmer'
    and m.village_id = '30000000-0000-4000-8000-000000000001' and m.revoked_at is null),
  1, 'the new login is a farmer in her own village');
select pg_temp.assert_eq((select count(*) from auth.users where email = '255712000301@farmers.ruaha360.test'),
  1, 'the login name is the normalised phone');
set local role authenticated;
select pg_temp.assert_eq((app_farmer_login_issue('60000000-0000-4000-8000-000000000003')->>'kind' = 'reset')::int::bigint,
  1, 'issuing again resets the password instead of creating a second login');
reset role;
select pg_temp.assert_eq((select count(*) from app_user where person_id = '60000000-0000-4000-8000-000000000003'),
  1, 'still exactly one login for the person');
select pg_temp.assert_eq((select count(*) from login_issue li join app_user u on u.id = li.user_id
  where u.person_id = '60000000-0000-4000-8000-000000000003' and li.issued_by = :OFF_ILU),
  2, 'every issue is recorded with who issued it');
set local role authenticated;
select pg_temp.assert_raises($q$ select app_farmer_login_issue('60000000-0000-4000-8000-000000000005') $q$,
  'a phone number already used by another login is refused');
select pg_temp.assert_raises($q$ select app_farmer_login_issue('60000000-0000-4000-8000-000000000006') $q$,
  'no login without a phone number');
select pg_temp.assert_raises($q$ select * from login_issue $q$, 'clients cannot read login history', '42501');
select pg_temp.assert_eq((select count(*) from app_person_login_history('60000000-0000-4000-8000-000000000003')),
  2, 'the officer sees the login history, with names');
rollback;

begin;
update person set phone = '0712 000 301' where id = '60000000-0000-4000-8000-000000000003';
select set_config('request.jwt.claims', json_build_object('sub', :OFF_MGA)::text, true);
set local role authenticated;
select pg_temp.assert_raises($q$ select app_farmer_login_issue('60000000-0000-4000-8000-000000000003') $q$,
  'a Mgama officer cannot issue an Ilundo login');
select pg_temp.assert_eq((select count(*) from app_person_login_history('60000000-0000-4000-8000-000000000003')),
  0, 'a Mgama officer sees no Ilundo login history');
rollback;

begin;
select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
set local role authenticated;
select pg_temp.assert_raises($q$ select app_farmer_login_issue('60000000-0000-4000-8000-000000000003') $q$,
  'a farmer cannot issue logins', '42501');
select pg_temp.assert_raises($q$ update app_user set must_change_password = false where id = auth.uid() $q$,
  'a farmer cannot clear the temporary-password flag', '42501');
rollback;

begin;
set local role anon;
select pg_temp.assert_raises($q$ select app_farmer_login_issue('60000000-0000-4000-8000-000000000003') $q$,
  'anonymous login issue denied', '42501');
rollback;

-- The flag clears only once the stored password is no longer the temporary one.
begin;
update person set phone = '0712 000 301' where id = '60000000-0000-4000-8000-000000000003';
select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
set local role authenticated;
select app_farmer_login_issue('60000000-0000-4000-8000-000000000003');
reset role;
select set_config('request.jwt.claims', json_build_object('sub',
  (select id from app_user where person_id = '60000000-0000-4000-8000-000000000003'))::text, true);
set local role authenticated;
select pg_temp.assert_raises($q$ select app_password_changed() $q$,
  'the temporary password does not count as a new one');
reset role;
update auth.users set encrypted_password = extensions.crypt('farmer-chosen', extensions.gen_salt('bf'))
where id = (select id from app_user where person_id = '60000000-0000-4000-8000-000000000003');
set local role authenticated;
select app_password_changed();
select pg_temp.assert_eq((select count(*) from app_user where must_change_password),
  0, 'a changed password clears the flag');
rollback;

-- ── B. registration needs a phone and the farm GPS ───────
begin;
select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
set local role authenticated;
select pg_temp.assert_raises($q$ select app_register_farmer('{"client_ref":"99000000-0000-4000-8000-000000000011","village_id":"30000000-0000-4000-8000-000000000001","person":{"given_name":"MVP","family_name":"NoPhone"},"household":{"label":"x"},"farm":{"label":"x","latitude":"-8.13","longitude":"35.19"},"plot":{"label":"x","area_ha":"1"}}') $q$,
  'registration needs a phone number');
select pg_temp.assert_raises($q$ select app_register_farmer('{"client_ref":"99000000-0000-4000-8000-000000000011","village_id":"30000000-0000-4000-8000-000000000001","person":{"given_name":"MVP","family_name":"BadPhone","phone":"+1 555 0100"},"household":{"label":"x"},"farm":{"label":"x","latitude":"-8.13","longitude":"35.19"},"plot":{"label":"x","area_ha":"1"}}') $q$,
  'registration needs a Tanzanian mobile number');
select pg_temp.assert_raises($q$ select app_register_farmer('{"client_ref":"99000000-0000-4000-8000-000000000011","village_id":"30000000-0000-4000-8000-000000000001","person":{"given_name":"MVP","family_name":"NoGps","phone":"0712000902"},"household":{"label":"x"},"farm":{"label":"x"},"plot":{"label":"x","area_ha":"1"}}') $q$,
  'registration needs the farm GPS position');
select app_register_farmer('{"client_ref":"99000000-0000-4000-8000-000000000012","village_id":"30000000-0000-4000-8000-000000000001","person":{"given_name":"MVP","family_name":"FourEyes","phone":"0712 000 902"},"household":{"label":"FourEyes fixture"},"farm":{"label":"x","latitude":"-8.13","longitude":"35.19"},"plot":{"label":"x","area_ha":"1"}}');
select pg_temp.assert_eq((select count(*) from person where family_name = 'FourEyes' and phone = '+255712000902'),
  1, 'registration stores the normalised phone');

-- ── C. four eyes on households ───────────────────────────
select pg_temp.assert_raises($q$ select app_verify('household', (select id from household where label = 'FourEyes fixture')) $q$,
  'the registering officer cannot verify the household');
select app_verify('person', (select id from person where family_name = 'FourEyes'));
select pg_temp.assert_eq((select count(*) from person where family_name = 'FourEyes' and verification = 'verified'),
  1, 'the registering officer may still verify the person');
select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
select app_verify('household', (select id from household where label = 'FourEyes fixture'));
select pg_temp.assert_eq((select count(*) from household where label = 'FourEyes fixture'
  and verification = 'verified' and verified_by = auth.uid()),
  1, 'a second staff member verifies the household');
rollback;

-- ── D. authoring ─────────────────────────────────────────
begin;
select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
set local role authenticated;
select pg_temp.assert_raises($q$ insert into survey (project_id, title_en, reward_amount)
  values ('20000000-0000-4000-8000-000000000001', 'Ops draft', 1000) $q$,
  'ops cannot author surveys', '42501');
select set_config('request.jwt.claims', json_build_object('sub', :ADMIN)::text, true);
insert into survey (id, project_id, title_en, reward_amount)
values ('f5000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'Authoring fixture', 1000);
select pg_temp.assert_raises($q$ update survey set status = 'live' where id = 'f5000000-0000-4000-8000-000000000001' $q$,
  'a survey cannot go live without questions');
insert into survey_question (survey_id, position, kind, prompt_en, options)
values ('f5000000-0000-4000-8000-000000000001', 1, 'single_choice', 'Pick one', '[{"value":"a","label_en":"A"}]');
select pg_temp.assert_raises($q$ update survey set status = 'live' where id = 'f5000000-0000-4000-8000-000000000001' $q$,
  'a choice question needs at least two options');
update survey_question set options = '[{"value":"a","label_en":"A"},{"value":"b","label_en":"B"}]'
where survey_id = 'f5000000-0000-4000-8000-000000000001';
update survey set status = 'live' where id = 'f5000000-0000-4000-8000-000000000001';
select pg_temp.assert_eq((select count(*) from survey where id = 'f5000000-0000-4000-8000-000000000001'
  and published_by = auth.uid() and published_at is not null and created_by = auth.uid()),
  1, 'publishing stamps who and when');
select pg_temp.assert_raises($q$ update survey set reward_amount = 9999 where id = 'f5000000-0000-4000-8000-000000000001' $q$,
  'a live survey cannot be edited');
select pg_temp.assert_raises($q$ insert into survey_question (survey_id, position, kind, prompt_en)
  values ('f5000000-0000-4000-8000-000000000001', 2, 'text', 'Late question') $q$,
  'no questions are added after publishing');
update survey set status = 'closed' where id = 'f5000000-0000-4000-8000-000000000001';
select pg_temp.assert_raises($q$ update survey set status = 'live' where id = 'f5000000-0000-4000-8000-000000000001' $q$,
  'a closed survey cannot reopen');
rollback;

begin;
select pg_temp.fixture_survey('f5000000-0000-4000-8000-000000000003', 0);
select set_config('request.jwt.claims', json_build_object('sub', :ADMIN)::text, true);
insert into survey (id, project_id, title_en, reward_amount)
values ('f5000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000001', 'Draft fixture', 1000);
select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
set local role authenticated;
select pg_temp.assert_eq((select count(*) from survey where id = 'f5000000-0000-4000-8000-000000000002'),
  0, 'farmers do not see draft surveys');
select pg_temp.assert_eq((select count(*) from survey where id = 'f5000000-0000-4000-8000-000000000003'),
  1, 'farmers see live surveys in their project');
rollback;

-- ── E. answering: once per household ─────────────────────
begin;
select pg_temp.fixture_survey('f5000000-0000-4000-8000-000000000010', 0);
select pg_temp.fixture_four_eyes();
select pg_temp.fixture_farmer_login(:REHEMA_U, '60000000-0000-4000-8000-000000000005');
select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
set local role authenticated;
select pg_temp.assert_eq((select count(*) from app_survey_eligibility()
  where survey_id = 'f5000000-0000-4000-8000-000000000010' and eligible),
  1, 'a verified household may answer');
select app_survey_submit('f5000000-0000-4000-8000-000000000010',
  pg_temp.answers('f5000000-0000-4000-8000-000000000010', 'a'), '99000000-0000-4000-8000-000000000021');
select pg_temp.assert_eq((select count(*) from survey_voucher where survey_id = 'f5000000-0000-4000-8000-000000000010'),
  1, 'answering issues one voucher');
select pg_temp.assert_eq((select count(*) from survey_response where survey_id = 'f5000000-0000-4000-8000-000000000010'
  and captured_by = auth.uid() and source = 'farmer_reported'),
  1, 'the response carries its provenance');
select pg_temp.assert_eq((app_survey_submit('f5000000-0000-4000-8000-000000000010',
  pg_temp.answers('f5000000-0000-4000-8000-000000000010', 'a'), '99000000-0000-4000-8000-000000000021')->>'replayed')::boolean::int::bigint,
  1, 'a retried submit is a replay');
select pg_temp.assert_eq((select count(*) from survey_voucher where survey_id = 'f5000000-0000-4000-8000-000000000010'),
  1, 'a retried submit creates nothing new');
select pg_temp.assert_eq((select count(*) from app_survey_eligibility()
  where survey_id = 'f5000000-0000-4000-8000-000000000010' and not eligible
    and response_id is not null and voucher_id is not null),
  1, 'the list shows the answer and its voucher');
select pg_temp.assert_raises($q$ select code from survey_voucher $q$, 'voucher codes are not readable directly', '42501');
select pg_temp.assert_raises($q$ select audit_required from survey_voucher $q$, 'the audit flag is not readable', '42501');
select pg_temp.assert_eq((select count(*) from survey_voucher v where v.survey_id = 'f5000000-0000-4000-8000-000000000010'
  and app_voucher_code(v.id) ~ '^[0-9A-HJKMNP-TV-Z]{10}$'),
  1, 'the household reads its own code');
select pg_temp.assert_raises($q$ insert into survey_response (survey_id, household_id, person_id, village_id, client_ref, source)
  values ('f5000000-0000-4000-8000-000000000010', '70000000-0000-4000-8000-000000000001',
          '60000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001',
          '99000000-0000-4000-8000-000000000029', 'farmer_reported') $q$,
  'no direct response writes', '42501');
select set_config('request.jwt.claims', json_build_object('sub', :REHEMA_U)::text, true);
select pg_temp.assert_raises($q$ select app_survey_submit('f5000000-0000-4000-8000-000000000010',
  pg_temp.answers('f5000000-0000-4000-8000-000000000010', 'b'), '99000000-0000-4000-8000-000000000022') $q$,
  'a second member of the same household cannot answer again');
select pg_temp.assert_eq((select count(*) from app_survey_eligibility()
  where survey_id = 'f5000000-0000-4000-8000-000000000010' and response_id is not null),
  1, 'the co-member sees the household already answered');
reset role;
select id as nee_voucher from survey_voucher where survey_id = 'f5000000-0000-4000-8000-000000000010' \gset
select set_config('request.jwt.claims', json_build_object('sub', :FARM_JOS)::text, true);
set local role authenticated;
select pg_temp.assert_eq((select count(*) from survey_voucher where survey_id = 'f5000000-0000-4000-8000-000000000010'),
  0, 'another household sees no voucher');
select pg_temp.assert_eq((app_voucher_code(:'nee_voucher') is null)::int::bigint, 1, 'another household cannot read the code');
select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
select pg_temp.assert_eq((app_voucher_code(:'nee_voucher') is null)::int::bigint, 1, 'staff cannot read the code');
rollback;

-- ── F. eligibility rules ─────────────────────────────────
begin;
select pg_temp.fixture_survey('f5000000-0000-4000-8000-000000000011', 0);
select pg_temp.fixture_four_eyes();
select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
update app_user set must_change_password = true where id = :FARM_NEE;
set local role authenticated;
select pg_temp.assert_eq((select count(*) from app_survey_eligibility() where survey_id = 'f5000000-0000-4000-8000-000000000011'
  and reason = 'set your own password before answering surveys'), 1, 'no answers on a temporary password');
select pg_temp.assert_raises($q$ select app_survey_submit('f5000000-0000-4000-8000-000000000011',
  pg_temp.answers('f5000000-0000-4000-8000-000000000011', 'a'), '99000000-0000-4000-8000-000000000023') $q$,
  'submit is refused on a temporary password');
reset role;
update app_user set must_change_password = false where id = :FARM_NEE;
update household set verified_by = captured_by where id = '70000000-0000-4000-8000-000000000001';
set local role authenticated;
select pg_temp.assert_eq((select count(*) from app_survey_eligibility() where survey_id = 'f5000000-0000-4000-8000-000000000011'
  and reason = 'your household must be verified by a second staff member'), 1, 'a household its registrar verified is not eligible');
reset role;
update household set verified_by = :OPS, verification = 'pending' where id = '70000000-0000-4000-8000-000000000001';
set local role authenticated;
select pg_temp.assert_eq((select count(*) from app_survey_eligibility() where survey_id = 'f5000000-0000-4000-8000-000000000011'
  and reason = 'your household has not been verified yet'), 1, 'an unverified household is not eligible');
reset role;
update household set verification = 'verified', created_at = clock_timestamp() + interval '1 minute'
where id = '70000000-0000-4000-8000-000000000001';
set local role authenticated;
select pg_temp.assert_eq((select count(*) from app_survey_eligibility() where survey_id = 'f5000000-0000-4000-8000-000000000011'
  and reason = 'this survey opened before your household was registered'), 1, 'a household newer than the survey is not eligible');
reset role;
update household set created_at = timestamptz '2026-09-01' where id = '70000000-0000-4000-8000-000000000001';
insert into household_member (household_id, person_id) values
  ('70000000-0000-4000-8000-000000000002', '60000000-0000-4000-8000-000000000001');
set local role authenticated;
select pg_temp.assert_eq((select count(*) from app_survey_eligibility() where survey_id = 'f5000000-0000-4000-8000-000000000011'
  and reason = 'your household record needs checking by an officer'), 1, 'a person in two households is not eligible');
rollback;

begin;
select pg_temp.fixture_survey('f5000000-0000-4000-8000-000000000012', 0, 1);
select pg_temp.fixture_survey('f5000000-0000-4000-8000-000000000013', 0);
select pg_temp.fixture_four_eyes();
select set_config('request.jwt.claims', json_build_object('sub', :FARM_JOS)::text, true);
set local role authenticated;
select app_survey_submit('f5000000-0000-4000-8000-000000000012',
  pg_temp.answers('f5000000-0000-4000-8000-000000000012', 'a'), '99000000-0000-4000-8000-000000000031');
select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
select pg_temp.assert_eq((select count(*) from app_survey_eligibility() where survey_id = 'f5000000-0000-4000-8000-000000000012'
  and reason = 'this survey has reached its limit'), 1, 'the budget cap stops the next household');
select pg_temp.assert_raises($q$ select app_survey_submit('f5000000-0000-4000-8000-000000000013', '{}'::jsonb,
  '99000000-0000-4000-8000-000000000032') $q$, 'a required question must be answered');
select pg_temp.assert_raises($q$ select app_survey_submit('f5000000-0000-4000-8000-000000000013',
  pg_temp.answers('f5000000-0000-4000-8000-000000000013', 'z'), '99000000-0000-4000-8000-000000000033') $q$,
  'an answer must be one of the options');
select pg_temp.assert_raises($q$ select app_survey_submit('f5000000-0000-4000-8000-000000000013',
  pg_temp.answers('f5000000-0000-4000-8000-000000000013', 'a') || '{"00000000-0000-4000-8000-000000000000":"x"}'::jsonb,
  '99000000-0000-4000-8000-000000000034') $q$, 'answers must match the survey questions');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :ADMIN)::text, true);
update survey set status = 'closed' where id = 'f5000000-0000-4000-8000-000000000013';
select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
set local role authenticated;
select pg_temp.assert_eq((select count(*) from app_survey_eligibility() where survey_id = 'f5000000-0000-4000-8000-000000000013'
  and reason = 'this survey is closed'), 1, 'a closed survey takes no answers');
rollback;

-- ── G. redeeming: three different staff, and the trail ───
begin;
select pg_temp.fixture_survey('f5000000-0000-4000-8000-000000000020', 0);
select pg_temp.fixture_four_eyes();
select pg_temp.fixture_staff(:OFF_ILU2, 'field_officer', '30000000-0000-4000-8000-000000000001', 'Fixture Second Officer');
select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
set local role authenticated;
select app_survey_submit('f5000000-0000-4000-8000-000000000020',
  pg_temp.answers('f5000000-0000-4000-8000-000000000020', 'a'), '99000000-0000-4000-8000-000000000041');
reset role;
select code as nee_code, id as nee_voucher from survey_voucher where survey_id = 'f5000000-0000-4000-8000-000000000020' \gset
select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
set local role authenticated;
select pg_temp.assert_eq(((app_voucher_lookup(:'nee_code')->>'can_redeem')::boolean = false)::int::bigint,
  1, 'the registering officer is told they may not redeem');
select pg_temp.assert_raises(format($q$ select app_voucher_redeem(%L, 'nida', true) $q$, :'nee_code'),
  'the registering officer cannot redeem');
select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
select pg_temp.assert_raises(format($q$ select app_voucher_redeem(%L, 'nida', true) $q$, :'nee_code'),
  'the verifying staff member cannot redeem');
select set_config('request.jwt.claims', json_build_object('sub', :OFF_MGA)::text, true);
select pg_temp.assert_eq(((app_voucher_lookup(:'nee_code')->>'found')::boolean = false)::int::bigint,
  1, 'an out-of-village scan finds nothing');
select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
select pg_temp.assert_raises(format($q$ select app_voucher_lookup(%L) $q$, :'nee_code'),
  'a farmer cannot look up vouchers', '42501');
select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU2)::text, true);
select pg_temp.assert_raises(format($q$ select app_voucher_redeem(%L, null, true) $q$, :'nee_code'),
  'the ID document type is required');
select pg_temp.assert_raises(format($q$ select app_voucher_redeem(%L, 'nida', false) $q$, :'nee_code'),
  'the name check is required');
select pg_temp.assert_eq((app_voucher_redeem(lower(:'nee_code'), 'nida', true)->>'status' = 'redeemed')::int::bigint,
  1, 'a third staff member redeems, typed in lower case');
select pg_temp.assert_eq((app_voucher_redeem(:'nee_code', 'nida', true)->>'replayed')::boolean::int::bigint,
  1, 'the same officer retrying is a replay, not a second payout');
select set_config('request.jwt.claims', json_build_object('sub', :ADMIN)::text, true);
select pg_temp.assert_raises(format($q$ select app_voucher_redeem(%L, 'nida', true) $q$, :'nee_code'),
  'a redeemed voucher cannot be redeemed again');
reset role;
select pg_temp.assert_eq((select count(*) from voucher_event where voucher_id = :'nee_voucher' and kind = 'redeemed'
  and actor_name = 'Fixture Second Officer' and actor_role = 'field_officer' and detail->>'id_type_seen' = 'nida'),
  1, 'the redemption is recorded with the officer name, role and ID type');
select pg_temp.assert_eq((select count(*) from voucher_event where voucher_id = :'nee_voucher' and kind = 'refused'),
  1, 'the out-of-village scan is on the record');
select pg_temp.assert_eq((select count(*) from voucher_event where voucher_id = :'nee_voucher' and kind = 'scanned'),
  1, 'the in-village scan is on the record');
select pg_temp.assert_raises($q$ update voucher_event set actor_name = 'someone else' $q$, 'the audit trail cannot be edited');
select pg_temp.assert_raises($q$ delete from voucher_event $q$, 'the audit trail cannot be deleted');
select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
set local role authenticated;
select pg_temp.assert_eq((select count(*) from app_voucher_timeline(:'nee_voucher')
  where kind in ('scanned', 'refused', 'household_registered', 'household_verified')),
  0, 'the farmer sees no scans or staff steps');
select pg_temp.assert_eq((select count(*) from app_voucher_timeline(:'nee_voucher')
  where kind = 'redeemed' and actor_name = 'Fixture Second Officer'),
  1, 'the farmer sees who redeemed her voucher');
select pg_temp.assert_raises($q$ select * from voucher_event $q$, 'clients cannot read events directly', '42501');
select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
select pg_temp.assert_eq((select count(*) from app_voucher_timeline(:'nee_voucher') where kind = 'refused'),
  0, 'field staff do not see refused scans');
select pg_temp.assert_eq((select count(*) from app_voucher_timeline(:'nee_voucher') where kind = 'scanned'),
  1, 'field staff see scans');
select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
select pg_temp.assert_eq((select count(distinct kind) from app_voucher_timeline(:'nee_voucher')),
  8, 'ops sees the whole trail: registered, verified, published, answered, issued, scanned, refused, redeemed');
select set_config('request.jwt.claims', json_build_object('sub', :OFF_MGA)::text, true);
select pg_temp.assert_eq((select count(*) from app_voucher_timeline(:'nee_voucher')), 0, 'another village sees no trail');
rollback;

-- ── H. audit hold, void, expiry ──────────────────────────
begin;
select pg_temp.fixture_survey('f5000000-0000-4000-8000-000000000030', 1);
select pg_temp.fixture_survey('f5000000-0000-4000-8000-000000000031', 0);
select pg_temp.fixture_four_eyes();
select pg_temp.fixture_staff(:OFF_ILU2, 'field_officer', '30000000-0000-4000-8000-000000000001', 'Fixture Second Officer');
select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
set local role authenticated;
select app_survey_submit('f5000000-0000-4000-8000-000000000030',
  pg_temp.answers('f5000000-0000-4000-8000-000000000030', 'a'), '99000000-0000-4000-8000-000000000051');
select app_survey_submit('f5000000-0000-4000-8000-000000000031',
  pg_temp.answers('f5000000-0000-4000-8000-000000000031', 'a'), '99000000-0000-4000-8000-000000000053');
select set_config('request.jwt.claims', json_build_object('sub', :FARM_JOS)::text, true);
select app_survey_submit('f5000000-0000-4000-8000-000000000030',
  pg_temp.answers('f5000000-0000-4000-8000-000000000030', 'b'), '99000000-0000-4000-8000-000000000052');
reset role;
select code as held_code from survey_voucher where survey_id = 'f5000000-0000-4000-8000-000000000030'
  and household_id = '70000000-0000-4000-8000-000000000001' \gset
select code as jos_code, id as jos_voucher from survey_voucher where survey_id = 'f5000000-0000-4000-8000-000000000030'
  and household_id = '70000000-0000-4000-8000-000000000002' \gset
select code as old_code from survey_voucher where survey_id = 'f5000000-0000-4000-8000-000000000031' \gset
update survey_voucher set expires_at = now() - interval '1 day' where survey_id = 'f5000000-0000-4000-8000-000000000031';
select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU2)::text, true);
set local role authenticated;
select pg_temp.assert_eq((app_voucher_lookup(:'held_code')->>'needs_ops')::boolean::int::bigint,
  1, 'a held voucher tells the officer it needs ops');
select pg_temp.assert_raises(format($q$ select app_voucher_redeem(%L, 'voter', true) $q$, :'held_code'),
  'a field officer cannot redeem a held voucher');
select pg_temp.assert_raises(format($q$ select app_voucher_redeem(%L, 'nida', true) $q$, :'old_code'),
  'an expired voucher cannot be redeemed');
select pg_temp.assert_raises(format($q$ select app_voucher_void(%L, 'x') $q$, :'jos_voucher'),
  'a field officer cannot void', '42501');
select set_config('request.jwt.claims', json_build_object('sub', :ADMIN)::text, true);
select pg_temp.assert_eq((app_voucher_redeem(:'held_code', 'voter', true)->>'status' = 'redeemed')::int::bigint,
  1, 'admin redeems a held voucher in person');
select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
select pg_temp.assert_raises(format($q$ select app_voucher_void(%L, '  ') $q$, :'jos_voucher'),
  'a void needs a reason');
select app_voucher_void(:'jos_voucher', 'Duplicate household found on a field visit');
select set_config('request.jwt.claims', json_build_object('sub', :ADMIN)::text, true);
select pg_temp.assert_raises(format($q$ select app_voucher_redeem(%L, 'nida', true) $q$, :'jos_code'),
  'a voided voucher cannot be redeemed');
select pg_temp.assert_eq((select count(*) from app_voucher_timeline(:'jos_voucher') where kind = 'voided'
  and detail->>'reason' = 'Duplicate household found on a field visit'),
  1, 'the void and its reason are on the trail');
select pg_temp.assert_eq((select sum(vouchers)::bigint from app_redemption_totals(current_date - 1, current_date + 1)
  where redeemed_by = :ADMIN), 1, 'the redemption log totals per officer per day');
select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU2)::text, true);
select pg_temp.assert_eq((select count(*) from app_redemption_log(current_date - 1, current_date + 1)),
  0, 'field officers do not see the cash reconciliation log');
rollback;

-- ── I. anonymous callers reach nothing ───────────────────
begin;
set local role anon;
select pg_temp.assert_raises($q$ select * from survey $q$, 'anonymous survey read denied', '42501');
select pg_temp.assert_raises($q$ select app_voucher_lookup('ABCDE12345') $q$, 'anonymous voucher lookup denied', '42501');
select pg_temp.assert_raises($q$ select * from app_voucher_timeline('00000000-0000-4000-8000-000000000000') $q$,
  'anonymous timeline denied', '42501');
select pg_temp.assert_raises($q$ select * from app_survey_eligibility() $q$, 'anonymous eligibility denied', '42501');
rollback;

-- ── J. the seeded demo (supabase/seed_surveys.sql) ───────
begin;
select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
set local role authenticated;
select pg_temp.assert_eq((select count(*) from app_survey_eligibility() where eligible),
  2, 'seeded: Neema has two surveys to answer (maize storage, harvest labour)');
select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
select pg_temp.assert_eq((select sum(issued_count)::bigint from v_survey_summary
  where survey_id::text like 'f1000000-0000-4000-8000-00000000000_'), 3, 'seeded: three vouchers issued');
select pg_temp.assert_eq((select sum(issued_amount)::bigint from v_survey_summary
  where survey_id::text like 'f1000000-0000-4000-8000-00000000000_'), 10000, 'seeded: TZS 10,000 issued');
select pg_temp.assert_eq((select sum(redeemed_amount)::bigint from v_survey_summary
  where survey_id::text like 'f1000000-0000-4000-8000-00000000000_'), 2000, 'seeded: TZS 2,000 redeemed, by Juma');
select pg_temp.assert_eq((select sum(outstanding_amount)::bigint from v_survey_summary
  where survey_id::text like 'f1000000-0000-4000-8000-00000000000_'), 8000, 'seeded: TZS 8,000 outstanding');
rollback;

drop function pg_temp.fixture_four_eyes();
drop function pg_temp.answers(uuid, text);
drop function pg_temp.fixture_survey(uuid, numeric, int);
drop function pg_temp.fixture_farmer_login(uuid, uuid);
drop function pg_temp.fixture_staff(uuid, app_role, uuid, text);
drop function pg_temp.fixture_auth_user(uuid, text);

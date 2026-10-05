-- ============================================================
-- Ruaha 360 · DEMO SEED · resource catalogue
-- Run after seed.sql. Re-runnable: every write is idempotent.
--
--   psql "$(node scripts/db-url.mjs)" -v ON_ERROR_STOP=1 -f supabase/seed_resources.sql
--
-- Synthetic data. Every price, rent and loan amount is INDICATIVE: not a
-- quotation, not an offer. Loans are LISTINGS ONLY — no interest, deposit,
-- term, schedule or repayment (research item C is open). The Swahili is an
-- UNREVIEWED DRAFT from docs/i18n-glossary.md.
--
-- The new machines carry no requests, so the Tower's seeded figures
-- (10.800 kW approved peak, 489.200 kW headroom) do not move.
-- ============================================================

do $$
begin
  if exists (select 1 from project where code not like '%-DEMO') then
    raise exception
      'refusing to seed: this database holds a non-demo project. Seed is for demo instances only.';
  end if;
end $$;

-- ── rent or buy, on the five seeded machines ──────────────
update equipment e set can_rent = v.can_rent, can_buy = v.can_buy,
                       indicative_rent_per_day = v.rent
from (values
  ('51000000-0000-4000-8000-000000000001'::uuid, true,  true, 150000.00),  -- maize mill
  ('51000000-0000-4000-8000-000000000002'::uuid, true,  true,  25000.00),  -- solar pump
  ('51000000-0000-4000-8000-000000000003'::uuid, false, true,       null), -- oil press
  ('51000000-0000-4000-8000-000000000004'::uuid, true,  true, 180000.00),  -- grain dryer
  ('51000000-0000-4000-8000-000000000005'::uuid, false, true,       null)  -- cold room
) as v(id, can_rent, can_buy, rent)
where e.id = v.id;

-- ── three more machines, no requests against them ─────────
insert into equipment (id, project_id, category_id, code, name_en, name_sw,
                       rated_power_kw, typical_hours_per_day, typical_days_per_week,
                       indicative_price, currency, can_rent, can_buy, indicative_rent_per_day) values
  ('51000000-0000-4000-8000-000000000006', '20000000-0000-4000-8000-000000000001',
   '50000000-0000-4000-8000-000000000001', 'HAMMER-200',
   'Hammer mill 200 kg/hr', 'Mashine ya kusaga ya nyundo 200 kg/saa',
   5.500, 5.00, 5.0, null, 'TZS', true, false, 60000.00),
  ('51000000-0000-4000-8000-000000000007', '20000000-0000-4000-8000-000000000001',
   '50000000-0000-4000-8000-000000000003', 'HULLER-RICE',
   'Rice huller 600 kg/hr', 'Mashine ya kukoboa mpunga 600 kg/saa',
   11.000, 6.00, 5.0, 18500000.00, 'TZS', true, true, 120000.00),
  ('51000000-0000-4000-8000-000000000008', '20000000-0000-4000-8000-000000000001',
   '50000000-0000-4000-8000-000000000002', 'DRIP-05',
   'Solar drip irrigation kit, 0.5 ha', 'Seti ya umwagiliaji wa matone ya jua, ha 0.5',
   0.750, 4.00, 7.0, 4200000.00, 'TZS', false, true, null)
on conflict (id) do update set
  can_rent = excluded.can_rent, can_buy = excluded.can_buy,
  indicative_rent_per_day = excluded.indicative_rent_per_day,
  indicative_price = excluded.indicative_price;

-- ── loan listings ─────────────────────────────────────────
insert into loan_product (id, project_id, code, name_en, name_sw, description_en, description_sw,
                          indicative_min_amount, indicative_max_amount, currency) values
  ('52000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'INPUT',
   'Input loan: seed and fertiliser', 'Mkopo wa pembejeo: mbegu na mbolea',
   'For a season''s seed and fertiliser. Ask at the Ruaha office whether you are eligible.',
   'Kwa mbegu na mbolea za msimu mmoja. Uliza ofisi ya Ruaha kama unastahili.',
   200000.00, 1500000.00, 'TZS'),
  ('52000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000001', 'PROCESSOR',
   'Working capital for small processors', 'Mtaji wa kuendeshea kwa wasindikaji wadogo',
   'For millers, pressers and dryers buying produce to process. Ask at the Ruaha office.',
   'Kwa wasagaji, wakamuaji na wakaushaji wanaonunua mazao ya kusindika. Uliza ofisi ya Ruaha.',
   1000000.00, 5000000.00, 'TZS'),
  ('52000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000001', 'GROUP-EQUIP',
   'Farmer group equipment loan', 'Mkopo wa vifaa kwa vikundi vya wakulima',
   'For a registered farmer group buying a shared machine. Ask at the Ruaha office.',
   'Kwa kikundi cha wakulima kilichosajiliwa kinachonunua mashine ya pamoja. Uliza ofisi ya Ruaha.',
   2000000.00, 10000000.00, 'TZS')
on conflict (id) do update set
  name_en = excluded.name_en, name_sw = excluded.name_sw,
  description_en = excluded.description_en, description_sw = excluded.description_sw,
  indicative_min_amount = excluded.indicative_min_amount,
  indicative_max_amount = excluded.indicative_max_amount;

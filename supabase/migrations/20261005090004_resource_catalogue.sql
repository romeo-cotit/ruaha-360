-- Ruaha 360 · resource catalogue: equipment to rent or buy, loan listings
--
-- The ops catalogue becomes a Resource Catalogue. Two kinds of resource:
--
--   * equipment, offered to rent, to buy, or both, each with an INDICATIVE
--     price (buy) and/or an INDICATIVE rent per day. A farmer's request says
--     which they want (`pue_request.acquisition`). The energy estimate does
--     not change: a machine draws the same power rented or owned.
--
--   * loan listings (`loan_product`): a name, a description and an
--     INDICATIVE amount range. LISTING ONLY. No interest, deposit, term,
--     schedule or repayment — research item C (Bank of Tanzania Tier 2
--     classification) is unresolved and nothing here models lending. A
--     farmer cannot request a loan in the app; they ask at the office.
--
-- Ops and admin add rows (config tables: no provenance). Requested and
-- approved by the product owner on 5 Oct 2026, loans as listings only.

-- ── equipment: rent and/or buy ────────────────────────────
alter table equipment
  add column can_rent boolean not null default false,
  add column can_buy  boolean not null default true,
  add column indicative_rent_per_day numeric(14,2) check (indicative_rent_per_day >= 0),
  add constraint equipment_offered check (can_rent or can_buy);

comment on column equipment.indicative_rent_per_day is
  'INDICATIVE rent per day, not a quotation. Not a financial record.';

create type acquisition_mode as enum ('rent', 'buy');

-- Every existing request was for a machine to own: they backfill as buy.
alter table pue_request
  add column acquisition acquisition_mode not null default 'buy';

-- The request must ask for what the catalogue offers.
create function pue_request_acquisition_check() returns trigger
language plpgsql security definer set search_path = pg_catalog, public, pg_temp as $$
declare
  v_rent boolean;
  v_buy  boolean;
begin
  select can_rent, can_buy into v_rent, v_buy from equipment where id = new.equipment_id;
  if new.acquisition = 'rent' and not coalesce(v_rent, false) then
    raise exception 'this equipment is not offered for rent';
  elsif new.acquisition = 'buy' and not coalesce(v_buy, false) then
    raise exception 'this equipment is not offered for sale';
  end if;
  return new;
end $$;

create trigger pue_request_acquisition_trg
  before insert or update of acquisition, equipment_id on pue_request
  for each row execute function pue_request_acquisition_check();

-- Same guard, with `acquisition` among the fields a submitted request locks.
create or replace function pue_request_guard() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  is_reviewer boolean := app_has_role('ops') or app_has_role('admin');
begin
  if tg_op = 'INSERT' then
    if new.status not in ('draft','submitted') then
      raise exception 'a request may only be created as draft or submitted';
    end if;
    if new.status = 'submitted' then new.submitted_at := now(); end if;
    new.decided_at := null; new.decided_by := null;
    return new;
  end if;

  if new.status is distinct from old.status then
    if not (
         (old.status = 'draft'        and new.status in ('submitted','withdrawn'))
      or (old.status = 'submitted'    and new.status in ('under_review','withdrawn'))
      or (old.status = 'under_review' and new.status in ('approved','rejected'))
    ) then
      raise exception 'illegal transition % -> %', old.status, new.status;
    end if;

    if new.status in ('under_review','approved','rejected') and not is_reviewer then
      raise exception 'only ops or admin may review a request';
    end if;

    if new.status = 'submitted' then
      new.submitted_at := coalesce(old.submitted_at, now());
    end if;

    if new.status in ('approved','rejected') then
      new.decided_at := now();
      new.decided_by := auth.uid();
    end if;
  else
    new.submitted_at := old.submitted_at;
    new.decided_at   := old.decided_at;
    new.decided_by   := old.decided_by;
  end if;

  if old.status <> 'draft' and not is_reviewer then
    if (new.equipment_id, new.quantity, new.hours_per_day, new.days_per_week, new.purpose, new.acquisition)
       is distinct from
       (old.equipment_id, old.quantity, old.hours_per_day, old.days_per_week, old.purpose, old.acquisition)
    then
      raise exception 'a submitted request cannot be edited';
    end if;
  end if;

  return new;
end $$;

-- ── the pipeline: a rent is not a purchase price ──────────
-- indicative_value stays catalogue price x quantity, now for BUY requests
-- only; rent requests carry their indicative rent per day separately. Neither
-- is financed value or a loan book.
create or replace view v_village_pue_pipeline with (security_invoker = true) as
select
  pr.village_id,
  pr.status,
  count(*)                                                          as request_count,
  sum(eq.indicative_price * pr.quantity) filter (where pr.acquisition = 'buy') as indicative_value,
  eq.currency,
  sum(eq.indicative_rent_per_day * pr.quantity) filter (where pr.acquisition = 'rent') as indicative_rent_per_day
from pue_request pr
join equipment eq on eq.id = pr.equipment_id
where pr.deleted_at is null
  and app_is_staff()
group by pr.village_id, pr.status, eq.currency;

-- ── loan listings ─────────────────────────────────────────
create table loan_product (
  id                     uuid primary key default gen_random_uuid(),
  project_id             uuid not null references project(id) on delete restrict,
  code                   text not null check (length(btrim(code)) > 0),
  name_en                text not null check (length(btrim(name_en)) > 0),
  name_sw                text not null check (length(btrim(name_sw)) > 0),
  description_en         text,
  description_sw         text,
  indicative_min_amount  numeric(14,2) not null,
  indicative_max_amount  numeric(14,2) not null,
  currency               char(3) not null default 'TZS',
  is_active              boolean not null default true,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  unique (project_id, code),
  constraint loan_product_amount_range check (
    indicative_min_amount > 0 and indicative_min_amount <= indicative_max_amount)
);

comment on table loan_product is
  'Loan LISTINGS for the resource catalogue. Listing only: no interest, deposit, term, '
  'schedule or repayment. Research item C (BoT Tier 2 classification) is unresolved. '
  'Amounts are INDICATIVE, not an offer.';

create index loan_product_project_idx on loan_product (project_id) where is_active;

create trigger loan_product_updated_at before update on loan_product
  for each row execute function set_updated_at();
create trigger loan_product_audit after insert or update or delete on loan_product
  for each row execute function write_audit();

alter table loan_product enable row level security;

create policy loan_product_read on loan_product for select to authenticated
  using (project_id in (select app_projects()));
create policy loan_product_write on loan_product for insert to authenticated
  with check (app_manages_project(project_id));
create policy loan_product_update on loan_product for update to authenticated
  using (app_manages_project(project_id))
  with check (app_manages_project(project_id));

revoke all on loan_product from anon;
revoke delete on loan_product from authenticated;

# Ruaha 360 — working agreement

You are building the MVP of Ruaha 360: a rural economic development platform
for Ruaha Energy, first deployment Ilundo, Tanzania.

**Target: a working stakeholder demo by 30 September 2026.**
Solo developer. Demo data only — no real farmer data will be entered.

---

## Read before writing code

In this order. Do not skip.

1. `docs/schema.md` — tables, conventions, role matrix
2. `docs/business-rules.md` — how every function behaves, and what the database
   enforces so you don't
3. `docs/screens-and-components.md` — every screen, its data, its states, its
   acceptance criteria

Those three plus `supabase/migrations/` are the specification. This file is the
working agreement.

---

## Start here — the first session

> **Done, and superseded.** Tier 0 passed on 10 September 2026 and all seven
> tiers are built. This section is kept as the record of what the gate was.
> **There is no local Supabase on this project and none is wanted** — the cloud
> dev project is the only database. Use `pnpm db:rls`, not the commands below.

**Do not write UI first.** The migrations have never been applied. Everything
downstream inherits their assumptions.

```bash
supabase start
supabase db reset                                   # migrations + seed
psql "$LOCAL_DB_URL" -f supabase/tests/rls_test.sql
```

Expect failures. The assertion suite tests policies nobody has executed. Likely
breakages, in order:

1. `auth.users` / `auth.identities` shape in `seed.sql` — GoTrue version drift.
   Fallback is documented in the seed header
2. The farmer's visible-person count — `person_read_household` is the most
   intricate policy in the schema
3. `set local role authenticated` behaviour in your psql session

**Fix the migrations in place.** Nothing has been pushed to a shared database,
so corrections are edits, not new migrations. Once `db push` runs, that freedom
is gone forever.

> **No longer true, as of 11 September 2026.** The nine migrations are now
> recorded in `supabase_migrations.schema_migrations` on the dev project,
> statements included. A schema change is a NEW migration from here on — never
> an edit to an existing one. See `supabase/README.md`.

Only when every assertion passes does UI work begin.

## Current status — 25 September 2026

- Twelve migrations applied to the cloud dev project. The security one,
  `20260925090001_mvp_security`, closes direct client writes to observed and
  relationship tables. Those change only through the four RPCs, which run as
  the `NOLOGIN`, `NOBYPASSRLS` role `ruaha_observed_writer` so RLS still
  applies. Farmers are read-only on person and production records.
- `20260925120001_staff_scope_followup` scopes the remaining staff read paths
  (`app_staff_households`, `app_staff_opportunities`, `fm_read`) to staff villages.
- `app_user` is self-read only; provenance names come from `app_actor_names`.
- Opportunity writes are ops/admin only; its status machine and the supply
  commitment lock live in Postgres (business-rules §8).
- `pnpm db:rls` runs 193 assertions (92 until 29 Sep, plus `tests/survey_test.sql`).
  The Playwright journey signs in as the farmer it registered, with the phone
  and temporary password its login card showed, then continues through a
  survey answered, refused to the registrar, and redeemed by a second officer.
- Proof and open items: `docs/mvp-proof.md`.

## Surveys and farmer logins — added 29 September 2026

Approved by the product owner on 29 Sep 2026 as an exception to "Do not
build" (notifications, QR payments), for this feature only. Rules:
business-rules §15–17.

- Farmers sign in with their registered phone and a temporary password the
  officer's screen shows once; first sign-in forces a new password. Phone and
  farm GPS are now required at registration.
- Admin authors surveys in the ops shell; each household answers a survey
  once and gets a single-use QR voucher for a fixed cash incentive, redeemed
  at the office. In-app badge only — no SMS, no push.
- Anti-collusion: a household is verified by someone other than its
  registrar; its vouchers are redeemed by a third person; a random share
  (default 15%) is held for ops/admin; the redeemer records the ID type seen
  (never the number). Every step is on an append-only, named audit trail.
- Three migrations (`20260929090001`–`…03`), `supabase/seed_surveys.sql`
  (run after `seed.sql`), `pnpm db:rls` now 193 assertions.
- Dependencies `uqr` (QR drawing) and `qr-scanner` (camera) were approved.

## Guided tour — 30 September 2026

The tour is the demo script. Each role has chapters (one per module) in
`src/app/tour/chapters/`; the header **Tour** button opens a menu of them,
and the Welcome chapter runs once on a first visit. Rules for anything added:

- It explains and never performs a one-way action. It may open a row
  (`open`) and let a person try something that keeps nothing (`tryIt`);
  it never presses Verify, Approve, Redeem, Publish, Void or Submit.
  `e2e/tour.spec.ts` plays every chapter and fails on any server write.
- Anchors are literal `data-testid` values. Copy carries the labelling rules
  below (planned, estimate, indicative, not a sale, fixed cash amount).
- `docs/demo-script.md` is the run sheet: Part A is the read-only tour-led
  run, Part B the live chain and what it leaves behind.

---

## Non-negotiables

1. **Migrations are the only source of schema truth.** Never change schema in
   the Supabase dashboard. This is also what makes a later self-host a copy
   rather than a rewrite.
2. **RLS is the security boundary.** Route guards are convenience. Never add a
   client-side check as a substitute for a policy.
3. **Zero rows is an answer**, not an error. RLS returning nothing means "you
   may not see this". Render an empty state. Never retry, never escalate.
4. **Do not invent tables, columns, views or enum values.** If a screen appears
   to need one that does not exist, stop and ask. The absence is usually
   deliberate — `capacity_basis` has no `'measured'` value on purpose.
5. **Do not pre-validate rules the database enforces.** Call it, catch the
   error, show the message. A client-side copy of a trigger drifts within a
   fortnight.
6. **Every observed-table insert goes through `withProvenance`.** Write that
   helper before the second feature, not after the thirtieth call site.
7. **Do not add dependencies** beyond the locked stack. If something seems to
   need one, ask first.
8. **The MVP contains no AI.** No pgvector, no embeddings, no assistant, no
   "smart" suggestions. Plan v2 defers all of it (S07, S18, S21).

---

## Stack — locked

```
Vite + React + TypeScript          SPA, no SSR
TanStack Router                    typed routes, URL-held filter state, guards
TanStack Query                     all server state; no other state manager
Tailwind + shadcn/ui               UI primitives
TanStack Table                     ops tables, Tower drill-downs
react-hook-form + Zod              forms
react-i18next                      Swahili + English
vite-plugin-pwa                    cached shell
react-joyride                      the guided tour (approved at the product owner's request)
@supabase/supabase-js              the only data client
Playwright + Vitest                e2e and unit
```

**Explicitly not used:** SSR of any kind · Next.js · Nuxt · TanStack Start ·
monorepo tooling · Drizzle or any ORM · GraphQL · NestJS or any separate
backend · Redux/Zustand/Jotai · any chart library before the Tower renders real
numbers.

Rationale for each is in the specs. Reopen a decision only with a concrete
reason, and say what changed.

---

## Commands

```bash
pnpm dev                # vite
pnpm build              # static bundle
pnpm typecheck
pnpm test               # vitest
pnpm e2e                # playwright, against the cloud dev project + seed
pnpm e2e journey        # the acceptance journey alone

pnpm db:list            # migration history: files vs database
pnpm db:push            # apply pending migrations (db:push:dry to preview)
pnpm db:types           # regenerate src/lib/db.types.ts (Management API)
pnpm db:rls             # the 193 policy assertions
```

**No local Supabase.** The cloud dev project is the only database — every
`db:*` script points there through `scripts/db-url.mjs`. Do not reach for
`supabase start`, `db reset` or any `--local` flag; see `supabase/README.md`.

Regenerate `db.types.ts` after every migration change and commit it. No
hand-written row types.

---

## Layout

```
src/
  app/            router, providers, layouts, guards
  routes/         TanStack Router route files
  features/
    officer/  farmer/  ops/  tower/
  components/     shared UI (see spec §9)
  lib/
    supabase.ts     client
    db.types.ts     GENERATED — never hand-edited
    provenance.ts   withProvenance
    drafts.ts       useDraft, IndexedDB
    queryKeys.ts    the key registry from business-rules §10
    format.ts       units, currency, dates
  i18n/
    en/common.json  sw/common.json  (+ per-feature namespaces)
  styles/
supabase/
  migrations/  seed.sql  tests/rls_test.sql
docs/
e2e/            the acceptance journey
```

Reference data — crop names, equipment names, categories — is translated **in
the database** (`name_en` / `name_sw`), not in JSON. Those rows are created at
runtime and repo files cannot translate them.

---

## Environment

```
VITE_SUPABASE_URL
VITE_SUPABASE_ANON_KEY
VITE_DATA_MODE=demo        # drives the demo banner
```

The demo banner is driven by this variable, never by a database column. The
demo instance and any future live instance are **different databases** — there
is no `is_demo` flag by design.

Never commit a service-role key. Never use one from the browser.

---

## Build order

Tiers are defined in `docs/screens-and-components.md`.

```
0  migrations green + rls_test passing        <- gate, not a task
1  shell · login · membership routing · i18n · brand tokens
2  officer register (the RPC) + person detail + verify
3  farmer my-farm + equipment + request
4  ops request pipeline + review + decide
5  ops demand + coverage + opportunity + supply
6  tower tiles + drill-downs
7  seed polish + playwright journey
```

**Finish every T1 screen before any T2 screen.** The T1 set is exactly the
acceptance journey. Steps 2 and 3 are the whole product — everything after is a
view over what the officer wrote.

Do not start at step 6 because it demos well.

---

## Definition of done

Both must be true:

1. `supabase/tests/rls_test.sql` passes with no failures
2. The acceptance journey passes in Playwright against seeded demo data:

```
officer registers person + household + farm + plot + cycle + expected harvest
officer verifies the records; a second staff member verifies the household
farmer signs in with the login card's phone + temporary password, sets their own
farmer sees the same records, with provenance
farmer submits an equipment request; the estimate moves when hours change
ops reviews and approves
ops opens the maize demand and sees Ilundo coverage
ops creates an opportunity and attaches supply
tower reflects all of it, and a headline drills to that farmer's record
admin publishes a survey; the farmer answers once and gets a voucher
the registering officer may not redeem it; a second officer does, ID checked
the farmer sees who handed it over; ops sees every name on the trail
```

Plus: role permissions tested, and an interrupted save in step 1 that survives
a reload.

Expected seeded figures — assert these, do not eyeball them:

```
Ilundo maize, Sept    12,000 kg expected  (superseded 3,200 excluded)
committed              6,400 kg
available              5,600 kg
demand 9,000 kg    →   62.2% coverage
approved peak          (15.0 + 2×1.5) × 0.600 = 10.800 kW
headroom               489.200 kW
```

---

## Language and labelling

These are product requirements, not copy preferences. Getting them wrong
misrepresents the programme.

- Capacity is **planned**, never measured. Always shown with its `basis`
- Prospective and approved demand are separate figures, **never summed**
- An estimate is always labelled an estimate
- Prices are always labelled **indicative**. They are not quotations
- An opportunity is **not** a sale, a delivery or a payment
- `cycle_area_ha` is "planted area across cycles", never "land area" —
  intercropping means it can exceed the village's hectares
- Every record shows where its data came from (`ProvenanceBadge`)
- A survey incentive is **a fixed cash amount per household per survey**,
  paid at the office. Never "earnings", "wallet", "balance" or "payment",
  and not "indicative" — it is not a price

Farmer and Officer surfaces ship complete Swahili. Ops and Tower may ship
English for the demo.

**Swahili is a DRAFT, approved by the product owner on 29 September 2026 as an
exception to "no machine translation"**, so people who do not read English can
use the demo. It is written by Claude from a sourced glossary
(`docs/i18n-glossary.md`), back-translated blind as a cross-check, and **has not
been seen by a native reader**. Rules that still hold:

- Nothing is called reviewed unless `src/i18n/sw/reviewed.json` says a named
  person reviewed it. Every other Swahili string is a draft, and
  `docs/i18n-handover.md` (and `.csv`) is what a reviewer receives
- New Swahili follows the glossary's editorial decisions, and any term with no
  Tanzanian source is marked `unverified` there. Flag it, do not guess
- The labelling rules below survive translation. `bundles.test.ts` guards the
  incentive wording; the rest is on whoever writes the string
- Database messages a farmer or officer can reach are mapped in
  `src/lib/dbMessages.ts` (exact match, values kept); every other database
  message is still shown verbatim, per business-rules §9

---

## Do not build

Training · Services · Progress · translations admin · user admin · photo
upload · farm polygons · PostGIS · offline sync queues · notifications (beyond the
in-app survey badge) · meter screens · tariffs · finance terms, schedules or
repayments · crowdfarming · wallets or QR payment rails (survey vouchers are
single-use cash claims, not payments) · export or shipment tracking · buyer
self-service accounts · any AI surface.

Reference screens from the Ruaha Control Center and African Farmers Market
decks show several of these. **A screen existing does not put it in scope.**
Plan v2 controls scope.

---

## When unsure

Stop and ask. Do not guess at:

- a missing table or column — the gap is probably deliberate
- finance terms, interest, deposits or repayment — unresolved, and research
  item C (Bank of Tanzania Tier 2 classification) is open
- anything touching real farmer data, consent or registration — research items
  A and B are open and this build is demo-only
- Swahili wording that is not in the glossary — draft it from the glossary and
  flag it; do not invent a term silently
- a season, grade or confidence taxonomy — all still open under Plan v2 S22

A question costs minutes. A wrong assumption baked into the schema costs the
deadline.

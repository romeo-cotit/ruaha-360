import { execFileSync } from 'node:child_process'
import { readFileSync, existsSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, resolve } from 'node:path'

const here = dirname(fileURLToPath(import.meta.url))
const repoRoot = resolve(here, '../..')

function loadEnvFile(): Record<string, string> {
  const path = resolve(repoRoot, '.env')
  if (!existsSync(path)) return {}
  const out: Record<string, string> = {}
  for (const line of readFileSync(path, 'utf8').split('\n')) {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith('#')) continue
    const eq = trimmed.indexOf('=')
    if (eq === -1) continue
    out[trimmed.slice(0, eq).trim()] = trimmed.slice(eq + 1).trim().replace(/^["']|["']$/g, '')
  }
  return out
}

function connection(): { args: string[]; password: string } | null {
  const env = { ...loadEnvFile(), ...process.env }
  const host = env.SUPABASE_DB_HOST
  const port = env.SUPABASE_DB_PORT || '5432'
  const user = env.SUPABASE_DB_USER
  const password = env.SUPABASE_DB_PASSWORD
  if (!host || !user || !password) return null

  return {
    args: [`host=${host} port=${port} dbname=postgres user=${user} sslmode=require`],
    password,
  }
}

/**
 * Runs one statement as `postgres`, returning its output.
 *
 * For the few fixtures the APP CANNOT CREATE. A farmer has no route to a draft
 * request — the equipment form submits straight to `submitted` — so the only
 * draft in the system is seeded, and `app_verify` and the status machine are
 * one-way: submitting the seeded draft would consume it, and `cleanup.sql`
 * removes marked ROWS and cannot undo a column change on a seeded one.
 *
 * So a test that needs a draft creates its own, marked, and cleanup takes it
 * away again. Never use this to assert a result the app should be asked for.
 */
export function sql(statement: string): { ran: boolean; out: string; reason?: string } {
  const conn = connection()
  if (!conn) return { ran: false, out: '', reason: 'no SUPABASE_DB_* connection details' }

  try {
    // `-q` suppresses the command tag, so `returning id` yields the id alone
    // rather than the id followed by `INSERT 0 1`.
    const out = execFileSync(
      'psql',
      [...conn.args, '-v', 'ON_ERROR_STOP=1', '-q', '-At', '-c', statement],
      {
        env: { ...process.env, PGPASSWORD: conn.password, PGCONNECT_TIMEOUT: '20' },
        stdio: 'pipe',
      },
    )
    return { ran: true, out: out.toString().trim() }
  } catch (cause) {
    return { ran: false, out: '', reason: cause instanceof Error ? cause.message : String(cause) }
  }
}

/**
 * Account creation is outside the product UI. Give only a person registered by
 * this suite a temporary login, using the same GoTrue row shape as seed.sql.
 * The entire fixture is one transaction; cleanup removes it by both its
 * marked email and its link to the marked person.
 */
export function createSyntheticFarmerLogin(personId: string): { email: string; userId: string } {
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(personId)) {
    throw new Error('synthetic farmer fixture needs a valid person id')
  }

  const email = `e2e-journey-${personId}@demo.ruaha360.test`
  const result = sql(`
    begin;
    do $fixture$
    declare fixture_user uuid := gen_random_uuid();
    begin
      if not exists (select 1 from project where code like '%-DEMO')
         or exists (select 1 from project where code not like '%-DEMO') then
        raise exception 'refusing synthetic login: database is not demo-only';
      end if;
      if not exists (
        select 1 from person
        where id = '${personId}' and family_name like 'E2E-%'
          and village_id = '30000000-0000-4000-8000-000000000001'
      ) then
        raise exception 'synthetic login requires an E2E- Ilundo person';
      end if;
      if exists (select 1 from auth.users where email = '${email}') then
        raise exception 'synthetic login already exists';
      end if;

      insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, created_at, updated_at,
        raw_app_meta_data, raw_user_meta_data,
        confirmation_token, recovery_token, email_change_token_new, email_change
      ) values (
        '00000000-0000-0000-0000-000000000000', fixture_user,
        'authenticated', 'authenticated', '${email}',
        crypt('demo1234', gen_salt('bf')), now(), now(), now(),
        '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
        '', '', '', ''
      );

      insert into auth.identities (
        id, user_id, identity_data, provider, provider_id,
        last_sign_in_at, created_at, updated_at
      ) values (
        gen_random_uuid(), fixture_user,
        jsonb_build_object('sub', fixture_user::text, 'email', '${email}'),
        'email', fixture_user::text, now(), now(), now()
      );

      insert into app_user (id, person_id, display_name, locale)
        select fixture_user, id, given_name || ' ' || family_name, 'sw'
        from person where id = '${personId}';
      insert into membership (user_id, role, project_id, village_id)
        values (fixture_user, 'farmer',
          '20000000-0000-4000-8000-000000000001',
          '30000000-0000-4000-8000-000000000001');
    end $fixture$;
    commit;
    select id from app_user where person_id = '${personId}' and id in (
      select id from auth.users where email = '${email}'
    );
  `)

  if (!result.ran) throw new Error(`could not create synthetic farmer login: ${result.reason}`)
  if (!/^[0-9a-f-]{36}$/i.test(result.out)) {
    throw new Error(`synthetic farmer login returned an invalid user id: ${result.out}`)
  }
  return { email, userId: result.out }
}

/**
 * Deletes the records the browser suite created.
 *
 * Runs as `postgres`, which bypasses RLS: the schema has no DELETE policies by
 * design, so this cannot be done through the app's own client. Only rows
 * carrying the E2E- marker are matched, so seeded demo data is untouchable
 * from here.
 *
 * The suite setup treats missing credentials and cleanup failures as errors;
 * accepting either would make seeded-result assertions unreliable.
 */
export function cleanupE2eRecords(): { ran: boolean; reason?: string } {
  const env = { ...loadEnvFile(), ...process.env }
  const host = env.SUPABASE_DB_HOST
  const port = env.SUPABASE_DB_PORT || '5432'
  const user = env.SUPABASE_DB_USER
  const password = env.SUPABASE_DB_PASSWORD

  if (!host || !user || !password) {
    return { ran: false, reason: 'no SUPABASE_DB_* connection details' }
  }

  try {
    execFileSync(
      'psql',
      [
        `host=${host} port=${port} dbname=postgres user=${user} sslmode=require`,
        '-v',
        'ON_ERROR_STOP=1',
        '-q',
        '-f',
        resolve(here, 'cleanup.sql'),
      ],
      { env: { ...process.env, PGPASSWORD: password, PGCONNECT_TIMEOUT: '20' }, stdio: 'pipe' },
    )
    return { ran: true }
  } catch (cause) {
    const detail = cause instanceof Error ? cause.message : String(cause)
    return { ran: false, reason: detail }
  }
}

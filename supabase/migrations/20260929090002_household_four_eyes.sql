-- Ruaha 360 · four eyes on households
-- The officer who registered a household may not verify it. A household is
-- what a survey incentive is paid to, so one person must never be able to
-- create one and vouch for it alone. Other records keep the old rule.
--
-- Same body as the live definition (20260925090001), plus the household check.
-- Stays owned by ruaha_observed_writer.
create or replace function app_verify(p_table text, p_id uuid) returns void
language plpgsql security definer set search_path = pg_catalog, public, pg_temp as $$
declare
  v_status   verification_status;
  v_captured uuid;
begin
  if p_table not in ('person','household','farm','plot','crop_cycle','harvest_report') then
    raise exception 'not a verifiable table: %', p_table;
  end if;
  if not app_is_staff() then raise exception 'only field staff may verify records'; end if;
  execute format('select verification from public.%I where id = $1 and deleted_at is null for update', p_table)
    into v_status using p_id;
  if v_status is null then raise exception 'record not found or outside your villages'; end if;
  if v_status not in ('unverified','pending') then raise exception 'record is not awaiting verification'; end if;
  if p_table = 'household' then
    select captured_by into v_captured from public.household where id = p_id;
    if v_captured = public.app_actor_id() then
      raise exception 'a household must be verified by someone other than the officer who registered it';
    end if;
  end if;
  execute format('update public.%I set verification = ''verified'', verified_by = public.app_actor_id(), verified_at = now() where id = $1', p_table) using p_id;
end $$;

-- Ruaha 360 · plot title documents (staff only)
--
-- The officer photographs or scans the plot's title deed or other land
-- document at registration, so whoever verifies the plot can check its fields
-- against it. "Photo upload" is on the Do-not-build list; this is the one
-- exception, approved by the product owner on 5 Oct 2026, for this purpose
-- only:
--
--   * staff only — field officers, ops and admin of the plot's village.
--     Farmers have no access, to the rows or the files.
--   * a private bucket, images and PDFs, 10 MB a file.
--   * append-only: no update or delete for any client. A wrong upload is
--     superseded by a right one; the record of what was shown stays.
--   * demo images only. No real farmer documents in this build.
--
-- Files live at  plot-documents/{village_id}/{plot_id}/{uuid}-{file name}
-- so the storage policy can scope by village from the path alone.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('plot-documents', 'plot-documents', false, 10485760,
        array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'application/pdf'])
on conflict (id) do nothing;

create table plot_document (
  id           uuid primary key default gen_random_uuid(),
  plot_id      uuid not null,
  village_id   uuid not null,
  storage_path text not null unique,
  file_name    text not null check (length(btrim(file_name)) > 0),
  mime_type    text not null,
  size_bytes   bigint not null check (size_bytes > 0),
  uploaded_by  uuid not null default app_actor_id() references app_user(id),
  uploaded_at  timestamptz not null default now(),
  created_at   timestamptz not null default now(),

  constraint plot_document_plot_fk foreign key (plot_id, village_id)
    references plot (id, village_id),
  -- The row names the file it describes, in the plot's own folder.
  constraint plot_document_path_in_plot check (
    storage_path like village_id::text || '/' || plot_id::text || '/%')
);

create index plot_document_plot_idx on plot_document (plot_id);

comment on table plot_document is
  'Title deeds and land documents photographed at registration. Staff only, append-only. '
  'Exception to "no photo upload", approved 5 Oct 2026. Demo images only.';

create trigger plot_document_audit after insert or update or delete on plot_document
  for each row execute function write_audit();

alter table plot_document enable row level security;

-- Staff of the plot's village read and add; nobody updates or deletes.
create policy plot_document_read on plot_document for select to authenticated
  using (village_id in (select app_staff_villages()));
create policy plot_document_write on plot_document for insert to authenticated
  with check (village_id in (select app_staff_villages())
              and uploaded_by = app_actor_id());

revoke all on plot_document from anon;
revoke update, delete on plot_document from authenticated;
grant select, insert on plot_document to authenticated;

-- ── the files ──────────────────────────────────────────────
-- The first folder of the path is the village. Staff of that village may read
-- and add; there is no update or delete policy, so no one may.
create function app_plot_document_village(object_name text) returns uuid
language plpgsql immutable set search_path = pg_catalog as $$
begin
  return split_part(object_name, '/', 1)::uuid;
exception when others then
  return null;
end $$;

create policy plot_documents_read on storage.objects for select to authenticated
  using (bucket_id = 'plot-documents'
         and app_plot_document_village(name) in (select app_staff_villages()));
create policy plot_documents_write on storage.objects for insert to authenticated
  with check (bucket_id = 'plot-documents'
              and app_plot_document_village(name) in (select app_staff_villages()));

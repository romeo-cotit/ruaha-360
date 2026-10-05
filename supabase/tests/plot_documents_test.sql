-- ============================================================
-- Plot title documents — 20261005090003_plot_documents
-- Included by rls_test.sql. Every block is rolled back.
-- Seeded plot 1 is Neema's, in Ilundo.
-- ============================================================

\set ILU_PLOT '''a0000000-0000-4000-8000-000000000001'''
\set ILUNDO   '''30000000-0000-4000-8000-000000000001'''

-- the Ilundo officer files a document against an Ilundo plot
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :OFF_ILU)::text, true);
  set local role authenticated;

  insert into storage.objects (bucket_id, name)
  values ('plot-documents', :ILUNDO || '/' || :ILU_PLOT || '/f1-title.jpg');
  insert into plot_document (plot_id, village_id, storage_path, file_name, mime_type, size_bytes)
  values (:ILU_PLOT, :ILUNDO, :ILUNDO || '/' || :ILU_PLOT || '/f1-title.jpg', 'title.jpg', 'image/jpeg', 2048);

  select pg_temp.assert_eq((select count(*) from plot_document where plot_id = :ILU_PLOT and uploaded_by = :OFF_ILU), 1,
    'an officer files a title document against a plot in their village');
  select pg_temp.assert_eq((select count(*) from storage.objects
    where bucket_id = 'plot-documents' and name like :ILUNDO || '/%'), 1,
    'and can read the file back');

  -- who uploaded is the caller, never what the client claims
  select pg_temp.assert_raises($q$ insert into plot_document (plot_id, village_id, storage_path, file_name, mime_type, size_bytes, uploaded_by)
    values ('a0000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001',
            '30000000-0000-4000-8000-000000000001/a0000000-0000-4000-8000-000000000001/f2.jpg', 'f2.jpg', 'image/jpeg', 1,
            '80000000-0000-4000-8000-000000000004') $q$,
    'an upload cannot be attributed to someone else', '42501');

  -- a row must describe a file in its own plot's folder
  select pg_temp.assert_raises($q$ insert into plot_document (plot_id, village_id, storage_path, file_name, mime_type, size_bytes)
    values ('a0000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001',
            'elsewhere/f3.jpg', 'f3.jpg', 'image/jpeg', 1) $q$,
    'a document row cannot point outside its plot folder', '23514');

  -- append-only
  select pg_temp.assert_raises($q$ update plot_document set file_name = 'renamed.jpg' $q$,
    'a filed document cannot be renamed', '42501');
  select pg_temp.assert_raises($q$ delete from plot_document $q$,
    'a filed document cannot be deleted', '42501');
  -- Storage refuses direct SQL deletes; through its API, RLS decides, and no
  -- policy lets anyone update or delete a file in this bucket.
  select pg_temp.assert_eq((select count(*) from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and cmd in ('UPDATE', 'DELETE', 'ALL')
      and (coalesce(qual, '') || coalesce(with_check, '')) like '%plot-documents%'), 0,
    'no policy lets a filed file be replaced or deleted');

  -- the Mgama officer sees none of it, and cannot file into Ilundo
  select set_config('request.jwt.claims', json_build_object('sub', :OFF_MGA)::text, true);
  select pg_temp.assert_eq((select count(*) from plot_document), 0,
    'an officer outside the village sees no documents');
  select pg_temp.assert_eq((select count(*) from storage.objects where bucket_id = 'plot-documents'), 0,
    'an officer outside the village sees no files');
  select pg_temp.assert_raises($q$ insert into storage.objects (bucket_id, name)
    values ('plot-documents', '30000000-0000-4000-8000-000000000001/a0000000-0000-4000-8000-000000000001/x.jpg') $q$,
    'an officer outside the village cannot upload into it', '42501');

  -- the farmer whose plot it is sees nothing either: staff only
  select set_config('request.jwt.claims', json_build_object('sub', :FARM_NEE)::text, true);
  select pg_temp.assert_eq((select count(*) from plot_document), 0,
    'the farmer does not see title documents');
  select pg_temp.assert_eq((select count(*) from storage.objects where bucket_id = 'plot-documents'), 0,
    'the farmer does not see the files');
  select pg_temp.assert_raises($q$ insert into storage.objects (bucket_id, name)
    values ('plot-documents', '30000000-0000-4000-8000-000000000001/a0000000-0000-4000-8000-000000000001/y.jpg') $q$,
    'a farmer cannot upload a document', '42501');

  -- ops sees across its project
  select set_config('request.jwt.claims', json_build_object('sub', :OPS)::text, true);
  select pg_temp.assert_eq((select count(*) from plot_document where plot_id = :ILU_PLOT), 1,
    'ops sees the document');
rollback;

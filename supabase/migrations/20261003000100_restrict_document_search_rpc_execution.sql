-- Document retrieval is only meaningful for an authenticated organisation member.
-- The function remains SECURITY INVOKER, so its underlying table RLS remains active.
revoke execute on function public.search_scoped_document_chunks(uuid, uuid[], vector, integer, real) from public;
revoke execute on function public.search_scoped_document_chunks(uuid, uuid[], vector, integer, real) from anon;
grant execute on function public.search_scoped_document_chunks(uuid, uuid[], vector, integer, real) to authenticated;

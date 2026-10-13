create or replace function public.search_scoped_document_chunks(
  p_organisation_id uuid, p_document_ids uuid[], p_query_embedding extensions.vector(1536), p_match_count integer default 8, p_similarity_threshold real default 0.65
)
returns table(document_id uuid, document_title text, page integer, chunk_index integer, content text, similarity real)
language sql stable security invoker set search_path = public, extensions
as $$
  select d.id, d.title, c.source_page, c.chunk_index, c.content, (1 - (c.embedding <=> p_query_embedding))::real
  from public.document_chunks c join public.document_versions v on v.id=c.document_version_id and v.organisation_id=p_organisation_id
  join public.documents d on d.id=v.document_id and d.organisation_id=p_organisation_id
  where c.organisation_id=p_organisation_id and d.id=any(p_document_ids) and d.status <> 'archived' and d.intelligence_status='ready' and c.embedding is not null
    and (1 - (c.embedding <=> p_query_embedding)) >= p_similarity_threshold
  order by c.embedding <=> p_query_embedding limit greatest(1, least(p_match_count, 50));
$$;
revoke all on function public.search_scoped_document_chunks(uuid, uuid[], extensions.vector(1536), integer, real) from public;
grant execute on function public.search_scoped_document_chunks(uuid, uuid[], extensions.vector(1536), integer, real) to authenticated;

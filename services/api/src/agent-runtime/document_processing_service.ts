import { CloudflareMarkdownDocumentExtractor, createChunks } from './document_pipeline';
import { GeminiEmbeddingProvider } from './embedding_provider';
import { SupabaseRuntimeRepository } from './supabase_repository';
import { RequestContext } from './types';

export async function processDocument(repo: SupabaseRuntimeRepository, context: RequestContext, documentId: string, env: { AI?: any; EMBEDDING_API_KEY?: string; EMBEDDING_MODEL?: string }): Promise<{ status: string; error?: string; chunks?: number }> {
  const docs = await repo.list('documents', context.organisationId, { id: documentId }); const doc: any = docs[0];
  if (!doc) throw new Error('Document not found.');
  await repo.update('documents', context.organisationId, documentId, { intelligence_status: 'processing', intelligence_error: null });
  try {
    const mime = String(doc.mime_type ?? doc.content_type ?? ''); const name = String(doc.filename ?? doc.file_name ?? doc.title ?? 'document');
    if (/png|jpe?g|gif|webp/i.test(`${mime} ${name}`)) { await repo.update('documents', context.organisationId, documentId, { intelligence_status: 'requires_ocr' }); return { status: 'requires_ocr' }; }
    if (!env.AI) throw new Error('DOCUMENT_CONVERTER_NOT_CONFIGURED');
    if (!env.EMBEDDING_API_KEY) throw new Error('EMBEDDING_PROVIDER_NOT_CONFIGURED');
    const versions = await repo.list('document_versions', context.organisationId, { document_id: documentId }); const version: any = versions.sort((a: any, b: any) => b.version_number - a.version_number)[0];
    if (!version) throw new Error('Current document version is missing.');
    const bytes = await repo.downloadStorage(String(doc.storage_path));
    const extracted = await new CloudflareMarkdownDocumentExtractor(env.AI).extract(bytes, name, mime);
    if (extracted.status !== 'ready') throw new Error(extracted.error ?? 'Document conversion failed.');
    const chunks = createChunks(documentId, version.id, extracted.sections);
    if (!chunks.length) throw new Error('Document conversion returned no searchable content.');
    const embedder = new GeminiEmbeddingProvider(env.EMBEDDING_API_KEY, env.EMBEDDING_MODEL ?? 'gemini-embedding-2', 1536);
    const vectors = []; for (const chunk of chunks) vectors.push(await embedder.embed(chunk.content));
    await repo.removeChunks(context.organisationId, version.id);
    for (let i = 0; i < chunks.length; i++) await repo.insert('document_chunks', context.organisationId, { document_version_id: version.id, chunk_index: i, content: chunks[i].content, source_page: chunks[i].page ?? null, embedding: `[${vectors[i].join(',')}]`, embedding_model: embedder.model });
    await repo.update('documents', context.organisationId, documentId, { intelligence_status: 'ready', intelligence_error: null });
    return { status: 'ready', chunks: chunks.length };
  } catch (error) { const safe = error instanceof Error && /CONFIGURED|missing|no searchable/i.test(error.message) ? error.message : 'Document processing failed.'; await repo.update('documents', context.organisationId, documentId, { intelligence_status: safe === 'DOCUMENT_CONVERTER_NOT_CONFIGURED' || safe === 'EMBEDDING_PROVIDER_NOT_CONFIGURED' ? 'failed' : 'failed', intelligence_error: safe }); return { status: 'failed', error: safe }; }
}

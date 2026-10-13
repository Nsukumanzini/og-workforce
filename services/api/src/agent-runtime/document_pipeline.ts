export type DocumentIntelligenceStatus = 'uploaded'|'queued'|'processing'|'ready'|'failed'|'unsupported'|'requires_ocr';
export interface DocumentSection { content: string; page?: number; sheet?: string; heading?: string; }
export interface ExtractedDocument { text: string; sections: DocumentSection[]; status: DocumentIntelligenceStatus; error?: string; }
export interface DocumentExtractor { supports(mimeType: string, filename: string): boolean; extract(bytes: Uint8Array, filename: string, mimeType: string): Promise<ExtractedDocument>; }
export interface MarkdownConversionBinding { toMarkdown(input: Blob | ArrayBuffer | Uint8Array, options?: Record<string, unknown>): Promise<unknown>; }
export class CloudflareMarkdownDocumentExtractor implements DocumentExtractor {
  constructor(private readonly ai: MarkdownConversionBinding) {}
  supports(mime: string, name: string) { return /pdf|word|officedocument|excel|spreadsheet/i.test(`${mime} ${name}`); }
  async extract(bytes: Uint8Array, filename: string, mime: string): Promise<ExtractedDocument> {
    try {
      const copy = new Uint8Array(bytes.byteLength); copy.set(bytes);
      const result = await this.ai.toMarkdown(new Blob([copy.buffer], { type: mime }), { output: 'markdown' }) as any;
      const markdown = typeof result === 'string' ? result : result?.markdown ?? result?.text;
      if (!markdown || typeof markdown !== 'string') return { text: '', sections: [], status: 'failed', error: 'Document conversion returned no text.' };
      const sections = markdown.split(/\n(?=#{1,6}\s)/).map((content) => ({ content: content.trim() })).filter((section) => section.content);
      return { text: markdown, sections, status: 'ready' };
    } catch { return { text: '', sections: [], status: 'failed', error: `Document conversion failed for ${filename}.` }; }
  }
}
export class ConservativeExtractor implements DocumentExtractor {
  supports(mime: string, name: string) { return /pdf|word|excel|spreadsheet|png|jpe?g/i.test(`${mime} ${name}`); }
  async extract(_bytes: Uint8Array, filename: string, mime: string): Promise<ExtractedDocument> {
    if (/png|jpe?g|gif|webp/i.test(mime)) return { text: '', sections: [], status: 'requires_ocr', error: 'OCR is required for image documents.' };
    return { text: '', sections: [], status: 'unsupported', error: `No Worker-compatible extractor is configured for ${filename} (${mime}).` };
  }
}
export function chunkText(text: string, size = 1200, overlap = 150): string[] { if (size <= overlap) throw new Error('Chunk overlap must be smaller than chunk size'); const chunks: string[] = []; for (let start = 0; start < text.length; start += size - overlap) chunks.push(text.slice(start, start + size)); return chunks; }
export function normalizeText(text: string): string { return text.replace(/\r\n?/g, '\n').replace(/[ \t]+/g, ' ').replace(/\n{3,}/g, '\n\n').trim(); }
export interface DocumentChunk { content: string; chunkIndex: number; page?: number; sheet?: string; metadata: Record<string, string | number>; }
export function createChunks(documentId: string, versionId: string, sections: DocumentSection[], size = 1200): DocumentChunk[] {
  const output: DocumentChunk[] = [];
  sections.forEach((section) => chunkText(normalizeText(section.content), size).forEach((content) => {
    const chunkIndex = output.length;
    output.push({ content, chunkIndex, page: section.page, sheet: section.sheet, metadata: { document_id: documentId, version_id: versionId, ...(section.page ? { page: section.page } : {}), ...(section.sheet ? { sheet: section.sheet } : {}), ...(section.heading ? { heading: section.heading } : {}) } });
  }));
  return output;
}

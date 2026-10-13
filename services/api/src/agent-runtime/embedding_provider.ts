import { EmbeddingProvider } from './types';

export class ConfiguredEmbeddingProvider implements EmbeddingProvider {
  constructor(public readonly model: string, public readonly dimensions = 1536, private readonly embedder?: (text: string) => Promise<number[]>) {}
  async embed(text: string): Promise<number[]> { if (!this.embedder) throw new Error('Embedding provider credentials are not configured.'); const vector = await this.embedder(text); if (vector.length !== this.dimensions) throw new Error(`Embedding dimension mismatch: expected ${this.dimensions}.`); return vector; }
}

export class GeminiEmbeddingProvider implements EmbeddingProvider {
  constructor(private readonly apiKey: string, public readonly model = 'gemini-embedding-2', public readonly dimensions = 1536) {}
  async embed(text: string): Promise<number[]> {
    if (!this.apiKey) throw new Error('Gemini embedding credentials are not configured.');
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(this.model)}:embedContent?key=${encodeURIComponent(this.apiKey)}`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ model: `models/${this.model}`, content: { parts: [{ text }] }, output_dimensionality: this.dimensions }) });
    if (!response.ok) throw new Error('Gemini embedding request failed.');
    const payload = await response.json() as { embedding?: { values?: number[] } };
    const vector = payload.embedding?.values ?? [];
    if (vector.length !== this.dimensions) throw new Error(`Embedding dimension mismatch: expected ${this.dimensions}.`);
    return vector;
  }
}

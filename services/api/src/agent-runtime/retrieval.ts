import { EvidenceSource, classifyEvidence } from './confidence_gate';
import { BusinessBrainReader } from './business_assistant_tools';
import { RequestContext } from './types';

export type RetrievalMode = 'structured' | 'document' | 'hybrid';
export interface RetrievalResult { mode: RetrievalMode; data: unknown[]; sources: EvidenceSource[]; }
export function routeQuestion(question: string): RetrievalMode { return /pdf|document|file|company profile/i.test(question) ? 'hybrid' : 'structured'; }
export async function retrieveStructured(reader: BusinessBrainReader, context: RequestContext, tables: string[]): Promise<RetrievalResult> {
  const data: unknown[] = []; for (const table of tables) data.push(...await reader.list(table, context.organisationId));
  return { mode: 'structured', data, sources: tables.map((table) => ({ type: table, id: table, label: table })) };
}
export function retrievalEvidence(result: RetrievalResult) { return classifyEvidence(result.sources, result.mode === 'structured'); }

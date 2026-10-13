export type EvidenceLevel = 'high' | 'medium' | 'low';
export interface EvidenceSource { type: string; id: string; label: string; page?: number; }
export interface EvidenceResult { level: EvidenceLevel; sources: EvidenceSource[]; }
export function classifyEvidence(sources: EvidenceSource[], structured: boolean): EvidenceResult {
  if (structured && sources.length > 0) return { level: 'high', sources };
  if (sources.length > 0) return { level: 'medium', sources };
  return { level: 'low', sources: [] };
}
export function evidenceFallback(level: EvidenceLevel): string { return level === 'low' ? "I don't have an approved answer for that in the Business Brain." : "I found partial information, but it needs confirmation before I can give a definitive answer."; }

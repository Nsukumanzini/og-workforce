export const TENDER_DECISIONS = ['no_action','shortlist','not_suitable','request_information','prepare_workspace','prepare_draft','request_approval','escalate','failure'] as const;
export type TenderDecision = typeof TENDER_DECISIONS[number];
export type TenderDecisionResult = { decision: TenderDecision; confidence: number; reason: string; missingInformation: string[]; workspaceStatus?: string; draft?: string };
export function parseTenderDecision(value: unknown): TenderDecisionResult {
  const input = (value && typeof value === 'object' ? value : {}) as Record<string, unknown>;
  const decision = TENDER_DECISIONS.includes(input.decision as TenderDecision) ? input.decision as TenderDecision : 'failure';
  const confidence = Math.max(0, Math.min(1, Number(input.confidence ?? 0)));
  return { decision, confidence, reason: String(input.reason ?? 'No reason supplied.').slice(0, 1000), missingInformation: Array.isArray(input.missingInformation) ? input.missingInformation.map(String).slice(0, 30) : [], workspaceStatus: typeof input.workspaceStatus === 'string' ? input.workspaceStatus : undefined, draft: typeof input.draft === 'string' ? input.draft.slice(0, 20000) : undefined };
}
export function tenderDeadlineState(closingAt?: string | null): 'open'|'closing_soon'|'closed'|'unknown' { if (!closingAt) return 'unknown'; const ms = Date.parse(closingAt); if (!Number.isFinite(ms)) return 'unknown'; if (ms <= Date.now()) return 'closed'; return ms - Date.now() < 7 * 86400000 ? 'closing_soon' : 'open'; }

import { gatherTenderEvidence, type TenderRequirementEvidence } from './tender_evidence';
import type { SupabaseRuntimeRepository } from './supabase_repository';

type DraftMode = 'initial' | 'regenerate';
type GenerateTenderDraftArgs = {
  repo: SupabaseRuntimeRepository;
  env: any;
  organisationId: string;
  workspace: any;
  opportunity: any;
  requirements: any[];
  draftType: string;
  requirementId?: string | null;
  mode: DraftMode;
};

const selectedEvidence = (draftType: string, requirementId: string | null | undefined, evidence: TenderRequirementEvidence[]) => {
  if (requirementId) return evidence.filter((item) => item.requirementId === requirementId);
  if (draftType === 'company_introduction') return evidence.filter((item) =>
    ['company_identity', 'capability', 'documentary_evidence'].includes(item.classification));
  if (draftType === 'methodology') return evidence.filter((item) =>
    ['policy_process', 'capability', 'documentary_evidence'].includes(item.classification));
  if (draftType === 'clarification_questions') return evidence.filter((item) => item.humanInputRequired || item.missingEvidence.length > 0);
  return evidence.filter((item) => ['capability', 'documentary_evidence', 'other'].includes(item.classification));
};

const evidenceSummary = (item: TenderRequirementEvidence) => {
  const sources = item.structuredEvidence.filter((source) => source.count > 0)
    .map((source) => `${source.source}: ${source.labels.join(', ') || `${source.count} record(s)`}`);
  const tender = item.tenderDocumentEvidence.map((source) => source.document_title ?? 'Tender document');
  const business = item.businessBrainDocumentEvidence.map((source) => source.document_title ?? 'Business Brain document');
  return { sources, tender, business };
};

export async function generateTenderDraft(args: GenerateTenderDraftArgs) {
  const allEvidence = await gatherTenderEvidence(
    args.repo, args.env, args.organisationId, args.workspace.id, args.opportunity, args.requirements,
  );
  const relevant = selectedEvidence(args.draftType, args.requirementId, allEvidence);
  const humanInput = relevant.filter((item) => item.humanInputRequired || item.missingEvidence.length > 0);
  const lines = [
    `${args.draftType.replaceAll('_', ' ')} draft`,
    '',
    `Tender: ${args.opportunity?.title ?? 'Untitled tender'}`,
    `Reference: ${args.opportunity?.reference ?? 'Not provided'}`,
    `Buyer: ${args.opportunity?.buyer ?? 'Not provided'}`,
    '',
    'TENDER FACTS',
    ...(relevant.length
      ? relevant.map((item) => `• ${item.requirementText}`).slice(0, 12)
      : ['• No matching tender requirement was supplied.']),
    '',
    'ORGANISATION FACTS',
    ...relevant.flatMap((item) => evidenceSummary(item).sources.map((source) => `• ${source}`)).slice(0, 16),
    ...relevant.flatMap((item) => evidenceSummary(item).business.map((source) => `• Business document: ${source}`)).slice(0, 8),
    '',
    'TENDER DOCUMENT EVIDENCE',
    ...relevant.flatMap((item) => evidenceSummary(item).tender.map((source) => `• Tender document: ${source}`)).slice(0, 8),
    '',
    'MISSING / UNCLEAR',
    ...(humanInput.length
      ? humanInput.map((item) => `Human input required: provide evidence for ${item.requirementText}`).slice(0, 12)
      : ['No unresolved evidence gaps were identified from the current source set.']),
    '',
    'Draft for internal review only. Do not submit externally.',
  ];
  const used = relevant.flatMap((item) => [
    { requirement_id: item.requirementId, classification: item.classification },
    ...item.structuredEvidence.filter((source) => source.count > 0).map((source) => ({ requirement_id: item.requirementId, structured_source: source.source })),
    ...item.tenderDocumentEvidence.map((source) => ({ requirement_id: item.requirementId, tender_document_id: source.document_id })),
    ...item.businessBrainDocumentEvidence.map((source) => ({ requirement_id: item.requirementId, business_document_id: source.document_id })),
  ]);
  return {
    content: lines.join('\n'),
    humanInputRequired: humanInput.length > 0,
    provenance: used,
    evidence: relevant,
    mode: args.mode,
  };
}

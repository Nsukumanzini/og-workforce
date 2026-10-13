import { GeminiEmbeddingProvider } from './embedding_provider';
import type { SupabaseRuntimeRepository } from './supabase_repository';

export type TenderRequirementClass =
  | 'company_identity' | 'capability' | 'location' | 'organisation_capacity'
  | 'policy_process' | 'commercial' | 'language' | 'documentary_evidence' | 'other';

export type TenderRequirementEvidence = {
  requirementId: string;
  requirementText: string;
  mandatory: boolean;
  classification: TenderRequirementClass;
  structuredEvidence: Array<{ source: string; count: number; labels: string[] }>;
  tenderDocumentEvidence: any[];
  businessBrainDocumentEvidence: any[];
  missingEvidence: string[];
  humanInputRequired: boolean;
};

export function classifyTenderRequirement(text: string): TenderRequirementClass {
  const value = text.toLowerCase();
  if (/location|province|municipal|site|geographic/.test(value)) return 'location';
  if (/policy|procedure|methodology|quality management/.test(value)) return 'policy_process';
  if (/price|pricing|commercial|cost|rate/.test(value)) return 'commercial';
  if (/language|multilingual/.test(value)) return 'language';
  if (/department|team|staff|capacity/.test(value)) return 'organisation_capacity';
  if (/certificate|certification|evidence|document|reference/.test(value)) return 'documentary_evidence';
  if (/registration|legal|company profile|identity/.test(value)) return 'company_identity';
  if (/service|product|capability|experience/.test(value)) return 'capability';
  return 'other';
}

const labelFor = (record: any) => String(
  record.name ?? record.title ?? record.display_name ?? record.legal_name ??
  record.location_name ?? record.language ?? record.code ?? 'Recorded item',
).slice(0, 160);

export async function gatherTenderEvidence(
  repo: SupabaseRuntimeRepository,
  env: any,
  organisationId: string,
  workspaceId: string,
  opportunity: any,
  requirements: any[],
): Promise<TenderRequirementEvidence[]> {
  const classifications = requirements.slice(0, 20).map((requirement) => ({
    requirement,
    classification: classifyTenderRequirement(String(requirement.requirement_text ?? '')),
  }));
  const needed = new Set(classifications.map((item) => item.classification));
  const fetch = (table: string, required: boolean, filters?: Record<string, string>) =>
    required ? repo.list(table, organisationId, filters) : Promise.resolve([] as any[]);
  const [tenderDocuments, profiles, services, products, locations, departments, contacts, policies, packages, pricingRules, languages] = await Promise.all([
    repo.list('tender_documents', organisationId, { workspace_id: workspaceId }),
    repo.list('business_profiles', organisationId),
    fetch('services', needed.has('capability') || needed.has('other')),
    fetch('products', needed.has('capability') || needed.has('other')),
    fetch('business_locations', needed.has('location')),
    fetch('departments', needed.has('organisation_capacity')),
    fetch('business_contacts', needed.has('organisation_capacity')),
    fetch('knowledge_entries', needed.has('policy_process'), { entry_type: 'policy' }),
    fetch('packages', needed.has('commercial')),
    fetch('pricing_rules', needed.has('commercial')),
    fetch('organisation_languages', needed.has('language')),
  ]);
  const structured: Record<string, any[]> = {
    profile: profiles,
    services,
    products,
    locations,
    departments,
    contacts,
    policies,
    packages,
    pricing_rules: pricingRules,
    organisation_languages: languages,
  };
  const tenderDocumentIds = tenderDocuments.map((item: any) => item.document_id).filter(Boolean);
  const embedder = env.EMBEDDING_API_KEY
    ? new GeminiEmbeddingProvider(env.EMBEDDING_API_KEY, env.EMBEDDING_MODEL ?? 'gemini-embedding-2', 1536)
    : null;
  const sourcesFor = (classification: TenderRequirementClass) => {
    if (classification === 'capability' || classification === 'other') return ['profile', 'services', 'products'];
    if (classification === 'location') return ['profile', 'locations'];
    if (classification === 'organisation_capacity') return ['profile', 'departments', 'contacts'];
    if (classification === 'policy_process') return ['profile', 'policies', 'services'];
    if (classification === 'commercial') return ['profile', 'packages', 'pricing_rules'];
    if (classification === 'language') return ['profile', 'organisation_languages'];
    return ['profile'];
  };

  return Promise.all(classifications.map(async ({ requirement, classification }) => {
    const sourceNames = sourcesFor(classification);
    const structuredEvidence = sourceNames.map((source) => {
      const records = structured[source] ?? [];
      return { source, count: records.length, labels: records.slice(0, 4).map(labelFor) };
    });
    let tenderDocumentEvidence: any[] = [];
    let businessBrainDocumentEvidence: any[] = [];
    if (embedder) {
      const vector = await embedder.embed(`${requirement.requirement_text ?? ''} ${opportunity?.title ?? ''} ${opportunity?.description ?? ''}`);
      tenderDocumentEvidence = (await repo.searchScopedDocumentChunks(organisationId, tenderDocumentIds, vector, 4, .65))
        .map((item) => ({ ...item, source_class: 'tender_document', requirement_id: requirement.id }));
      businessBrainDocumentEvidence = (await repo.searchBusinessDocumentChunks(organisationId, vector, 4, .65))
        .map((item) => ({ ...item, source_class: 'business_brain_document', requirement_id: requirement.id }));
    }
    const hasEvidence = structuredEvidence.some((item) => item.count > 0)
      || tenderDocumentEvidence.length > 0 || businessBrainDocumentEvidence.length > 0;
    return {
      requirementId: requirement.id,
      requirementText: requirement.requirement_text,
      mandatory: requirement.mandatory === true,
      classification,
      structuredEvidence,
      tenderDocumentEvidence,
      businessBrainDocumentEvidence,
      missingEvidence: hasEvidence ? [] : ['No supporting evidence found.'],
      humanInputRequired: !hasEvidence,
    };
  }));
}

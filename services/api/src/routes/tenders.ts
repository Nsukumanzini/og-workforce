import { Hono } from 'hono';
import { AppEnv, ApiError } from '../api_types';
import { authMiddleware } from '../middleware/auth';
import { ManualTenderSourceProvider } from '../agent-runtime/tender_source';
import { runTenderAgent } from '../agent-runtime/tender_dispatcher';
import { processDocument } from '../agent-runtime/document_processing_service';
import { gatherTenderEvidence } from '../agent-runtime/tender_evidence';
import { generateTenderDraft } from '../agent-runtime/tender_draft_generation';

export const tenderRoutes = new Hono<AppEnv>();
tenderRoutes.use('*', authMiddleware);

async function ensureTenderAgent(r: any, organisationId: string) {
  const existing = await r.list('agents', organisationId, { agent_type_key: 'tender_agent' });
  return existing[0] ?? r.insert('agents', organisationId, {
    agent_type_key: 'tender_agent', display_name: 'Tender Agent', status: 'active', config: { source_mode: 'manual' },
  });
}
async function workspaceContext(r: any, organisationId: string, id: string) {
  const workspace = (await r.list('tender_workspaces', organisationId, { id }))[0];
  if (!workspace) throw new ApiError('NOT_FOUND', 'Tender workspace not found.');
  const [opportunity, requirements] = await Promise.all([
    r.list('tender_opportunities', organisationId, { id: workspace.opportunity_id }),
    r.list('tender_requirements', organisationId, { workspace_id: id }),
  ]);
  return { workspace, opportunity: opportunity[0], requirements };
}
async function workspaceApprovals(r: any, organisationId: string, workspaceId: string) {
  const actions = (await r.list('agent_actions', organisationId)).filter((action: any) =>
    action.input_payload?.workspace_id === workspaceId && action.tool_key === 'requestTenderApproval');
  if (!actions.length) return [];
  const approvals = await r.list('approvals', organisationId);
  return actions.map((action: any) => {
    const approval = approvals.find((item: any) => item.agent_action_id === action.id);
    return approval ? {
      id: approval.id, status: approval.status, requested_at: approval.created_at,
      action: { id: action.id, status: action.status, tool_key: action.tool_key, draft_id: action.input_payload?.draft_id ?? null },
    } : null;
  }).filter(Boolean);
}

tenderRoutes.get('/tenders/opportunities', async (c) => {
  const x = c.get('agentContext'); const r = c.get('runtimeRepository');
  const status = c.req.query('status'); const source = c.req.query('source');
  const q = (c.req.query('q') ?? c.req.query('search') ?? '').toLowerCase();
  let opportunities = await r.list('tender_opportunities', x.organisationId, status ? { status } : undefined);
  if (source) opportunities = opportunities.filter((item: any) => item.source_provider === source);
  if (q) opportunities = opportunities.filter((item: any) => `${item.reference ?? ''} ${item.title} ${item.buyer ?? ''}`.toLowerCase().includes(q));
  return c.json({ opportunities });
});
tenderRoutes.get('/tenders/summary', async (c) => {
  const x = c.get('agentContext'); const r = c.get('runtimeRepository');
  const workspaces = await r.list('tender_workspaces', x.organisationId); const opportunities = await r.list('tender_opportunities', x.organisationId);
  const byId = new Map(opportunities.map((item: any) => [item.id, item])); const now = Date.now();
  const counts: any = { discovered: 0, shortlisted: 0, preparing: 0, awaiting_information: 0, awaiting_approval: 0, due_soon: 0, expired: 0 };
  for (const workspace of workspaces) { if (counts[workspace.status] !== undefined) counts[workspace.status]++; const close = byId.get(workspace.opportunity_id)?.closing_at; if (close) { const when = Date.parse(close); if (when <= now) counts.expired++; else if (when - now < 604800000) counts.due_soon++; } }
  return c.json({ counts });
});
tenderRoutes.post('/tenders/opportunities', async (c) => { const x = c.get('agentContext'); const body = await c.req.json<any>(); if (!body.title) throw new ApiError('VALIDATION_ERROR', 'Tender title is required.'); return c.json({ opportunity: await new ManualTenderSourceProvider(c.get('runtimeRepository')).persist(x.organisationId, body) }, 201); });
tenderRoutes.get('/tenders/opportunities/:id', async (c) => {
  const x = c.get('agentContext'); const r = c.get('runtimeRepository'); const opportunity = (await r.list('tender_opportunities', x.organisationId, { id: c.req.param('id') }))[0];
  if (!opportunity) throw new ApiError('NOT_FOUND', 'Tender opportunity not found.'); const workspace = (await r.list('tender_workspaces', x.organisationId, { opportunity_id: opportunity.id }))[0];
  const data = workspace ? await workspaceContext(r, x.organisationId, workspace.id) : null;
  return c.json({ opportunity, workspace: workspace ?? null, requirements: data?.requirements ?? [], documents: workspace ? await r.list('tender_documents', x.organisationId, { workspace_id: workspace.id }) : [], drafts: workspace ? await r.list('tender_drafts', x.organisationId, { workspace_id: workspace.id }) : [], missingInformation: workspace ? await r.list('tender_missing_information', x.organisationId, { workspace_id: workspace.id }) : [] });
});
tenderRoutes.get('/tenders/workspaces/:id', async (c) => {
  const x = c.get('agentContext'); const r = c.get('runtimeRepository'); const data = await workspaceContext(r, x.organisationId, c.req.param('id'));
  return c.json({ ...data, documents: await r.list('tender_documents', x.organisationId, { workspace_id: data.workspace.id }), drafts: await r.list('tender_drafts', x.organisationId, { workspace_id: data.workspace.id }), missingInformation: await r.list('tender_missing_information', x.organisationId, { workspace_id: data.workspace.id }), approvals: await workspaceApprovals(r, x.organisationId, data.workspace.id) });
});
tenderRoutes.get('/tenders/workspaces/:id/evidence', async (c) => { const x = c.get('agentContext'); const data = await workspaceContext(c.get('runtimeRepository'), x.organisationId, c.req.param('id')); return c.json({ evidence: await gatherTenderEvidence(c.get('runtimeRepository'), c.env, x.organisationId, data.workspace.id, data.opportunity, data.requirements) }); });
tenderRoutes.post('/tenders/workspaces', async (c) => { const x = c.get('agentContext'); const r = c.get('runtimeRepository'); const body = await c.req.json<any>(); if (!body.opportunity_id) throw new ApiError('VALIDATION_ERROR', 'Opportunity is required.'); const existing = (await r.list('tender_workspaces', x.organisationId, { opportunity_id: body.opportunity_id }))[0]; return c.json({ workspace: existing ?? await r.insert('tender_workspaces', x.organisationId, { opportunity_id: body.opportunity_id, status: 'preparing', eligibility_status: 'unclear', match_reasons: [], missing_requirements: [], deadline_snapshot: {} }) }, existing ? 200 : 201); });
tenderRoutes.patch('/tenders/requirements/:id', async (c) => { const x = c.get('agentContext'); const body = await c.req.json<any>(); if (!['satisfied', 'missing', 'unclear', 'not_applicable'].includes(body.status)) throw new ApiError('VALIDATION_ERROR', 'Invalid requirement status.'); return c.json({ requirement: await c.get('runtimeRepository').update('tender_requirements', x.organisationId, c.req.param('id'), { status: body.status, notes: String(body.notes ?? '').slice(0, 1000), evidence_source: String(body.evidence_source ?? '').slice(0, 500) }) }); });
tenderRoutes.post('/tenders/workspaces/:id/missing-information', async (c) => { const x = c.get('agentContext'); const body = await c.req.json<any>(); if (!body.question) throw new ApiError('VALIDATION_ERROR', 'A question is required.'); return c.json({ item: await c.get('runtimeRepository').insert('tender_missing_information', x.organisationId, { workspace_id: c.req.param('id'), question: String(body.question).slice(0, 1000), reason: String(body.reason ?? '').slice(0, 1000), requested_from: body.requested_from ?? null, status: 'open' }) }, 201); });
tenderRoutes.patch('/tenders/missing-information/:id', async (c) => { const x = c.get('agentContext'); const r = c.get('runtimeRepository'); const body = await c.req.json<any>(); const item = (await r.list('tender_missing_information', x.organisationId, { id: c.req.param('id') }))[0]; if (!item) throw new ApiError('NOT_FOUND', 'Missing-information item not found.'); return c.json({ item: await r.update('tender_missing_information', x.organisationId, item.id, { status: body.status ?? item.status, reason: String(body.reason ?? item.reason ?? '').slice(0, 1000) }) }); });
tenderRoutes.post('/tenders/workspaces/:id/drafts/generate', async (c) => { const x = c.get('agentContext'); const r = c.get('runtimeRepository'); const body = await c.req.json<any>(); const data = await workspaceContext(r, x.organisationId, c.req.param('id')); const generated = await generateTenderDraft({ repo: r, env: c.env, organisationId: x.organisationId, ...data, draftType: body.draft_type ?? 'capability_response', requirementId: body.requirement_id ?? null, mode: 'initial' }); const draft = await r.insert('tender_drafts', x.organisationId, { workspace_id: data.workspace.id, draft_type: body.draft_type ?? 'capability_response', content: generated.content, grounded_sources: generated.provenance, status: 'draft' }); await r.insert('audit_logs', x.organisationId, { actor_user_id: x.userId, event_type: 'tender_draft_generated', entity_type: 'tender_draft', entity_id: draft.id, metadata: { workspace_id: data.workspace.id, human_input_required: generated.humanInputRequired, source_count: generated.provenance.length } }); return c.json({ draft, human_input_required: generated.humanInputRequired, provenance: generated.provenance }, 201); });
tenderRoutes.patch('/tenders/drafts/:id', async (c) => { const x = c.get('agentContext'); const r = c.get('runtimeRepository'); const body = await c.req.json<any>(); const draft = (await r.list('tender_drafts', x.organisationId, { id: c.req.param('id') }))[0]; if (!draft || !String(body.content ?? '').trim()) throw new ApiError('VALIDATION_ERROR', 'Draft content is required.'); return c.json({ draft: await r.update('tender_drafts', x.organisationId, draft.id, { content: String(body.content).slice(0, 50000), status: 'draft', updated_at: new Date().toISOString() }) }); });
tenderRoutes.post('/tenders/drafts/:id/regenerate', async (c) => { const x = c.get('agentContext'); const r = c.get('runtimeRepository'); const body = await c.req.json<any>(); if (body.confirm !== true) throw new ApiError('VALIDATION_ERROR', 'Explicit regeneration confirmation is required.'); const draft = (await r.list('tender_drafts', x.organisationId, { id: c.req.param('id') }))[0]; if (!draft) throw new ApiError('NOT_FOUND', 'Draft not found.'); const data = await workspaceContext(r, x.organisationId, draft.workspace_id); const generated = await generateTenderDraft({ repo: r, env: c.env, organisationId: x.organisationId, ...data, draftType: draft.draft_type, mode: 'regenerate' }); const updated = await r.update('tender_drafts', x.organisationId, draft.id, { content: generated.content, grounded_sources: generated.provenance, status: 'draft', updated_at: new Date().toISOString() }); await r.insert('audit_logs', x.organisationId, { actor_user_id: x.userId, event_type: 'tender_draft_regenerated', entity_type: 'tender_draft', entity_id: draft.id, metadata: { explicit_confirmation: true, human_input_required: generated.humanInputRequired } }); return c.json({ draft: updated, human_input_required: generated.humanInputRequired, provenance: generated.provenance }); });
tenderRoutes.post('/tenders/drafts/:id/request-approval', async (c) => {
  const x = c.get('agentContext'); const r = c.get('runtimeRepository');
  const draft = (await r.list('tender_drafts', x.organisationId, { id: c.req.param('id') }))[0];
  if (!draft) throw new ApiError('NOT_FOUND', 'Tender draft not found.');
  const existingActions: any[] = await r.list('agent_actions', x.organisationId);
  const previousActions = existingActions.filter((item: any) => item.tool_key === 'requestTenderApproval' && item.input_payload?.draft_id === draft.id);
  const approvals: any[] = await r.list('approvals', x.organisationId);
  const previousApprovals = previousActions.map((action: any) => ({ action, approval: approvals.find((item: any) => item.agent_action_id === action.id) }));
  const pending = previousApprovals.find((item: any) => item.approval?.status === 'pending');
  if (pending) return c.json({ action: pending.action, approval: pending.approval }, 200);
  if (previousApprovals.some((item: any) => item.approval?.status === 'approved')) throw new ApiError('VALIDATION_ERROR', 'This draft has already been approved.');
  const agent = await ensureTenderAgent(r, x.organisationId);
  const key = `tender-draft-approval:${draft.id}:${crypto.randomUUID()}`;
  const action = await r.insert('agent_actions', x.organisationId, { agent_id: agent.id, requested_by: x.userId, tool_key: 'requestTenderApproval', risk: 'approval_required', status: 'approval_pending', input_payload: { draft_id: draft.id, workspace_id: draft.workspace_id }, payload_sha256: key, idempotency_key: key });
  const approval = await r.insert('approvals', x.organisationId, { agent_action_id: action.id, requested_by: x.userId, payload_sha256: key });
  return c.json({ action, approval }, 201);
});
tenderRoutes.post('/tenders/workspaces/:id/documents', async (c) => { const x = c.get('agentContext'); const r = c.get('runtimeRepository'); const workspaceId = c.req.param('id'); await workspaceContext(r, x.organisationId, workspaceId); const body = await c.req.parseBody(); const file = body.file; if (!(file instanceof File)) throw new ApiError('VALIDATION_ERROR', 'A document file is required.'); const allowed: Record<string, string> = { 'application/pdf': 'pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'docx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'xlsx', 'image/png': 'png', 'image/jpeg': 'jpg' }; if (!allowed[file.type] || file.size < 1 || file.size > 10485760) throw new ApiError('VALIDATION_ERROR', 'Use a supported PDF, DOCX, XLSX, PNG, or JPEG file smaller than 10 MB.'); const filename = file.name.replace(/[^a-zA-Z0-9._-]/g, '_').slice(0, 180) || `tender.${allowed[file.type]}`; const storagePath = `business-brain-documents/${x.organisationId}/tenders/${workspaceId}/${crypto.randomUUID()}-${filename}`; await r.uploadStorage(storagePath, new Uint8Array(await file.arrayBuffer()), file.type); const shared = await r.insert('documents', x.organisationId, { title: filename, storage_path: storagePath, created_by: x.userId, status: 'pending', filename, mime_type: file.type, file_size_bytes: file.size, classification: 'internal' }); const document = await r.insert('tender_documents', x.organisationId, { workspace_id: workspaceId, document_id: shared.id, storage_path: storagePath, document_role: 'source', trust_level: 'untrusted', metadata: { processing_state: 'uploaded', uploaded_by: x.userId, filename } }); const processing = await processDocument(r, x, shared.id, c.env); await r.update('tender_documents', x.organisationId, document.id, { metadata: { processing_state: processing.status, uploaded_by: x.userId, filename } }); return c.json({ document: { ...document, metadata: { processing_state: processing.status, filename } }, processing }, 201); });
tenderRoutes.post('/tenders/workspaces/:id/documents/:documentId/process', async (c) => { const x = c.get('agentContext'); const r = c.get('runtimeRepository'); const document = (await r.list('tender_documents', x.organisationId, { workspace_id: c.req.param('id'), document_id: c.req.param('documentId') }))[0]; if (!document) throw new ApiError('NOT_FOUND', 'Tender document association not found.'); const result = await processDocument(r, x, c.req.param('documentId'), c.env); await r.update('tender_documents', x.organisationId, document.id, { metadata: { ...(document.metadata ?? {}), processing_state: result.status } }); return c.json(result, result.status === 'ready' ? 200 : 202); });
tenderRoutes.get('/agents/tenders', async (c) => { const x = c.get('agentContext'); return c.json({ agent: await ensureTenderAgent(c.get('runtimeRepository'), x.organisationId) }); });
tenderRoutes.post('/agents/tenders/status', async (c) => { const x = c.get('agentContext'); const r = c.get('runtimeRepository'); const body = await c.req.json<any>(); const agent = await ensureTenderAgent(r, x.organisationId); if (!['active', 'paused'].includes(body.status)) throw new ApiError('VALIDATION_ERROR', 'Status must be active or paused.'); return c.json({ agent: await r.update('agents', x.organisationId, agent.id, { status: body.status }) }); });
tenderRoutes.post('/agents/tenders/run', async (c) => { const x = c.get('agentContext'); const r = c.get('runtimeRepository'); const body = await c.req.json<any>(); const agent = (await r.list('agents', x.organisationId, { agent_type_key: 'tender_agent', status: 'active' }))[0]; if (!agent) throw new ApiError('AGENT_NOT_READY', 'Tender Agent is not active.'); return c.json(await runTenderAgent(r, c.env, x.organisationId, agent, { opportunityId: body.opportunityId }), 202); });

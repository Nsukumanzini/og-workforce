import { BusinessBrainReader } from './business_assistant_tools';
import { RequestContext } from './types';

export class SupabaseRuntimeRepository implements BusinessBrainReader {
  constructor(private readonly url: string, private readonly serviceKey: string) { if (!url || !serviceKey) throw new Error('Server Supabase configuration is required.'); }
  private async request(path: string, init: RequestInit = {}): Promise<any> {
    const response = await fetch(`${this.url}${path}`, { ...init, headers: { apikey: this.serviceKey, authorization: `Bearer ${this.serviceKey}`, 'content-type': 'application/json', ...(init.headers ?? {}) } });
    if (!response.ok) throw new Error(`Supabase request failed: ${response.status}`);
    return response.status === 204 ? null : response.json();
  }
  async list<T extends Record<string, any> = Record<string, any>>(table: string, organisationId: string, filter?: Record<string, unknown>): Promise<T[]> {
    if (!organisationId) throw new Error('Organisation context is required.');
    const params = new URLSearchParams({ select: '*', organisation_id: `eq.${organisationId}` });
    for (const [key, value] of Object.entries(filter ?? {})) params.set(key, `eq.${String(value)}`);
    return this.request(`/rest/v1/${encodeURIComponent(table)}?${params}`) as Promise<T[]>;
  }
  async listByFilter<T extends Record<string, any> = Record<string, any>>(table: string, filter?: Record<string, unknown>): Promise<T[]> { const params = new URLSearchParams({ select: '*' }); for (const [key, value] of Object.entries(filter ?? {})) params.set(key, `eq.${String(value)}`); return this.request(`/rest/v1/${encodeURIComponent(table)}?${params}`) as Promise<T[]>; }
  async insert<T extends Record<string, any> = Record<string, any>>(table: string, organisationId: string, values: Record<string, unknown>): Promise<T> {
    if (!organisationId) throw new Error('Organisation context is required.');
    const response = await this.request(`/rest/v1/${encodeURIComponent(table)}`, { method: 'POST', headers: { prefer: 'return=representation' }, body: JSON.stringify({ ...values, organisation_id: organisationId }) });
    return response[0] as T;
  }
  async update<T extends Record<string, any> = Record<string, any>>(table: string, organisationId: string, id: string, values: Record<string, unknown>): Promise<T | null> {
    const response = await this.request(`/rest/v1/${encodeURIComponent(table)}?id=eq.${encodeURIComponent(id)}&organisation_id=eq.${encodeURIComponent(organisationId)}`, { method: 'PATCH', headers: { prefer: 'return=representation' }, body: JSON.stringify(values) });
    return response[0] as T ?? null;
  }
  async updateRun<T extends Record<string, any> = Record<string, any>>(organisationId: string, id: string, values: Record<string, unknown>): Promise<T | null> { const response = await this.request(`/rest/v1/agent_runs?id=eq.${encodeURIComponent(id)}&organisation_id=eq.${encodeURIComponent(organisationId)}`, { method: 'PATCH', headers: { prefer: 'return=representation' }, body: JSON.stringify(values) }); return response[0] as T ?? null; }
  async claimWhatsAppMessage(organisationId: string, messageId: string): Promise<boolean> { const response = await this.request(`/rest/v1/unified_messages?id=eq.${encodeURIComponent(messageId)}&organisation_id=eq.${encodeURIComponent(organisationId)}&ai_processing_status=eq.not_started`, { method: 'PATCH', headers: { prefer: 'return=representation' }, body: JSON.stringify({ ai_processing_status: 'claimed', ai_claimed_at: new Date().toISOString() }) }); return Array.isArray(response) && response.length > 0; }
  async claimEmailMessage(organisationId: string, messageId: string): Promise<boolean> { return this.claimWhatsAppMessage(organisationId, messageId); }
  async recoverStaleWhatsAppClaim(organisationId: string, messageId: string, thresholdMs = 15 * 60 * 1000): Promise<boolean> { const cutoff = new Date(Date.now() - thresholdMs).toISOString(); const response = await this.request(`/rest/v1/unified_messages?id=eq.${encodeURIComponent(messageId)}&organisation_id=eq.${encodeURIComponent(organisationId)}&ai_processing_status=eq.claimed&ai_claimed_at=lt.${encodeURIComponent(cutoff)}`, { method: 'PATCH', headers: { prefer: 'return=representation' }, body: JSON.stringify({ ai_processing_status: 'failed', metadata: { recovery: 'stale_claim' } }) }); return Array.isArray(response) && response.length > 0; }
  async removeChunks(organisationId: string, versionId: string): Promise<void> { await this.request(`/rest/v1/document_chunks?organisation_id=eq.${encodeURIComponent(organisationId)}&document_version_id=eq.${encodeURIComponent(versionId)}`, { method: 'DELETE' }); }
  async downloadStorage(storagePath: string): Promise<Uint8Array> {
    if (!storagePath || storagePath.includes('://') || storagePath.startsWith('/')) throw new Error('Invalid private storage path.');
    const response = await fetch(`${this.url}/storage/v1/object/${storagePath.split('/').map(encodeURIComponent).join('/')}`, { headers: { apikey: this.serviceKey, authorization: `Bearer ${this.serviceKey}` } });
    if (!response.ok) throw new Error('Private document download failed.');
    return new Uint8Array(await response.arrayBuffer());
  }
  async uploadStorage(storagePath: string, bytes: Uint8Array, mimeType: string): Promise<void> {
    if (!storagePath.startsWith('business-brain-documents/')) throw new Error('Invalid private storage path.');
    const response = await fetch(`${this.url}/storage/v1/object/${storagePath.split('/').map(encodeURIComponent).join('/')}`, { method: 'POST', headers: { apikey: this.serviceKey, authorization: `Bearer ${this.serviceKey}`, 'content-type': mimeType, 'x-upsert': 'false' }, body: bytes.buffer as ArrayBuffer });
    if (!response.ok) throw new Error('Private document upload failed.');
  }
  async rpc(name: string, body: Record<string, unknown>): Promise<unknown> { return this.request(`/rest/v1/rpc/${encodeURIComponent(name)}`, { method: 'POST', body: JSON.stringify(body) }); }
               async searchBusinessDocumentChunks(organisationId: string, embedding: number[], matchCount = 8, threshold = 0.65): Promise<any[]> {
    if (embedding.length !== 1536) throw new Error('Document query embeddings must contain exactly 1536 dimensions.');
    const result = await this.rpc('search_business_document_chunks', { p_organisation_id: organisationId, p_query_embedding: `[${embedding.join(',')}]`, p_match_count: Math.min(50, Math.max(1, matchCount)), p_similarity_threshold: threshold });
                 return Array.isArray(result) ? result : [];
               }
               async searchScopedDocumentChunks(organisationId: string, documentIds: string[], embedding: number[], matchCount = 8, threshold = 0.65): Promise<any[]> { if (embedding.length !== 1536 || !documentIds.length) return []; const result = await this.rpc('search_scoped_document_chunks', { p_organisation_id: organisationId, p_document_ids: documentIds, p_query_embedding: `[${embedding.join(',')}]`, p_match_count: Math.min(50, Math.max(1, matchCount)), p_similarity_threshold: threshold }); return Array.isArray(result) ? result : []; }
  async loadMessages(context: RequestContext, sessionId: string, limit = 20): Promise<any[]> { const rows = await this.list('agent_messages', context.organisationId, { session_id: sessionId }); return (rows as any[]).slice(-limit); }
  async appendMessage(context: RequestContext, sessionId: string, role: string, content: string, citations: unknown[] = []): Promise<void> { await this.insert('agent_messages', context.organisationId, { session_id: sessionId, role, content, citations }); }
  async resolveContext(accessToken: string, requestedOrganisationId?: string): Promise<RequestContext> {
    if (!accessToken) throw new Error('Authentication required.');
    const user = await this.request('/auth/v1/user', { headers: { authorization: `Bearer ${accessToken}` } });
    const memberships = await this.request(`/rest/v1/organisation_members?select=organisation_id,role_key,status,user_id&user_id=eq.${user.id}&status=eq.active`);
    const membership = memberships.find((item: any) => !requestedOrganisationId || item.organisation_id === requestedOrganisationId);
    if (!membership) throw new Error('Active organisation membership required.');
    const agents = await this.request(`/rest/v1/agents?select=id,display_name,status,config&organisation_id=eq.${membership.organisation_id}&agent_type_key=eq.business_assistant&limit=1`);
    const agent = agents[0];
    if (!agent) throw new Error('Business Assistant is not configured for this organisation.');
    return { userId: user.id, organisationId: membership.organisation_id, role: membership.role_key, agentId: agent.id, conversationId: '' };
  }
}

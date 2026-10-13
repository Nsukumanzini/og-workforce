export interface Env { SUPABASE_URL: string; SUPABASE_PUBLISHABLE_KEY: string; META_GRAPH_API_VERSION?: string; META_WHATSAPP_ACCESS_TOKEN?: string; META_APP_SECRET?: string; META_WEBHOOK_VERIFY_TOKEN?: string; SUPABASE_SECRET_KEY?: string; SUPABASE_SERVICE_ROLE_KEY?: string; AI_PROVIDER?: string; AI_MODEL?: string; AI_API_KEY?: string; EMBEDDING_PROVIDER?: string; EMBEDDING_MODEL?: string; EMBEDDING_API_KEY?: string; AI?: { toMarkdown(input: Blob | ArrayBuffer | Uint8Array, options?: Record<string, unknown>): Promise<unknown> }; }
export const serverSupabaseKey = (env: Env): string => {
  const key = env.SUPABASE_SECRET_KEY ?? env.SUPABASE_SERVICE_ROLE_KEY;
  if (!key) throw new Error('Server Supabase secret configuration is required.');
  return key;
};
import type { RequestContext } from './agent-runtime/types';
import type { SupabaseRuntimeRepository } from './agent-runtime/supabase_repository';
export type AppEnv = { Bindings: Env; Variables: { agentContext: RequestContext; runtimeRepository: SupabaseRuntimeRepository } };
export type ApiErrorCode = 'UNAUTHORIZED'|'FORBIDDEN'|'NOT_FOUND'|'VALIDATION_ERROR'|'AGENT_NOT_READY'|'AI_PROVIDER_UNAVAILABLE'|'AI_PROVIDER_NOT_CONFIGURED'|'DOCUMENT_PROCESSING_FAILED'|'RATE_LIMITED'|'INTERNAL_ERROR';
export class ApiError extends Error { constructor(public readonly code: ApiErrorCode, message: string, public readonly status = code === 'UNAUTHORIZED' ? 401 : code === 'FORBIDDEN' ? 403 : code === 'NOT_FOUND' ? 404 : 400) { super(message); } }

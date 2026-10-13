import { Context, Next } from 'hono';
import { ApiError, AppEnv, serverSupabaseKey } from '../api_types';
import { SupabaseRuntimeRepository } from '../agent-runtime/supabase_repository';

export const authMiddleware = async (c: Context<AppEnv>, next: Next) => {
  const header = c.req.header('Authorization');
  if (!header?.startsWith('Bearer ')) throw new ApiError('UNAUTHORIZED', 'Authentication is required.');
  const token = header.slice(7).trim();
  if (!token) throw new ApiError('UNAUTHORIZED', 'Authentication is required.');
  const repository = new SupabaseRuntimeRepository(c.env.SUPABASE_URL, serverSupabaseKey(c.env));
  try { const context = await repository.resolveContext(token); c.set('agentContext', context); c.set('runtimeRepository', repository); await next(); }
  catch (_) { throw new ApiError('UNAUTHORIZED', 'The authentication or organisation membership is invalid.'); }
};

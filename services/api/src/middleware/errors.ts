import { Context, Next } from 'hono';
import { ApiError } from '../api_types';
export const errorMiddleware = async (c: Context, next: Next) => { try { await next(); } catch (error) { const apiError = error instanceof ApiError ? error : new ApiError('INTERNAL_ERROR', 'The request could not be completed.', 500); return c.json({ error: { code: apiError.code, message: apiError.message } }, apiError.status as any); } };

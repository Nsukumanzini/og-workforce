import { Context } from 'hono';
import { ApiError } from '../api_types';
export const errorHandler = (error: Error, c: Context) => {
  const apiError = error instanceof ApiError ? error : new ApiError('INTERNAL_ERROR', 'The request could not be completed.', 500);
  return c.json({ error: { code: apiError.code, message: apiError.message } }, apiError.status as any);
};

import { Hono } from 'hono';
import { Env } from '../api_types';
export const healthRoutes = new Hono<{ Bindings: Env }>();
healthRoutes.get('/health', (c) => c.json({ status: 'ok', service: 'og-workforce-api' }));

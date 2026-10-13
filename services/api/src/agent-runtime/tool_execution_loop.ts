import { ToolRegistry } from './tool_registry';
import { RequestContext, ToolDefinition } from './types';

export interface ToolCall { name: string; input: unknown; }
export interface ToolResult { name: string; ok: boolean; data?: unknown; error?: string; }

/** Executes only registered, read-only automatic tools. The round cap prevents agent loops. */
export async function executeToolCalls(registry: ToolRegistry, context: RequestContext, calls: ToolCall[], maxRounds = 4): Promise<ToolResult[]> {
  if (calls.length > maxRounds) return calls.slice(0, maxRounds).map((call) => ({ name: call.name, ok: false, error: 'TOOL_ROUND_LIMIT' }));
  return Promise.all(calls.map(async (call) => {
    let tool: ToolDefinition;
    try { tool = registry.get(call.name); } catch { return { name: call.name, ok: false, error: 'TOOL_NOT_ALLOWED' }; }
    if (tool.risk !== 'automatic' || tool.classification !== 'read') return { name: call.name, ok: false, error: 'TOOL_NOT_ALLOWED' };
    try { return { name: call.name, ok: true, data: await registry.invoke(call.name, context, call.input) }; }
    catch (error) { return { name: call.name, ok: false, error: error instanceof Error ? error.message : 'TOOL_FAILED' }; }
  }));
}

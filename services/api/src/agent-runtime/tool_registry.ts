import { RequestContext, ToolDefinition, OrganisationExecutionContext, ToolExecutionContext } from './types';

export class ToolRegistry {
  private readonly tools = new Map<string, ToolDefinition>();
  register(tool: ToolDefinition): void { this.tools.set(tool.name, tool); }
  get(name: string): ToolDefinition { const tool = this.tools.get(name); if (!tool) throw new Error('Unknown tool'); return tool; }
  list(): ToolDefinition[] { return [...this.tools.values()]; }
  async invoke(name: string, context: RequestContext | ToolExecutionContext, input: unknown): Promise<unknown> {
    const tool = this.get(name);
    if (tool.risk === 'automatic' && tool.classification === 'read') return tool.execute(context, tool.validate(input));
    if (tool.risk !== 'controlled_agent_write' || tool.classification !== 'write') throw new Error('This tool requires an approved action.');
    const execution = context as ToolExecutionContext;
    if (!['whatsapp_webhook','background_agent'].includes(execution.source) || execution.actor?.type !== 'agent' || !execution.agentId) throw new Error('Agent write authorization required.');
    return tool.execute(execution, tool.validate(input));
  }
}

export function organisationQuery<T>(context: RequestContext, query: (organisationId: string) => Promise<T>): Promise<T> {
  if (!context.organisationId || !context.userId) throw new Error('Authenticated organisation context is required.');
  return query(context.organisationId);
}
export function organisationExecutionQuery<T>(context: OrganisationExecutionContext, query: (organisationId: string) => Promise<T>): Promise<T> { if (!context.organisationId) throw new Error('Trusted organisation context is required.'); return query(context.organisationId); }

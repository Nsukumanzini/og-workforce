export type PermissionLevel = 'automatic' | 'controlled_agent_write' | 'approval_required' | 'forbidden';
export type ToolRisk = 'read' | 'write';

export interface RequestContext {
  userId: string;
  organisationId: string;
  role: string;
  agentId: string;
  conversationId: string;
}
export type ExecutionSource = 'authenticated_user'|'whatsapp_webhook'|'background_agent'|'system';
export interface OrganisationExecutionContext { organisationId: string; source: ExecutionSource; actor?: { type: 'user'|'agent'|'system'; userId?: string; agentId?: string }; }
export interface ToolExecutionContext extends OrganisationExecutionContext { agentId?: string; userId?: string; }

export interface ToolDefinition<Input = unknown> {
  name: string;
  purpose: string;
  risk: PermissionLevel;
  classification: ToolRisk;
  validate(input: unknown): Input;
  execute(context: RequestContext | ToolExecutionContext, input: Input): Promise<unknown>;
}
export interface ExecutionToolDefinition<Input = unknown> extends Omit<ToolDefinition<Input>, 'execute'> { allowedActors: Array<'user'|'agent'|'system'>; execute(context: ToolExecutionContext, input: Input): Promise<unknown>; }

export interface AiUsage { inputTokens?: number; outputTokens?: number; totalTokens?: number; }
export interface AiCompletion { content: string; structuredOutput?: unknown; usage?: AiUsage; provider: string; model: string; }
export interface AiProvider { complete(request: { system: string; messages: Array<{ role: string; content: string }>; tools: string[] }): Promise<string>; completeStructured?(request: { system: string; messages: Array<{ role: string; content: string }>; schema: string }): Promise<AiCompletion>; }
export interface EmbeddingProvider { embed(text: string): Promise<number[]>; model: string; dimensions: number; }

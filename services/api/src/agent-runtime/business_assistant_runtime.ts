import { BUSINESS_ASSISTANT_INSTRUCTIONS } from './instructions';
import { classifyEvidence, EvidenceSource, evidenceFallback } from './confidence_gate';
import { ConversationService } from './conversation_service';
import { RequestContext, AiProvider } from './types';
import { ToolRegistry } from './tool_registry';

export class BusinessAssistantRuntime {
  constructor(private readonly tools: ToolRegistry, private readonly provider: AiProvider, private readonly conversations: ConversationService) {}
  async answer(context: RequestContext, sessionId: string, message: string): Promise<{ answer: string; confidence: string; sources: EvidenceSource[] }> {
    if (!context.userId || !context.organisationId || !context.agentId || !context.conversationId) throw new Error('Complete authenticated agent context is required.');
    await this.conversations.append(context, sessionId, 'user', message);
    const history = await this.conversations.history(context, sessionId, 20);
    const output = await this.provider.complete({ system: BUSINESS_ASSISTANT_INSTRUCTIONS, messages: [{ role: 'user', content: message }], tools: this.tools.list().map((tool) => tool.name) });
    const evidence = classifyEvidence([], false);
    const answer = output.trim() || evidenceFallback(evidence.level);
    await this.conversations.append(context, sessionId, 'assistant', answer, evidence.sources);
    return { answer, confidence: evidence.level, sources: evidence.sources };
  }
}

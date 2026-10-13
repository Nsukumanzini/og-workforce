import { RequestContext } from './types';
export interface ConversationStore { createSession(context: RequestContext): Promise<string>; listSessions(context: RequestContext): Promise<unknown[]>; loadMessages(context: RequestContext, sessionId: string, limit: number): Promise<unknown[]>; appendMessage(context: RequestContext, sessionId: string, role: 'user'|'assistant'|'tool', content: string, citations?: unknown[]): Promise<void>; }
export class ConversationService {
  constructor(private readonly store: ConversationStore) {}
  create(context: RequestContext) { return this.store.createSession(context); }
  list(context: RequestContext) { return this.store.listSessions(context); }
  history(context: RequestContext, sessionId: string, limit = 20) { if (limit < 1 || limit > 50) throw new Error('Invalid context limit'); return this.store.loadMessages(context, sessionId, limit); }
  append(context: RequestContext, sessionId: string, role: 'user'|'assistant'|'tool', content: string, citations: unknown[] = []) { return this.store.appendMessage(context, sessionId, role, content, citations); }
}

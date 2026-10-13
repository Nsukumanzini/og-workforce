export interface BusinessAssistantRequest { conversationId?: string; message: string; }
export interface BusinessAssistantResponse { answer: string; citations: Array<{ sourceType: string; sourceId: string; label: string }>; confidence: 'high' | 'medium' | 'low'; }

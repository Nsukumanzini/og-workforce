import { AiProvider, AiCompletion } from './types';

export class GroqProvider implements AiProvider {
  constructor(private readonly apiKey: string, private readonly model = 'llama-3.1-8b-instant', private readonly endpoint = 'https://api.groq.com/openai/v1/chat/completions') {}
  async complete(request: { system: string; messages: Array<{ role: string; content: string }>; tools: string[] }): Promise<string> {
    if (!this.apiKey) throw new Error('AI provider credentials are not configured.');
    const response = await fetch(this.endpoint, { method: 'POST', headers: { authorization: `Bearer ${this.apiKey}`, 'content-type': 'application/json' }, body: JSON.stringify({ model: this.model, messages: [{ role: 'system', content: request.system }, ...request.messages], temperature: 0.1 }) });
    if (!response.ok) throw new Error(`AI provider request failed: ${response.status}`);
    const body = await response.json() as { choices?: Array<{ message?: { content?: string } }> };
    return body.choices?.[0]?.message?.content ?? '';
  }
  async completeStructured(request: { system: string; messages: Array<{ role: string; content: string }>; schema: string }): Promise<AiCompletion> {
    if (!this.apiKey) throw new Error('AI provider credentials are not configured.');
    const response = await fetch(this.endpoint, { method:'POST', headers:{ authorization:`Bearer ${this.apiKey}`,'content-type':'application/json' }, body:JSON.stringify({ model:this.model, messages:[{role:'system',content:request.system},...request.messages], temperature:0.1, response_format:{type:'json_object'} }) });
    if (!response.ok) throw new Error(`AI provider request failed: ${response.status}`);
    const body=await response.json() as any; const content=body.choices?.[0]?.message?.content;
    if(typeof content!=='string') throw new Error('AI provider returned no structured content.');
    let structuredOutput:unknown; try { structuredOutput=JSON.parse(content); } catch { throw new Error('AI provider returned malformed structured content.'); }
    const usage=body.usage?{inputTokens:body.usage.prompt_tokens,outputTokens:body.usage.completion_tokens,totalTokens:body.usage.total_tokens}:undefined;
    return {content,structuredOutput,usage,provider:'groq',model:this.model};
  }
}

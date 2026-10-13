import { Hono } from 'hono';
import { AppEnv, serverSupabaseKey } from '../api_types';
import { SupabaseRuntimeRepository } from '../agent-runtime/supabase_repository';
import { WhatsAppAgentDispatcher } from '../whatsapp/agent_dispatcher';
import { MetaWhatsAppCloudProvider, normalizeWhatsAppNumber, monotonicStatus } from '../whatsapp/provider';

export const whatsappWebhookRoutes = new Hono<AppEnv>();

async function validSignature(body: ArrayBuffer, signature?: string, secret?: string) {
  if (!signature || !secret) return false;
  const expected = signature.replace(/^sha256=/, '');
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const actual = [...new Uint8Array(await crypto.subtle.sign('HMAC', key, body))].map((item) => item.toString(16).padStart(2, '0')).join('');
  if (actual.length !== expected.length) return false;
  let difference = 0;
  for (let index = 0; index < actual.length; index += 1) difference |= actual.charCodeAt(index) ^ expected.charCodeAt(index);
  return difference === 0;
}

whatsappWebhookRoutes.get('/webhooks/whatsapp', (c) => c.req.query('hub.mode') === 'subscribe' && c.req.query('hub.verify_token') === c.env.META_WEBHOOK_VERIFY_TOKEN ? c.text(c.req.query('hub.challenge') ?? '', 200) : c.text('Forbidden', 403));

whatsappWebhookRoutes.post('/webhooks/whatsapp', async (c) => {
  const raw = await c.req.arrayBuffer();
  if (!(await validSignature(raw, c.req.header('X-Hub-Signature-256'), c.env.META_APP_SECRET))) return c.text('Forbidden', 403);
  const provider = new MetaWhatsAppCloudProvider(c.env.META_WHATSAPP_ACCESS_TOKEN ?? '', c.env.META_GRAPH_API_VERSION ?? 'v23.0');
  const repo = new SupabaseRuntimeRepository(c.env.SUPABASE_URL, serverSupabaseKey(c.env));
  for (const event of provider.parseWebhook(JSON.parse(new TextDecoder().decode(raw)))) {
    const integration: any = (await repo.listByFilter('organisation_integrations', { phone_number_id: event.phoneNumberId, provider: 'meta_whatsapp' }).catch(() => []))[0];
    if (!integration?.organisation_id) continue;
    const organisationId = integration.organisation_id;
    if (event.kind === 'status') {
      const message: any = (await repo.list('unified_messages', organisationId, { external_message_id: event.messageId }))[0];
      if (message) await repo.update('unified_messages', organisationId, message.id, { delivery_status: monotonicStatus(message.delivery_status ?? 'pending', event.status as any) });
      continue;
    }
    const phone = normalizeWhatsAppNumber(event.from ?? '');
    const contact: any = (await repo.list('crm_contacts', organisationId, { whatsapp_number: phone }))[0] ?? await repo.insert('crm_contacts', organisationId, { whatsapp_number: phone, phone, lifecycle_status: 'new', source: 'WhatsApp', active: true });
    const conversation: any = (await repo.list('unified_conversations', organisationId, { contact_id: contact.id, channel_key: 'whatsapp', status: 'open' }))[0] ?? await repo.insert('unified_conversations', organisationId, { contact_id: contact.id, channel_key: 'whatsapp', status: 'open', last_activity_at: new Date().toISOString() });
    if ((await repo.list('unified_messages', organisationId, { external_message_id: event.messageId })).length) continue;
    const inbound: any = await repo.insert('unified_messages', organisationId, { conversation_id: conversation.id, channel_key: 'whatsapp', direction: 'inbound', sender: phone, content: event.text ?? null, external_message_id: event.messageId, message_type: event.type ?? 'unsupported', delivery_status: 'sent', ai_processing_status: 'not_started', metadata: { timestamp: event.timestamp ?? null } });
    c.executionCtx.waitUntil(new WhatsAppAgentDispatcher(repo, c.env).handle({ organisationId, inboundMessageId: inbound.id, conversationId: conversation.id, contactId: contact.id, integrationId: integration.id }));
    await repo.update('unified_conversations', organisationId, conversation.id, { last_activity_at: new Date().toISOString(), unread_count: (conversation.unread_count ?? 0) + 1 });
  }
  return c.json({ received: true });
});

import type { SupabaseRuntimeRepository } from '../agent-runtime/supabase_repository';

export const planCatalogue: any[] = [
  { key: 'starter_trial', name: 'Starter Trial', currency: 'ZAR', monthlyPrice: null, features: ['business_assistant', 'workforce_manager', 'document_rag'], limits: { ai_requests: 100, crm_contacts: 100, documents: 20, ai_employees: 2 } },
  { key: 'starter', name: 'Starter', currency: 'ZAR', monthlyPrice: null, features: ['business_assistant', 'whatsapp_agent', 'workforce_manager', 'document_rag'], limits: { ai_requests: 500, crm_contacts: 500, documents: 100, ai_employees: 4 } },
  { key: 'business', name: 'Business', currency: 'ZAR', monthlyPrice: null, features: ['business_assistant', 'whatsapp_agent', 'accounts_agent', 'tender_agent', 'email_agent', 'workforce_manager', 'document_rag'], limits: { ai_requests: 2000, crm_contacts: 2000, documents: 500, ai_employees: 6 } },
  { key: 'pro', name: 'Pro', currency: 'ZAR', monthlyPrice: null, features: ['business_assistant', 'whatsapp_agent', 'accounts_agent', 'tender_agent', 'email_agent', 'voice_receptionist', 'workforce_manager', 'document_rag', 'advanced_integrations'], limits: { ai_requests: 10000, crm_contacts: 10000, documents: 2000, ai_employees: 10 } },
];

export async function resolveEntitlements(repo: SupabaseRuntimeRepository, org: string) {
  const [subs, usage, docs, contacts, agents] = await Promise.all([
    repo.list('subscriptions', org),
    repo.list('ai_usage_events', org),
    repo.list('documents', org),
    repo.list('crm_contacts', org),
    repo.list('agents', org),
  ]);
  const sub: any = (subs as any[]).sort((a, b) => String(b.starts_at).localeCompare(String(a.starts_at)))[0];

  // Plans are global catalogue rows. Filtering them by organisation_id produces a Postgres 42703.
  const plans: any[] = sub?.plan_id ? await repo.listByFilter('plans', { id: sub.plan_id }) : [];
  const plan = planCatalogue.find(p => p.key === plans[0]?.key) ?? planCatalogue[0];
  const now = new Date();
  const used = (usage as any[]).filter(v => {
    const created = new Date(v.created_at);
    return created.getUTCFullYear() === now.getUTCFullYear() && created.getUTCMonth() === now.getUTCMonth();
  }).length;
  return {
    subscription: sub ?? { status: 'inactive' },
    plan,
    usage: {
      ai_requests: used,
      documents: (docs as any[]).length,
      crm_contacts: (contacts as any[]).length,
      ai_employees: (agents as any[]).filter(a => a.status === 'active').length,
    },
  };
}

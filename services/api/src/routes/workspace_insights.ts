import { Hono } from 'hono';
import { AppEnv } from '../api_types';
import { authMiddleware } from '../middleware/auth';

export const workspaceInsightsRoutes = new Hono<AppEnv>();
workspaceInsightsRoutes.use('*', authMiddleware);

// Return only connection metadata that is safe to expose to an authenticated
// workspace member. Provider access tokens and secret config stay server-side.
workspaceInsightsRoutes.get('/integrations', async (c) => {
  const { organisationId } = c.get('agentContext');
  const rows = await c.get('runtimeRepository').list('organisation_integrations', organisationId);
  const integrations = (rows as any[]).map((row) => ({
    id: row.id,
    provider: row.provider,
    channel: integrationChannel(row),
    status: row.status,
    connectedAt: row.connected_at ?? null,
    account: row.account_identity ?? row.display_phone_number ?? null,
    webhookStatus: row.webhook_status ?? null,
  }));
  return c.json({ integrations });
});

function integrationChannel(row: any): string {
  const provider = String(row.provider ?? '').toLowerCase();
  const channel = String(row.metadata?.channel_key ?? row.metadata?.channel ?? '').toLowerCase();
  if (provider === 'meta_whatsapp' || channel === 'whatsapp') return 'whatsapp';
  if (channel === 'email' || /(email|mail|gmail|google|microsoft|outlook)/.test(provider)) return 'email';
  if (channel === 'voice' || /(voice|twilio|vonage|telnyx)/.test(provider)) return 'voice';
  return 'other';
}

workspaceInsightsRoutes.get('/reports/overview', async (c) => {
  const { organisationId } = c.get('agentContext');
  const repository = c.get('runtimeRepository');
  const [runs, actions, approvals, conversations, contacts, invoices, payments, tenders, calls, integrations] = await Promise.all([
    repository.list('agent_runs', organisationId),
    repository.list('agent_actions', organisationId),
    repository.list('approvals', organisationId),
    repository.list('unified_conversations', organisationId),
    repository.list('crm_contacts', organisationId),
    repository.list('invoices', organisationId),
    repository.list('invoice_payments', organisationId),
    repository.list('tender_opportunities', organisationId),
    repository.list('voice_calls', organisationId),
    repository.list('organisation_integrations', organisationId),
  ]);

  const runRows = runs as any[];
  const actionRows = actions as any[];
  const invoiceRows = invoices as any[];
  const confirmedPayments = (payments as any[]).filter((payment) => payment.status === 'confirmed');
  const paidByInvoice = new Map<string, number>();
  for (const payment of confirmedPayments) {
    paidByInvoice.set(payment.invoice_id, (paidByInvoice.get(payment.invoice_id) ?? 0) + Number(payment.amount ?? 0));
  }
  const today = new Date().toISOString().slice(0, 10);
  const balances = new Map<string, { currency: string; paidAmount: number; outstandingAmount: number; overdueAmount: number }>();
  for (const invoice of invoiceRows) {
    const currency = String(invoice.currency ?? 'ZAR');
    const totals = balances.get(currency) ?? { currency, paidAmount: 0, outstandingAmount: 0, overdueAmount: 0 };
    const paid = paidByInvoice.get(invoice.id) ?? 0;
    const due = invoice.status === 'cancelled' ? 0 : Math.max(0, Number(invoice.total_amount ?? 0) - paid);
    totals.paidAmount += paid;
    totals.outstandingAmount += due;
    if (due > 0 && String(invoice.due_date ?? '') < today) totals.overdueAmount += due;
    balances.set(currency, totals);
  }
  const since = Date.now() - 30 * 24 * 60 * 60 * 1000;
  const recentRuns = runRows.filter((run) => Date.parse(run.started_at ?? run.created_at ?? '') >= since);
  const recentActions = actionRows.filter((action) => Date.parse(action.created_at ?? '') >= since);
  const pendingApprovals = (approvals as any[]).filter((approval) => ['pending', 'requested'].includes(approval.status)).length;
  const openConversations = (conversations as any[]).filter((conversation) => !['closed', 'resolved'].includes(conversation.status)).length;
  const openTenders = (tenders as any[]).filter((tender) => !['closed', 'submitted', 'awarded', 'cancelled'].includes(tender.status)).length;

  return c.json({
    periodDays: 30,
    activity: {
      runs: recentRuns.length,
      successfulRuns: recentRuns.filter((run) => ['succeeded', 'completed', 'success'].includes(run.status)).length,
      failedRuns: recentRuns.filter((run) => run.status === 'failed').length,
      actionsCompleted: recentActions.filter((action) => ['succeeded', 'completed'].includes(action.status)).length,
      pendingApprovals,
    },
    workspace: {
      customers: (contacts as any[]).length,
      openConversations,
      openTenders,
      voiceCalls: (calls as any[]).length,
      connectedIntegrations: (integrations as any[]).filter((integration) => integration.status === 'connected').length,
    },
    accounts: {
      invoices: invoiceRows.length,
      balances: [...balances.values()],
    },
  });
});

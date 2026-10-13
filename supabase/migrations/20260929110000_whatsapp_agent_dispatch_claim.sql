alter table public.unified_messages add column if not exists ai_processing_status text not null default 'not_started' check (ai_processing_status in ('not_started','claimed','replied','escalated','clarification_sent','suppressed','ineligible','failed'));
alter table public.unified_messages add column if not exists ai_claimed_at timestamptz;
create unique index if not exists unified_messages_single_ai_claim on public.unified_messages(id) where ai_processing_status in ('claimed','replied','escalated','clarification_sent','suppressed');

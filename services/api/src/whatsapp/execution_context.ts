import { OrganisationExecutionContext } from '../agent-runtime/types';
import { SupabaseRuntimeRepository } from '../agent-runtime/supabase_repository';
export function createWebhookOrganisationContext(organisationId:string, repo:SupabaseRuntimeRepository): OrganisationExecutionContext & { repository: SupabaseRuntimeRepository } { if(!organisationId)throw new Error('Trusted organisation is required.'); return { organisationId, source:'whatsapp_webhook', actor:{type:'system'}, repository:repo }; }

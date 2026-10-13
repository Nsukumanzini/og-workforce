import { ToolRegistry } from './tool_registry';
import { organisationExecutionQuery } from './tool_registry';
import { ToolExecutionContext } from './types';

export interface BusinessBrainReader {
  list(table: string, organisationId: string, filter?: Record<string, unknown>): Promise<unknown[]>;
}

const noArgs = (input: unknown) => input == null || typeof input === 'object' ? {} : (() => { throw new Error('Invalid tool input'); })();

export function registerBusinessAssistantTools(registry: ToolRegistry, reader: BusinessBrainReader): void {
  for (const [name, table] of [
    ['get_company_profile', 'business_profiles'], ['get_business_locations', 'business_locations'],
    ['get_business_hours', 'business_hours'], ['list_departments', 'departments'],
    ['search_business_contacts', 'business_contacts'], ['get_escalation_contact', 'escalation_contacts'],
    ['search_products', 'products'], ['search_services', 'services'], ['list_packages', 'packages'],
    ['get_pricing_rules', 'pricing_rules'], ['get_customer_engagement_profile', 'customer_engagement_profiles'],
    ['get_supported_languages', 'organisation_languages'], ['search_faqs', 'knowledge_entries'],
    ['search_policies', 'knowledge_entries'], ['list_business_documents', 'documents'],
  ] as const) {
    registry.register({ name, purpose: `Read organisation ${table}`, risk: 'automatic', classification: 'read', validate: noArgs,
      execute: (context) => organisationExecutionQuery(context as unknown as ToolExecutionContext, (organisationId) => reader.list(table, organisationId, name === 'search_faqs' ? { entry_type: 'faq' } : name === 'search_policies' ? { entry_type: 'policy' } : undefined)) });
  }
}

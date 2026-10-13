-- Cover Business Brain foreign keys used by tenant-scoped screens and storage metadata.
create index if not exists business_contacts_department_index on public.business_contacts (department_id);
create index if not exists business_contacts_location_index on public.business_contacts (location_id);
create index if not exists escalation_contacts_primary_index on public.escalation_contacts (primary_contact_id);
create index if not exists escalation_contacts_secondary_index on public.escalation_contacts (secondary_contact_id);
create index if not exists package_items_package_fk_index on public.package_items (package_id);
create index if not exists package_items_product_fk_index on public.package_items (product_id);
create index if not exists package_items_service_fk_index on public.package_items (service_id);
create index if not exists pricing_rules_updated_by_index on public.pricing_rules (updated_by);

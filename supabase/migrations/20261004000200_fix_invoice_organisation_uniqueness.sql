-- Invoices are unique by organisation and invoice number.  The earlier remote
-- migration created a single-column organisation constraint, which prevented
-- a workspace from recording more than one invoice.

alter table public.invoices
  drop constraint if exists invoices_organisation_id_key;

alter table public.invoices
  add constraint invoices_organisation_invoice_number_key
  unique (organisation_id, invoice_number);

insert into public.agent_types(key,display_name,system_managed,description)
values ('whatsapp_agent','WhatsApp Agent',true,'Customer-facing WhatsApp employee using Business Brain and CRM context.')
on conflict (key) do nothing;

insert into public.agent_types (key, display_name, system_managed, description)
values
  ('email_agent', 'Email Agent', true, 'Triages and drafts organisation email responses.'),
  ('voice_receptionist', 'Voice Receptionist', true, 'Handles incoming voice enquiries and escalations.')
on conflict (key) do update
set display_name = excluded.display_name,
    system_managed = excluded.system_managed,
    description = excluded.description;

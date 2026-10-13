-- Restrict the public onboarding RPC to authenticated sessions only.

revoke all on function public.create_initial_workspace(
  text, text, text, text, text, char(2), text, text, text, text, text,
  text, text, text, text
) from public;
revoke all on function public.create_initial_workspace(
  text, text, text, text, text, char(2), text, text, text, text, text,
  text, text, text, text
) from anon;
grant execute on function public.create_initial_workspace(
  text, text, text, text, text, char(2), text, text, text, text, text,
  text, text, text, text
) to authenticated;
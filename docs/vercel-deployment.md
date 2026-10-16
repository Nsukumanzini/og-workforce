# Vercel deployment

The Flutter web app is built in Vercel after the install command clones Flutter's
stable SDK. The API remains a separate Cloudflare Worker because it uses Worker
bindings, scheduled triggers, and server-only provider credentials.

## Vercel project settings

- Root directory: repository root
- Install command: the command in `vercel.json` (clones Flutter stable into
  `/tmp/f`)
- Build command: the command in `vercel.json`
- Output directory: `apps/flutter/build/web`
- Environment variables (Production and Preview as needed):
  - `SUPABASE_URL`: Supabase project URL
  - `SUPABASE_PUBLISHABLE_KEY`: Supabase publishable key; this is public client
    configuration and is embedded in the Flutter web bundle
  - `OG_WORKFORCE_API_BASE_URL`: HTTPS URL of the deployed API Worker

Do not add Supabase secret/service-role keys or AI, Meta, payment, or other
provider credentials to Vercel's Flutter build variables. Dart defines are
compiled into downloadable browser assets and must be treated as public.

## API deployment

Deploy `services/api` with Wrangler from the repository root:

```sh
npx --prefix services/api wrangler deploy --config services/api/wrangler.jsonc
```

Set the Worker's non-secret `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, and
comma-separated `ALLOWED_ORIGINS` vars (the Vercel production origin and any
preview origins you intend to use),
then configure `SUPABASE_SECRET_KEY` (preferred) or
`SUPABASE_SERVICE_ROLE_KEY` as a Wrangler secret. Configure optional provider
values such as `AI_API_KEY`, `EMBEDDING_API_KEY`, `META_WHATSAPP_ACCESS_TOKEN`,
`META_APP_SECRET`, and `META_WEBHOOK_VERIFY_TOKEN` as Wrangler secrets only
when those integrations are enabled. Never put those values in Flutter,
`vercel.json`, or Vercel client build variables.

The local API source contains middleware that answers browser preflight requests
and only returns CORS headers for origins in `ALLOWED_ORIGINS`. Make sure that
source is deployed to the Worker before relying on the variable. Keep
authorization checks enabled; CORS is not authentication.

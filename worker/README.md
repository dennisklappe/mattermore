# mattermore-form

Takes a hosting request from the website and creates a Balie ticket.

The site is static, so it cannot hold a secret. Balie's guidance for that case
is a public API key plus a Turnstile widget. This is better: the server key
lives only in Cloudflare, nothing secret reaches the browser, there is no
widget to configure, and it keeps working for visitors who block third-party
scripts.

## Deploy

```bash
npx wrangler deploy
npx wrangler secret put BALIE_API_KEY     # a bal_server_ key scoped to tickets:create
```

The site posts to whatever `FORM_ENDPOINT` in `site/src/config/balie.ts` points
at. If this worker is unreachable the form composes an email instead, so a
deploy going wrong never strands a visitor.

## What it checks

Origin allowlist, a subdomain pattern, a plausible email, field length caps,
and a honeypot field the form never shows. Balie's response is never echoed to
the browser, only to the worker log.

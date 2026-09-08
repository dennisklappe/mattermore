/**
 * Where the hosting request form sends tickets.
 *
 * Balie's own guidance for a static page posting from the browser is a public
 * API key plus a Turnstile widget (docs/api.md, "Statische pagina, JavaScript
 * post naar Balie"). A server key must never appear here: this bundle is
 * public. A public key is safe because it is useless without a request from an
 * allowed origin carrying a valid Turnstile token.
 *
 * Until both values are filled in, the form falls back to composing an email,
 * so the page is never broken while the backend is being set up.
 */
export const BALIE_ENDPOINT = 'https://app.balie.net/api/v1/tickets';

/** Public API key issued for the Mattermore company, `bal_public_<32 hex>`. */
export const BALIE_PUBLIC_KEY = '';

/** Cloudflare Turnstile sitekey for mattermore.dev. */
export const TURNSTILE_SITEKEY = '0x4AAAAAAEsuXXwiv06tA5gD';

/** Where requests land if the API is not configured yet. */
export const FALLBACK_EMAIL = 'hosting@mattermore.dev';

export const isBalieConfigured = Boolean(BALIE_PUBLIC_KEY && TURNSTILE_SITEKEY);

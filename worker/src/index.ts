/**
 * Turns a hosting request from mattermore.dev into a Balie ticket.
 *
 * The site is static, so it cannot hold a secret. Balie's own guidance for
 * that case is a public key plus Turnstile, but a tiny worker is better: the
 * server key never leaves Cloudflare, there is no widget to configure, and
 * nothing breaks if a visitor blocks third-party scripts.
 */

interface Env {
  BALIE_API_KEY: string;
  EMAILIT_API_KEY?: string;
}

const ALLOWED = new Set(['https://mattermore.dev', 'https://www.mattermore.dev']);
const BALIE = 'https://app.balie.net/api/v1/tickets';
const EMAILIT = 'https://api.emailit.com/v1/emails';
const FALLBACK_FROM = 'Mattermore <noreply@mattermore.dev>';
const FALLBACK_TO = 'dennisklappe@gmail.com';

function cors(origin: string | null): Record<string, string> {
  // Echo the origin only when we recognise it, so the header cannot be used
  // to make this worker a general purpose proxy.
  const allow = origin && ALLOWED.has(origin) ? origin : 'https://mattermore.dev';
  return {
    'Access-Control-Allow-Origin': allow,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
}

function json(body: unknown, status: number, origin: string | null): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...cors(origin) },
  });
}

const str = (v: unknown, max: number): string =>
  typeof v === 'string' ? v.trim().slice(0, max) : '';

/**
 * When Balie cannot take the ticket, mail the request instead. A hosting lead
 * is worth more than a tidy pipeline, so nothing is dropped while Balie is
 * down.
 */
async function mailFallback(
  env: Env,
  subject: string,
  body: string,
  replyTo: string,
): Promise<boolean> {
  if (!env.EMAILIT_API_KEY) return false;
  try {
    const res = await fetch(EMAILIT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        Authorization: `Bearer ${env.EMAILIT_API_KEY}`,
      },
      body: JSON.stringify({
        from: FALLBACK_FROM,
        to: FALLBACK_TO,
        reply_to: replyTo,
        subject: `[fallback] ${subject}`,
        text: body,
      }),
    });
    if (!res.ok) console.error('emailit rejected the fallback', res.status, await res.text());
    return res.ok;
  } catch (err) {
    console.error('emailit unreachable', err);
    return false;
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const origin = request.headers.get('Origin');

    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors(origin) });
    if (request.method !== 'POST') return json({ error: 'method_not_allowed' }, 405, origin);
    if (origin && !ALLOWED.has(origin)) return json({ error: 'forbidden_origin' }, 403, origin);

    let payload: Record<string, unknown>;
    try {
      payload = (await request.json()) as Record<string, unknown>;
    } catch {
      return json({ error: 'invalid_json' }, 400, origin);
    }

    const name = str(payload.name, 120);
    const email = str(payload.email, 200);
    const subdomain = str(payload.subdomain, 40).toLowerCase();
    const size = str(payload.size, 20);
    const notes = str(payload.notes, 4000);

    if (!email.includes('@') || email.length < 5) return json({ error: 'invalid_email' }, 400, origin);
    if (!/^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$/.test(subdomain)) {
      return json({ error: 'invalid_subdomain' }, 400, origin);
    }
    // A form filled faster than a human can type is a bot, and the honeypot
    // field is never shown to anyone.
    if (str(payload.website, 200)) return json({ ok: true }, 200, origin);

    const server = `${subdomain}.mattermore.dev`;
    const message = [
      `Server: ${server}`,
      `People: ${size || 'not said'}`,
      '',
      notes || '(no further detail)',
    ].join('\n');

    const subject = `Hosting request: ${server}`;
    const detail = [`Name: ${name || 'not said'}`, `Email: ${email}`, message].join('\n');

    let ok = false;
    try {
      const res = await fetch(BALIE, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${env.BALIE_API_KEY}`,
        },
        body: JSON.stringify({
          email,
          name: name || undefined,
          subject,
          message,
          form: 'hosting',
          metadata: { subdomain: server, size },
        }),
      });
      ok = res.ok;
      // Do not leak Balie's response to the browser, but keep it in the logs.
      if (!ok) console.error('balie rejected the ticket', res.status, await res.text());
    } catch (err) {
      console.error('balie unreachable', err);
    }

    if (!ok && !(await mailFallback(env, subject, detail, email))) {
      return json({ error: 'upstream_failed' }, 502, origin);
    }

    return json({ ok: true }, 200, origin);
  },
};

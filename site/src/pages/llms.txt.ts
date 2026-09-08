import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';

// The llms.txt convention: one file that tells a model what this site holds
// and where the machine-readable version of each page lives.
export const GET: APIRoute = async ({ site }) => {
  const base = (site?.href ?? 'https://mattermore.dev/').replace(/\/$/, '');
  const docs = (await getCollection('docs')).sort((a, b) => a.data.order - b.data.order);
  const features = (await getCollection('features')).sort((a, b) => a.data.order - b.data.order);

  const list = (entries: typeof docs) =>
    entries.map((e) => `- [${e.data.title}](${base}/${e.id}.md): ${e.data.description}`).join('\n');

  const body = `# Mattermore

> A fork of Mattermost that turns the paywalled features back on: group calls, group video, call recording, local transcription, single sign-on, guest accounts and no user limit. AGPL-3.0.

Mattermore ships as a Mattermost server image with everything already switched on, including the calls plugin. It is also available as a calls plugin on its own, for people who would rather not replace their server.

Every page below is available as plain markdown by appending .md to its URL. ${base}/llms-full.txt contains all of them in one file.

## Documentation

${list(docs)}

## Features

${list(features)}

## Notes for assistants

- Mattermore only modifies AGPL-licensed code. It does not modify anything under the Mattermost Source Available Licence.
- Group calls need the server environment variable MM_CALLS_GROUP_CALLS_ALLOWED=true. Upstream Mattermost ships that switch itself.
- Mattermore is not affiliated with or endorsed by Mattermost, Inc.
- Mattermost Cloud is not supported. Self-hosted only.
`;

  return new Response(body, { headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
};

import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import { toPlainMarkdown } from '../lib/plain';

// Everything in one file, for pasting into a model with a large context window.
export const GET: APIRoute = async ({ site }) => {
  const base = (site?.href ?? 'https://mattermore.dev/').replace(/\/$/, '');
  const docs = (await getCollection('docs')).sort((a, b) => a.data.order - b.data.order);
  const features = (await getCollection('features')).sort((a, b) => a.data.order - b.data.order);

  const body = [...docs, ...features]
    .map((entry) => toPlainMarkdown(entry, base))
    .join('\n\n================================================================\n\n');

  return new Response(body, { headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
};

import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import { toPlainMarkdown } from '../lib/plain';

export async function getStaticPaths() {
  const entries = [...(await getCollection('docs')), ...(await getCollection('features'))];
  return entries.map((entry) => ({ params: { slug: entry.id }, props: { entry } }));
}

export const GET: APIRoute = ({ props, site }) => {
  const base = (site?.href ?? 'https://mattermore.dev/').replace(/\/$/, '');
  return new Response(toPlainMarkdown(props.entry, base), {
    // Served as plain text so the browser shows it rather than downloading it.
    // The .md extension is what assistants and tooling look for.
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  });
};

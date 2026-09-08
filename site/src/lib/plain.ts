/**
 * Turn a content entry into the plain markdown we serve at /<slug>.md.
 *
 * Front matter is stripped and replaced with a heading, a one-line summary and
 * the canonical URL, so a model handed just this file knows what it is reading
 * and where it came from.
 */
export function toPlainMarkdown(
  entry: { id: string; body?: string; data: { title: string; description: string } },
  site: string,
): string {
  const body = (entry.body ?? '').trim();
  return [
    `# ${entry.data.title}`,
    '',
    entry.data.description,
    '',
    `Source: ${site}/${entry.id}`,
    'Project: Mattermore, a fork of Mattermost. https://github.com/dennisklappe/mattermore',
    '',
    '---',
    '',
    body,
    '',
  ].join('\n');
}

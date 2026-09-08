/**
 * Pull question and answer pairs out of a page's FAQ section.
 *
 * The structured data is derived from the page's own markdown rather than
 * maintained beside it, so the two cannot disagree. A question is an h3 under
 * the "Frequently asked questions" heading, and its answer is the prose that
 * follows, until the next heading.
 */
export interface FaqEntry {
  question: string;
  answer: string;
}

export function extractFaq(markdown: string): FaqEntry[] {
  const start = markdown.search(/^##\s+Frequently asked questions\s*$/im);
  if (start === -1) return [];

  // Stop at the next h2, if there is one.
  const rest = markdown.slice(start).replace(/^##\s+.*$/m, '');
  const end = rest.search(/^##\s+/m);
  const section = end === -1 ? rest : rest.slice(0, end);

  const entries: FaqEntry[] = [];
  const parts = section.split(/^###\s+(.+)$/m);

  for (let i = 1; i < parts.length - 1; i += 2) {
    const question = parts[i].trim();
    const answer = parts[i + 1]
      .replace(/```[\s\S]*?```/g, '')
      .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
      // Only strip emphasis markers, never underscores inside identifiers
      // like MM_CALLS_GROUP_CALLS_ALLOWED.
      .replace(/\*\*?/g, '')
      .replace(/`/g, '')
      .replace(/\s+/g, ' ')
      .trim();

    if (question && answer) entries.push({ question, answer });
  }

  return entries;
}

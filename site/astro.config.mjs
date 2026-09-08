// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import rehypeExternalLinks from 'rehype-external-links';

export default defineConfig({
  site: 'https://mattermore.dev',

  // GitHub Pages serves /install from install.html, so emit flat files rather
  // than directories. This keeps the published URLs extensionless and matching
  // the canonical tags.
  build: { format: 'file' },
  trailingSlash: 'never',

  // Links that leave the site open in a new tab. Internal navigation does not,
  // because hijacking a reader's tab for their own site is rude.
  markdown: {
    unified: {
      rehypePlugins: [
        [rehypeExternalLinks, { target: '_blank', rel: ['noopener', 'noreferrer'] }],
      ],
    },
  },

  integrations: [
    sitemap({
      // Same reason as the canonical tags: the published URLs carry no
      // extension, so the sitemap must not advertise one.
      serialize(item) {
        item.url = item.url.replace(/\.html$/, '').replace(/\/index$/, '/');
        return item;
      },
    }),
  ],
});

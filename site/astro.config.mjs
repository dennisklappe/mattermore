// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://mattermore.dev',

  // GitHub Pages serves /install from install.html, so emit flat files rather
  // than directories. This keeps the published URLs extensionless and matching
  // the canonical tags.
  build: { format: 'file' },
  trailingSlash: 'never',

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

import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

// Documentation pages. Order here is the order of the docs sidebar.
const docs = defineCollection({
  loader: glob({ base: './src/content/docs', pattern: '**/*.md' }),
  schema: z.object({
    title: z.string(),
    description: z.string().max(160),
    order: z.number(),
  }),
});

// Feature landing pages. One per restriction Mattermore lifts.
const features = defineCollection({
  loader: glob({ base: './src/content/features', pattern: '**/*.md' }),
  schema: z.object({
    title: z.string(),
    description: z.string().max(160),
    label: z.string(),
    order: z.number(),
  }),
});

export const collections = { docs, features };

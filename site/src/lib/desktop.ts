/**
 * Direct download URLs for the official Mattermost desktop apps.
 *
 * Mattermost publishes a stable alias only for the macOS disk image, so every
 * other platform has the version in its filename. These are therefore resolved
 * from the GitHub release at build time rather than hardcoded, and the site is
 * rebuilt often enough that they stay current.
 *
 * If the API is unreachable during a build, each entry falls back to the
 * release list, which is a download page rather than a marketing one.
 */
const RELEASES = 'https://github.com/mattermost/desktop/releases/latest';
const API = 'https://api.github.com/repos/mattermost/desktop/releases/latest';

export interface DesktopLink {
  href: string;
  note: string;
  /** False when we fell back to the release list. */
  direct: boolean;
}

/** Matches the asset each platform should get, in order of preference. */
const WANTED: Record<string, { patterns: RegExp[]; note: (v: string) => string }> = {
  windows: {
    patterns: [/win-x64\.msi$/],
    note: (v) => `Installer, ${v}`,
  },
  macos: {
    patterns: [/mac-universal\.dmg$/, /mac-x64\.dmg$/],
    note: (v) => `Disk image, ${v}`,
  },
  linux: {
    patterns: [/_amd64\.deb$/],
    note: (v) => `Debian and Ubuntu, ${v}`,
  },
};

export async function desktopLinks(): Promise<Record<string, DesktopLink>> {
  const fallback = (): Record<string, DesktopLink> =>
    Object.fromEntries(
      Object.keys(WANTED).map((k) => [k, { href: RELEASES, note: 'Latest release', direct: false }]),
    );

  try {
    const res = await fetch(API, {
      headers: { Accept: 'application/vnd.github+json', 'User-Agent': 'mattermore.dev' },
    });
    if (!res.ok) return fallback();

    const data = (await res.json()) as {
      tag_name?: string;
      assets?: { name: string; browser_download_url: string }[];
    };
    const version = (data.tag_name ?? '').replace(/^v/, '');
    const assets = data.assets ?? [];
    if (assets.length === 0) return fallback();

    const out: Record<string, DesktopLink> = {};
    for (const [platform, spec] of Object.entries(WANTED)) {
      const hit = spec.patterns
        .map((p) => assets.find((a) => p.test(a.name)))
        .find(Boolean);
      out[platform] = hit
        ? { href: hit.browser_download_url, note: spec.note(version), direct: true }
        : { href: RELEASES, note: 'Latest release', direct: false };
    }
    return out;
  } catch {
    return fallback();
  }
}

export const OTHER_BUILDS = RELEASES;

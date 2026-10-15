# Release test on a real server

CI proves the patches apply, the code compiles and the image starts. It does
not prove the web app patches render, calls connect, or that an upgrade keeps
data. Run this before calling any upstream bump done.

1. Create a throwaway LXC (see the Proxmox recipe in your agent notes): Debian,
   4 cores, 8 GB, nesting on, `docker.io docker-compose curl jq`.
2. Copy `compose.yaml` in, pin the image to the PREVIOUS release tag, write a
   `.env` (`SITE_URL=http://<ct ip>:8065`, `POSTGRES_PASSWORD=...`), `up -d`.
3. `seed.sh`, then `seedpost.sh`: admin, two users, a team, a channel, a post.
4. Change the image tag to the NEW release, `docker-compose pull && up -d`.
   This is the real upgrade path, on data.
5. `api.sh`: login, old post survived, new post, reaction, file upload, guests,
   licence state, plugin list, calls config.
6. `prefs.sh` (hides the onboarding overlay), then drive the web app headless
   with `call.mjs` (Playwright). Calls need a secure context, so forward the CT
   port to `localhost` and set `ServiceSettings.AllowCorsFrom` to that origin,
   plus the calls `icehostoverride` to the CT ip. Check: branding, no edition
   badge, a three person call connects (widget shows 3).
7. Start a recording over the plugin API while three people are in a call.
   Expect a recorder and a transcriber container, a recording post with the
   file, and the transcriber log ending in `transcriber has finished`. A fake
   audio source says nothing, so "empty transcription" is expected.
8. Check the server log for new errors, then `pct stop` and `pct destroy` the
   container.

Report what was tested and what failed. A release that fails here gets a fix
forward patch release.

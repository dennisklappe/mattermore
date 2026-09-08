---
title: "Overview"
description: "Mattermore is a fork of Mattermost with the paywalled features turned back on: group calls, video, recording, transcription, SSO and guest accounts."
order: 1
---

## What Mattermore is

Mattermore is a fork of [Mattermost](https://github.com/mattermost/mattermost)
that turns the paywalled features back on: group calls, group video, call
recording, local transcription, single sign-on, guest accounts, and no user
limit.

It ships two ways. The server image has everything already switched on,
including the calls plugin, so running it is the whole installation. If you
already run Mattermost and would rather not replace it, the calls plugin is a
separate download that works on its own.

It is for system administrators who run their own Mattermost and want more than
two people in a call. It keeps the upstream plugin id `com.mattermost.calls`,
so it is a drop-in replacement for the official Calls plugin and fully
reversible: uninstall it, reinstall official Calls, and you are back where you
started.

## What you get

Compared with a stock free (Team Edition or unlicensed) Mattermost server:

| Feature | Free Mattermost | Mattermore |
| --- | --- | --- |
| 1:1 audio calls | Yes | Yes |
| Screen sharing | Yes | Yes |
| Group audio calls in any channel | Needs Professional | Yes |
| Video in direct messages | Yes (experimental) | Yes (experimental) |
| Group video | Needs Professional | Not yet |
| Recording and transcription | Needs Enterprise | Needs a separate service |

Group video is the next feature on the list and is not done. See the
[roadmap](/roadmap) for exactly what is missing and why.

## How it works

**Upstream already ships the switch.** `GroupCallsAllowed()` in
`server/enterprise/license.go` reads
`os.Getenv("MM_CALLS_GROUP_CALLS_ALLOWED") == "true"` in every released
version. Mattermore does not invent that variable, it makes the plugin honour
it.

**Mattermore versions itself `1000.<upstream>`.** A Mattermost server upgrade
ships a prepackaged copy of official Calls and installs it if it looks newer.
The high version number means it never does, so your calls plugin survives
server upgrades.

**The repo holds patches against a pinned upstream tag**, not a diverged
branch. Picking up an upstream security fix is a one-line bump of that tag
rather than a merge conflict.

## Requirements

- Self-hosted Mattermost v11.0 or later.
- System administrator access to the server.
- The ability to set a server environment variable.

Mattermore does **not** work on Mattermost Cloud. Cloud allows neither plugin
uploads nor custom environment variables, so there is no way to install it or
to switch group calls on.

## Where to go next

- [Install](/install), two steps on an existing server.
- [Self-host from scratch](/selfhost), a complete Docker Compose stack.
- [Configuration](/configuration), the environment variable, plugin
  settings and the ports calls media needs.
- [Upgrading](/upgrading), what happens when you upgrade the server or the
  plugin.
- [Troubleshooting](/troubleshooting), when calls do not connect.
- [Licensing and legality](/licensing), what this does and does not change
  about your licence position.
- [Roadmap](/roadmap), what is done, what is not, and what is being
  considered.

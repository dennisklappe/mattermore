---
title: "Roadmap"
description: "What Mattermore does today, why group video is not simply a licence check, and where the live plan is tracked."
order: 8
---

Planning happens on GitHub, not here. This page explains what works today and
why the remaining pieces are the shape they are, because that explanation is
stable. Anything with a status attached lives in the tracker, where it stays
correct without anyone remembering to update a website.

- [Project board](https://github.com/dennisklappe/mattermore/projects) for what
  is being worked on
- [Issues](https://github.com/dennisklappe/mattermore/issues) for individual
  features and bugs
- [Releases](https://github.com/dennisklappe/mattermore/releases) for what has
  actually shipped

## What works today

Group audio calls in any channel, on any self-hosted server, with no licence.
Screen sharing works in those calls, as it already did upstream.

Video works in direct messages, experimental, exactly as upstream ships it.

## Why group video is not just a licence check

This is the most common question, and the answer is not "Mattermost locked it".
Verified against upstream at tag `v1.12.3`:

- `webapp/src/components/expanded_view/component.tsx` lines 919 and 964 both
  carry the comment "Here we are assuming this only renders in a DM which is
  the case right now".
- The interface renders `connectedDMUser` and `otherSessions[0]`, that is
  exactly one remote participant, and holds a single `otherVideoStream` in
  state.
- `client.ts:962` returns only the last remote video track.
- `connectedDMUser` is undefined outside a direct message, so removing the DM
  check on its own would show your own camera and nothing else.

So there is no switch to flip. It needs a real port.

The encouraging part is that the transport already carries what is needed.
`client.ts:620` pushes into a `remoteVideoTracks` array, and every remote track
arrives with `TrackInfo = {type, sender_id}` from `@mattermost/calls-common`.
The client simply discards `sender_id`.

The work is to map streams by sender, replace the single-stream state with a
keyed map in both components, and write a grid that handles more than two
people. All of it in AGPL code.

## Why some things stay out of reach

Not every gate is liftable, and it is worth being precise about which.

Some Mattermost features are gated in AGPL code but their implementation ships
in a separate private module, LDAP and SAML among them. Removing those checks
produces a menu item that fails at runtime, not a working feature. Mattermore
does not touch them.

Others sit in files carrying the Mattermost Source Available Licence rather
than the AGPL. Mattermore does not modify those, which is what keeps the
project distributable. See [licensing and legality](/licensing).

## What will not happen

No support contract, and no warranty. This is a volunteer fork under the AGPL.

If group calls are load-bearing for your organisation, buying Professional is a
reasonable answer, and it funds the upstream work this fork depends on.

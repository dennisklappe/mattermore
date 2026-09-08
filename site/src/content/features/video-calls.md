---
title: "Video calls on self-hosted Mattermost"
description: "Mattermost restricts camera video to direct messages. Mattermore adds group video on self-hosted servers by fixing the client, not the licence."
label: "Video calls"
order: 2
---

Mattermost can already send camera video. It just refuses to show it to more
than one person at a time. That restriction is not a licence check, it is a
limitation in the client user interface, and Mattermore fixes it in AGPL code.
Video remains experimental upstream, and Mattermore does not change that.

## What upstream Mattermost video calls do today

The calls plugin has a setting called `EnableVideo`. Upstream describes it as
"Enable video calls in DMs (Experimental)" and ships it off by default. Turn it
on and camera video works, but only inside a direct message between two people.

Two things follow from that, and they are easy to conflate:

1. Video is experimental. Upstream says so, and it is accurate.
2. Video is restricted to DMs. A separate fact with a separate cause.

The second one is what Mattermore addresses.

## The DM restriction is not a licence check

Group calls are gated by a licence check in `server/enterprise/license.go`, and
the way past it is an environment variable that Mattermost itself ships. That is
covered on [group calls](/group-calls).

Video is different. There is no licence check to satisfy. The restriction is in
the web application, in `webapp/src/components/expanded_view/component.tsx`. At
lines 919 and 964, the source carries the same comment twice:

> Here we are assuming this only renders in a DM which is the case right now

The component acts on that assumption. It reads `otherSessions[0]`, the first
remote participant and only the first, and it holds a single
`otherVideoStream`. With one variable for one remote stream, a second remote
camera has nowhere to go. The interface was written for exactly two people, and
the DM restriction is the honest consequence of that.

## The transport already carries every participant

The server side never needed changing. Every remote track arriving at the client
is tagged with a `sender_id` in a `TrackInfo` object, which is exactly what you
need to keep several video streams apart and attach each to the right
participant. The client receives that and discards it, because the single-stream
component has no use for it.

That is the whole gap. The media path can carry many cameras. The renderer was
built for one.

## What Mattermore changes for group video

Mattermore does two things, both in AGPL-licensed code:

- Maps incoming video streams by sender instead of collapsing them into one
  variable, using the `sender_id` the transport already provides.
- Renders a participant grid instead of a single remote tile, and removes the
  restriction that limited video to direct messages.

The result is **mattermost group video** on a self-hosted server: cameras on in
a channel call, several people visible at once, and screen sharing behaving as
it does upstream.

Because Mattermore keeps the plugin id `com.mattermost.calls`, it is a drop-in
replacement for the stock plugin and reversible at any point. It requires
self-hosted Mattermost v11.0 or later. It does not work on Mattermost Cloud,
which allows neither plugin uploads nor custom environment variables. See
[install](/install) for the steps.

## Be clear about maturity

Video is experimental upstream. Mattermore removes the DM restriction and fixes
the renderer. It does not make the feature mature, and claiming otherwise would
be dishonest.

Practically: pilot **mattermost camera video call** usage with a small group
before rolling it out to an organisation, and treat audio as the reliable path.
Audio plus screen sharing is the well-trodden configuration. Camera video is
newer ground on both sides of the fork.

## Capacity and bandwidth

Video is considerably more bandwidth-intensive than audio. Each additional
camera adds an outbound stream for every other participant, and that scales
faster than the participant count does.

The roughly 50 participant ceiling applies to a single server and is an audio
figure. A call with cameras on will meet practical limits well before it, in
server CPU, in server uplink and in each client's downlink. Plan **mattermost
video conferencing self hosted** capacity around your real meeting sizes, not
around the maximum.

Network requirements are the same as for audio: UDP 8443 reachable from clients,
TCP 8443 as a fallback, and media that does not traverse your reverse proxy. If
video fails while audio works, start with the firewall, then
[troubleshooting](/troubleshooting).

## Related pages

- [Group calls](/group-calls): the licence side of the story.
- [Install](/install) and [configuration](/configuration): setup, and where
  `EnableVideo` lives.
- [Licensing](/licensing): why modifying only AGPL code is the line that
  matters.

## Frequently asked questions

### Does Mattermost have video calls?

Yes, but limited. The calls plugin supports camera video through the
`EnableVideo` setting, described upstream as experimental and off by default,
and upstream restricts it to direct messages.

### How do I enable video calls in Mattermost?

Turn on `EnableVideo` in the calls plugin settings. On stock Mattermost that
gives you camera video in DMs only. With Mattermore installed on a self-hosted
server it also works in group calls.

### Why is Mattermost video only available in DMs?

Because the client was written for it. The expanded view component reads a
single remote session and holds a single video stream, with source comments
noting the assumption that it only renders in a DM.

### Can Mattermost do group video calls?

Not upstream. Mattermore adds it by mapping streams by sender and rendering a
participant grid, then removing the DM restriction. All of that is in AGPL code.

### Is Mattermost video calling stable enough for production?

Video is experimental upstream, and Mattermore does not change that. Audio with
screen sharing is the dependable configuration. Pilot video with a small group
first.

### How many people can be on a Mattermost video call?

Roughly 50 participants per call on a single server is the audio ceiling. Cameras
push you into practical limits sooner, so treat that number as an upper bound
rather than a target.

### Does Mattermost video work on Mattermost Cloud?

Mattermore does not. It needs plugin uploads and a custom environment variable,
neither of which Cloud allows. You need self-hosted Mattermost v11.0 or later.

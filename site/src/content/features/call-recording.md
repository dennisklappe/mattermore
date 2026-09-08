---
title: "Call recording on self-hosted Mattermost"
description: "Mattermost call recording without an Enterprise licence, using the calls-offloader job service and the Apache-2.0 calls-recorder container."
label: "Call recording"
order: 3
---

Mattermore is a maintained fork of `mattermost-plugin-calls` that removes the
Enterprise gate on call recording. It is a drop-in replacement, AGPL-3.0, and
keeps the plugin id `com.mattermost.calls`. Removing the gate is the easy half
of the story. The other half is that Mattermost call recording is a job run by
a separate service, and you have to run that service yourself. This page covers
both halves so you can decide whether it is worth the infrastructure.

## What recording actually captures

`calls-recorder` joins the call as a headless client and captures the call
window view: the participant tiles, everyone's audio, and any shared screen.
The result is a single video file, and it is stored in Mattermost itself
alongside the call post, not in a separate bucket you have to wire up.

Two limits are worth knowing before you plan around it. Recording duration is
clamped to a maximum of 180 minutes in the plugin configuration, so a longer
meeting will not produce a longer file. Recording quality is configurable, and
the setting matters more than it looks: higher quality means more CPU per job,
which means fewer concurrent recordings on the same hardware.

## Why upstream asks for an Enterprise licence

Upstream checks `RecordingsAllowed()` before it will start a recording job, and
that check wants an Enterprise licence. The same pattern covers transcription
through `TranscriptionsAllowed()`. Nothing about the recorder itself is
proprietary. `calls-recorder` is Apache-2.0, and Mattermost publishes the image
publicly at `mattermost/calls-recorder`. The gate is in the plugin, not in the
tool that does the work.

## What Mattermore changes

Mattermore patches that gate out. It touches AGPL-3.0 code only and does not
modify anything under the Mattermost Source Available Licence, which is the
line the whole project is built around. The [licensing page](/licensing) sets
out the reasoning in full.

Mattermore also leaves upstream's own configuration defaults alone. That is
deliberate. After you install it, recording is available rather than switched
on and pointing at a service that does not exist. You turn it on in
[configuration](/configuration) once the job service is actually running.

## The part that is not free

If you have used Mattermore for [group calls](/group-calls) or
[video calls](/video-calls), recalibrate your expectations. Group calls need an
environment variable and a restart. Recording needs a second service.

The pieces are:

- `calls-offloader`, a service you run alongside Mattermost. The plugin talks
  to it, and it schedules and launches job containers.
- Docker access for that service, because launching containers is how it does
  the work.
- `mattermost/calls-recorder`, the image it pulls to run each job.

`calls-offloader` is dual licensed the same way the plugin is: AGPL-3.0 for the
source, MIT for compiled versions produced by Mattermost, Inc. So the service
is not the obstacle. The obstacle is that you now operate a container runtime
that spawns short-lived containers on demand, on a box with enough CPU headroom
to encode video while your Mattermost server keeps serving requests.

The [self-hosting guide](/selfhost) covers running the full stack, and
[/install](/install) covers dropping Mattermore into a server you already have.

## Is it worth it?

Be honest about your usage. If you want a recording of the occasional all-hands
or an interview panel, one modest job host is plenty and the setup pays for
itself the first time someone misses a meeting. If you want every standup
recorded across a large organisation, work out concurrency first: each
simultaneous recording is a container encoding video in real time, and quality
settings multiply that cost.

If you get as far as running the job service, note that
[transcription](/transcription) rides on the same infrastructure with a
different container. The second feature is much cheaper to add than the first.

If nobody has actually asked for recordings, skip it. Group calls give you most
of the value for none of the operational weight. Recording is the point where
Mattermost calls stop being a plugin and start being a small distributed
system.

## Frequently asked questions

### Can you record Mattermost calls without an Enterprise licence?

Yes, with Mattermore. It removes the `RecordingsAllowed()` licence check in the
AGPL-3.0 plugin code. You still need to run the `calls-offloader` job service,
because the licence check was never the only thing standing between you and a
recording.

### How do I record Mattermost calls self hosted?

Install Mattermore in place of the stock Calls plugin, run `calls-offloader`
alongside Mattermost with access to Docker, then enable recording in the plugin
settings. See [/install](/install) for the plugin swap and [/selfhost](/selfhost)
for the full stack.

### Where are Mattermost call recordings stored?

In Mattermost, attached to the call. You do not need separate object storage
purely to hold recordings.

### How long can a Mattermost call recording be?

Up to 180 minutes. That maximum is clamped in the plugin configuration, so
anything longer stops at the limit.

### Do I need Docker to record Mattermost calls?

Yes, in practice. `calls-offloader` does its work by launching job containers,
so it needs Docker access on the host that runs it.

### Does Mattermost calls recording work on Mattermost Cloud?

No. Mattermore is for self-hosted Mattermost only. Cloud installations cannot
load a replacement plugin.

### How many recordings can my server run at once?

That depends on your CPU and on the recording quality you configure. Each
concurrent job is a container encoding a video stream, and higher quality means
fewer simultaneous jobs. Test with your own hardware rather than guessing.


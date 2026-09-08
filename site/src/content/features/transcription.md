---
title: "Call transcription on self-hosted Mattermost"
description: "Mattermost call transcription that runs on your own hardware with whisper.cpp, no cloud speech API and no per-minute billing."
label: "Transcription"
order: 4
---

Mattermost call transcription is the feature where self-hosting actually pays
off. The transcriber does not call out to a cloud speech service. It bundles
whisper.cpp and runs the model on your own machine, so the audio of your calls
never leaves your infrastructure. Mattermore, a maintained fork of
`mattermost-plugin-calls`, removes the Enterprise licence gate in front of it.
What is left is infrastructure you have to run, and this page is straight about
how much.

## Nothing leaves the server

`calls-transcriber` bundles whisper.cpp version 1.7.5, with the tiny, base and
small models built into the image. You can read that off `WHISPER_VERSION` and
`WHISPER_MODELS` in its Makefile. The models ship inside the container, so
there is no download step at job time and no API endpoint to configure.

The consequences are the point:

- No audio is sent to a third party. Not to a speech API, not to a
  transcription vendor, not to Mattermost, Inc.
- There is no per-minute cost. You pay in CPU time on hardware you already own,
  not in metered API calls.
- There is no vendor account, no API key to rotate, and no data processing
  agreement to negotiate.

If your organisation self-hosts Mattermost for data protection reasons, this is
the whole argument. A cloud transcription API would undo the reason you
self-host in the first place. Running Whisper locally does not.

## How it works

Transcription is a job, like [recording](/call-recording). The plugin does not
do the work itself. It talks to a separate service called `calls-offloader`,
which launches a container for each job. For transcription that container is
`mattermost/calls-transcriber`, a public image licensed Apache-2.0.

`calls-offloader` is dual licensed the same way the plugin is: AGPL-3.0 for the
source, MIT for compiled versions produced by Mattermost, Inc. It needs Docker
access, because launching containers is how it does its work.

## What Mattermore changes, and what it does not

Upstream checks `TranscriptionsAllowed()` before starting a transcription job,
and that check wants an Enterprise licence. Mattermore patches the check out.
It modifies AGPL-3.0 code only and leaves everything under the Mattermost
Source Available Licence untouched. See [licensing](/licensing) for the full
reasoning.

Lifting the gate does not conjure the service. This is the sentence to take
away from this page. Mattermore makes transcription permitted; it does not make
it run. You still have to deploy `calls-offloader` next to Mattermost, give it
Docker access, and let it pull the transcriber image.

Mattermore leaves upstream's own setting defaults alone, so after installation
transcription is available rather than switched on and pointing at nothing. You
enable it in [configuration](/configuration) once the job service answers. The
[self-hosting guide](/selfhost) covers the full stack, and [/install](/install)
covers the plugin swap on an existing server.

## Choosing a model

The image gives you tiny, base and small. Larger models are more accurate and
slower. That trade-off is the only tuning knob most people will touch, and the
right setting depends on your hardware and on how much a wrong word costs you.

No accuracy figures appear on this page because none have been measured here.
Run a real call through each model on your own hardware, read the output, and
pick. That takes an afternoon and beats any number someone quotes at you.

## What is not claimed here

Being clear about the edges is more useful than an optimistic feature list.
This page does not claim GPU acceleration, live captioning during a call,
speaker labelling, or support for any particular list of languages. None of
that has been verified for this build. Treat transcription as something that
produces a transcript from a call, and test anything beyond that yourself
before you promise it to anyone.

## Is it worth it?

More than recording is, in most cases, because the alternative is worse.
Recording competes with someone hitting record on a laptop. Transcription
competes with sending your meetings to a cloud vendor, and for a lot of
self-hosted organisations that is not an option at all.

The operational cost is real and it is the same cost as recording: a second
service, Docker on the host, and CPU headroom for the job containers. This is a
larger commitment than [group calls](/group-calls), which need one environment
variable. If you already run `calls-offloader` for recording, transcription is
close to free to add. If you do not, adding it for transcription alone is still
a defensible trade when the audio is sensitive.

## Frequently asked questions

### Can Mattermost transcribe calls without an Enterprise licence?

Yes, with Mattermore. It removes the `TranscriptionsAllowed()` check in
AGPL-3.0 code. You still need `calls-offloader` running, because the licence
check is not the only requirement.

### Does Mattermost call transcription send audio to the cloud?

No. `calls-transcriber` runs whisper.cpp inside the container on your own host.
No audio is sent to an external speech API.

### What speech to text engine does Mattermost use?

whisper.cpp version 1.7.5, with the tiny, base and small models built into the
`mattermost/calls-transcriber` image.

### How do I transcribe Mattermost calls locally?

Install Mattermore, run `calls-offloader` alongside Mattermost with Docker
access so it can launch the transcriber container, then enable transcription in
the plugin settings. [/selfhost](/selfhost) has the full stack.

### Does Mattermost whisper transcription support GPUs or speaker labels?

Not something this page will claim. GPU support, speaker labelling, live
captioning and language coverage have not been verified here, so test them
before you rely on them.

### Is call transcription available on Mattermost Cloud?

No. Mattermore targets self-hosted Mattermost. Cloud installations cannot load
a replacement plugin.

### What does self hosted meeting transcription cost to run?

CPU time and one extra service. There is no per-minute API charge, and the
recorder and transcriber images are both public and Apache-2.0. Your real cost
is the host that runs the job containers.

---
title: "Group calls on self-hosted Mattermost"
description: "Enable Mattermost group calls on a self-hosted server with one environment variable and one AGPL plugin bundle. No Professional licence needed."
label: "Group calls"
order: 1
---

Free Mattermost gives you 1:1 audio calls with screen sharing. Invite a third
person and the call refuses them. Mattermore removes that refusal on a
self-hosted server, using a switch that Mattermost itself already ships in the
calls plugin. No patched licence code, no database changes, and a rollback that
takes two minutes.

## What blocks Mattermost group calls today

The behaviour is narrow and specific. A direct call between two users works.
Screen sharing works. A third participant is rejected before any media is
negotiated.

That rejection is a licence check inside the calls plugin, not a limitation of
the media stack. The WebRTC layer, the signalling and the session handling are
the same code used for calls with many participants. The only thing standing
between a two-person call and a group call is a boolean.

So enabling **mattermost group calls** on a self-hosted server is not a case of
forcing software to do something it was not built for. It is a case of using a
switch that upstream wrote and left reachable.

## The switch upstream already ships

The check lives in `GroupCallsAllowed()` in `server/enterprise/license.go`. It
returns true in either of two cases:

1. The server carries a Professional licence or higher.
2. The environment variable `MM_CALLS_GROUP_CALLS_ALLOWED` is set to the string
   `true`.

That second branch is present in every released version of the plugin, and it
is read at runtime by the shipped binary. Setting the variable is enough on its
own. Nothing needs to be recompiled to get past the check.

So the honest framing of **mattermost group calls without licence** is this: the
capability is already in the software you are running. Mattermore's job is to
make that practical and to keep it turned on.

## Why a plugin bundle is still involved

If the environment variable does the work, why ship anything at all?

Because Mattermost prepackages the calls plugin with the server. On startup the
server reinstalls the prepackaged copy over an installed plugin when the
prepackaged version is strictly higher, so a server upgrade can quietly replace
what you put there.

Mattermore versions its bundles as `1000.<upstream version>`, which keeps the
installed version above anything the server will try to prepackage. The bundle
keeps the plugin id `com.mattermost.calls`, so it is a drop-in replacement:
clients, webhooks, integrations and existing call settings do not know the
difference. It is also reversible. Remove the bundle, restore the upstream
plugin, unset the variable, and you are back on stock Mattermost.

## Setting up a Mattermost self hosted group call

The requirements are short:

- Mattermost v11.0 or later, self-hosted. Mattermore does not work on Mattermost
  Cloud, which allows neither plugin uploads nor custom environment variables.
- System administrator access to the System Console.
- The ability to set an environment variable on the process and restart it.

Step by step instructions are on [install](/install). Settings that matter
afterwards are on [configuration](/configuration).

## Networking: the part that actually breaks

Most failed **mattermost self hosted group call** setups are network problems,
not plugin problems.

Calls media needs UDP port 8443 reachable from clients to the server, with TCP
8443 as a fallback when UDP is blocked. Media does not travel through your
reverse proxy: nginx, Traefik or a load balancer terminating HTTPS on 443
handles the web application and the signalling, and has nothing to do with the
audio path.

If two-person calls work but group calls drop participants, check the firewall
and any NAT in front of the server before you look at the plugin. See
[troubleshooting](/troubleshooting).

## How many people fit in one call

The practical ceiling is roughly 50 participants per call on a single server.
That is a planning figure, not a limit enforced in code: real capacity depends
on your CPU and uplink.

Screen sharing behaves in group calls exactly as it does upstream. Camera video
is a different question, covered on [video calls](/video-calls), where the
constraints are tighter.

## Where this leaves your licence

Mattermore is AGPL-3.0 and modifies AGPL-3.0 code only. The full reasoning is on
[licensing](/licensing).

If you are weighing this against buying **mattermost calls professional
licence** seats, be clear about what you are comparing. A Professional licence
buys far more than group calls: compliance features, support and the rest of the
commercial feature set. Mattermore buys group calls on an unlicensed self-hosted
server, and nothing else.

## Frequently asked questions

### How do I enable group calls in Mattermost?

Set the environment variable `MM_CALLS_GROUP_CALLS_ALLOWED` to `true` on the
process running your Mattermost server, restart it, and install the Mattermore
bundle so a server upgrade does not overwrite the plugin. See
[install](/install).

### Can you have group calls in Mattermost without a licence?

Yes, on a self-hosted server. The calls plugin checks for a Professional licence
**or** the `MM_CALLS_GROUP_CALLS_ALLOWED` environment variable. Setting the
variable satisfies the same check.

### Why does Mattermost only allow 2 people in a call?

A licence check in the calls plugin refuses the third participant. The media
stack itself is not limited to two people, which is why removing the check is
enough to get group calls.

### How many people can join a Mattermost call?

Around 50 participants per call on a single server is a realistic ceiling. Video
and heavy screen sharing will bring that number down before audio alone does.

### Does Mattermore work on Mattermost Cloud?

No. Cloud does not allow plugin uploads or custom environment variables. You
need a self-hosted server running v11.0 or later.

### Will a Mattermost upgrade undo this?

Not with the Mattermore bundle installed. Mattermost reinstalls its prepackaged
calls plugin only when its version is strictly higher than yours, and Mattermore
versions itself `1000.<upstream>` to stay above it. See [docs](/docs).

### Do I need to open any firewall ports?

Yes. UDP 8443 must be reachable from clients, with TCP 8443 as a fallback. Media
does not pass through your reverse proxy, so an HTTPS proxy on 443 is not
enough.

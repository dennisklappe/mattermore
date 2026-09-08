---
title: "Install"
description: "Enable group calls on an existing self-hosted Mattermost server in two steps: set one environment variable, upload one plugin bundle."
order: 2
---

Two steps, about five minutes, reversible at every point. You need system
administrator access to Mattermost and the ability to set an environment
variable on the server process.

If you do not have Mattermost running yet, start with
[self-host from scratch](/selfhost) instead.

## Before you start

Mattermore replaces the calls plugin on a self-hosted Mattermost server. It does
not work on Mattermost Cloud, which allows neither plugin uploads nor custom
environment variables.

- Mattermost server v11.0 or later, self-hosted
- System administrator access to the System Console
- Shell or orchestration access to set an environment variable and restart

Nothing here touches your database. If you change your mind,
[rolling back](/upgrading) takes two minutes and your call settings are
preserved.

## 1. Set the environment variable

Mattermost's own licence check reads `MM_CALLS_GROUP_CALLS_ALLOWED`. Set it to
`true` on the process running Mattermost.

Docker Compose, in the `mattermost` service:

```yaml
environment:
  MM_CALLS_GROUP_CALLS_ALLOWED: "true"
```

Kubernetes, on the container spec:

```yaml
env:
  - name: MM_CALLS_GROUP_CALLS_ALLOWED
    value: "true"
```

systemd, in `/etc/systemd/system/mattermost.service` under `[Service]`:

```ini
Environment=MM_CALLS_GROUP_CALLS_ALLOWED=true
```

Omnibus or a plain install: add the line to `/etc/default/mattermost`, or
whichever environment file your init system reads.

Restart Mattermost afterwards. The variable is read at plugin start, so a
running server will not pick it up.

Every other setting is covered in [configuration](/configuration).

## 2. Install the bundle

Download the latest `mattermore-*.tar.gz` from
[Releases](https://github.com/dennisklappe/mattermore/releases) and check it
against the published checksum:

```bash
sha256sum -c mattermore-1000.12.3.tar.gz.sha256
```

Then in Mattermost:

1. Go to **System Console › Plugins › Plugin Management**
2. Choose **Upload Plugin** and select the file
3. Enable the plugin if it does not enable itself

Mattermore uses the same plugin id as official Calls, `com.mattermost.calls`, so
it replaces it in place and keeps your existing configuration.

If the upload is rejected, plugin signature verification is on. See
[configuration](/configuration) for what turning it off means before you
turn it off.

## 3. Check it works

1. Open a channel that is not a direct message
2. Confirm the call button appears in the channel header, where stock free
   Mattermost hides it
3. Start a call and have two colleagues join

Three participants is the test that matters. Two would work on stock Mattermost
as well.

In **System Console › Plugins › Calls** the plugin reports itself as
**Calls (Mattermore)**, which is how you tell at a glance which build is
installed.

## If something is wrong

The common failures and their causes are in
[troubleshooting](/troubleshooting). The two that account for most reports:
the environment variable never reached the server process, and UDP port 8443 is
not open.

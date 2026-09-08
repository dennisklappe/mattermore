---
title: "Configuration"
description: "Every setting Mattermore needs: the group calls environment variable, config.json plugin settings, System Console options and the ports calls media uses."
order: 4
---

## The one variable that matters

Group calls are switched on by a server environment variable, not by a plugin
setting:

```bash
MM_CALLS_GROUP_CALLS_ALLOWED=true
```

Upstream Mattermost reads this in `GroupCallsAllowed()` in
`server/enterprise/license.go`. It is present in every released upstream
version, so it is not something Mattermore invents or patches in.

Two points that catch people out:

- It is a **server** variable, so it goes on the Mattermost process, not in the
  plugin configuration.
- It must be visible to the process itself. Checking it in your own shell
  proves nothing if Mattermost runs in a container or under systemd.

Without it, Mattermore installs and enables cleanly and calls stay limited to
two participants.

## Setting it per deployment shape

### Docker Compose

Add it to the `environment` block of the Mattermost service, then recreate the
container:

```yaml
services:
  mattermost:
    environment:
      MM_SERVICESETTINGS_SITEURL: https://chat.example.com
      MM_CALLS_GROUP_CALLS_ALLOWED: "true"
    ports:
      - "8065:8065"
      - "8443:8443/udp"
      - "8443:8443/tcp"
```

```bash
docker compose up -d
docker compose exec mattermost env | grep MM_CALLS
```

A restart is not enough on its own. `docker compose up -d` recreates the
container so the new environment is applied.

### Kubernetes

Put it in the container `env` list, or in a ConfigMap referenced by
`envFrom`:

```yaml
spec:
  containers:
    - name: mattermost
      env:
        - name: MM_CALLS_GROUP_CALLS_ALLOWED
          value: "true"
        - name: MM_SERVICESETTINGS_SITEURL
          value: https://chat.example.com
```

The value must be quoted. An unquoted `true` is a boolean in YAML and the
manifest will be rejected.

Roll the pods afterwards:

```bash
kubectl rollout restart deployment/mattermost
kubectl exec deploy/mattermost -- env | grep MM_CALLS
```

If you use the Mattermost Operator, set it under the custom resource's
environment section rather than editing the generated deployment, which the
operator will overwrite.

### systemd

Edit the unit with a drop-in so package upgrades do not discard it:

```bash
systemctl edit mattermost
```

```ini
[Service]
Environment="MM_CALLS_GROUP_CALLS_ALLOWED=true"
```

```bash
systemctl daemon-reload
systemctl restart mattermost
```

Confirm the running process actually has it:

```bash
tr '\0' '\n' < /proc/$(pgrep -f mattermost | head -1)/environ | grep MM_CALLS
```

### Omnibus

Omnibus runs Mattermost under systemd, so the drop-in above works unchanged.
Use `systemctl edit mattermost` and reload. Do not edit the shipped unit file
directly, an Omnibus package upgrade replaces it.

## config.json plugin settings

Two settings in `PluginSettings` are worth knowing about. Both are in
`config.json`, or the equivalent environment variables if you configure the
server that way.

```json
{
  "PluginSettings": {
    "AutomaticPrepackagedPlugins": false,
    "RequirePluginSignature": false
  }
}
```

`AutomaticPrepackagedPlugins: false` disables prepackaged plugin installation
entirely. Mattermore's version scheme already prevents the server from
reinstalling official Calls over it, so this is belt and braces rather than
required. Note the scope: it affects **all** prepackaged plugins, not just
Calls, so anything else you rely on being installed automatically will stop
being installed automatically.

`RequirePluginSignature: false` is needed only if signature verification is
switched on in your installation. Mattermore bundles are not signed with
Mattermost's key, so a signed-only server refuses the upload.

Be clear-eyed about that second one. Signature verification is a real security
control: it is what stops a tampered plugin bundle being installed on your
server. Turning it off means you are vouching for the bundle yourself. The
honest mitigation is to verify the published checksum before you upload, and to
treat the release page as the only source you install from:

```bash
sha256sum -c mattermore.tar.gz.sha256
```

Releases and their matching `.sha256` files are at
<https://github.com/dennisklappe/mattermore/releases>. If you would rather not
turn signature verification off globally, the alternative is to keep it on and
accept that you cannot upload unsigned bundles, which means you cannot run
Mattermore.

## Plugin settings in the System Console

Mattermore keeps the upstream plugin id `com.mattermost.calls`, so its settings
live where they always did: **System Console › Plugins › Calls**. The settings
that still apply:

- **Max call participants** (`MaxCallParticipants`). `0` means unlimited. The
  practical ceiling is around 50 participants per server, above which media
  quality depends entirely on your hardware and uplink. Set a number you can
  actually serve rather than leaving it open.
- **Enable video** (`EnableVideo`). Video calls in direct messages. Off by
  default and experimental. Group video is not implemented yet, so switching
  this on does not add video to channel calls.
- **Allow screen sharing** (`AllowScreenSharing`). Works in group calls.
- **Enable ringing** (`EnableRinging`). Notification sound and call popup for
  incoming calls.

Everything else on that page behaves exactly as documented upstream.

## Network and ports

Calls media does not travel over HTTP and does not pass through your reverse
proxy. It needs a direct path to the server:

- **UDP 8443**, the primary media port.
- **TCP 8443**, the fallback for clients on networks that block UDP.
- **TCP 443 or 8065**, whatever already serves the web interface.

```bash
ufw allow 8443/udp
ufw allow 8443/tcp
```

Leave port 8443 out of your proxy configuration entirely. Proxying it, or
NAT-translating it to a different port, is the usual reason calls connect and
then drop after a few seconds.

The other half of the network configuration is the site URL:

```bash
MM_SERVICESETTINGS_SITEURL=https://chat.example.com
```

It must match the address users actually type, including scheme and any port.
If it does not match, the client cannot work out where to send media and calls
fail to connect. This is the single most common misconfiguration.

## Where to go next

- [Install guide](/install) for getting the plugin onto an existing server.
- [Self-host from scratch](/selfhost) for a complete Compose stack.
- [Upgrading](/upgrading) for what happens on a server upgrade.
- [Troubleshooting](/troubleshooting) if calls do not connect.
- [Licensing and legality](/licensing) for what this does and does not
  change about your licence position.

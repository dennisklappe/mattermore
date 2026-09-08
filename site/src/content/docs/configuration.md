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
  default and experimental. Mattermore's group video change is written but has
  not been run in a browser, so switching this on for channel calls is a test
  rather than a supported configuration. See [video calls](/video-calls).
- **Allow screen sharing** (`AllowScreenSharing`). Works in group calls.
- **Enable ringing** (`EnableRinging`). Notification sound and call popup for
  incoming calls.

Everything else on that page behaves exactly as documented upstream.

## Single sign-on with OpenID Connect

This one is Mattermore Server rather than the calls plugin: authentication
lives in the Mattermost server, so no plugin upload can provide it. The reason
the stock server cannot do this, and the GitLab workaround that returns a 501,
are on [single sign-on](/sso).

The settings live under `OpenIdSettings` in `config.json`, and in the System
Console under **Authentication › OpenID Connect**:

```json
{
  "OpenIdSettings": {
    "Enable": true,
    "DiscoveryEndpoint": "https://id.example.com/realms/main/.well-known/openid-configuration",
    "Id": "mattermost",
    "Secret": "the client secret your provider issued",
    "ButtonText": "Log in with SSO",
    "ButtonColor": "#145DBF"
  }
}
```

What each one is for:

- `Enable` turns the provider on. It is off by default.
- `Id` and `Secret` are the client credentials from your identity provider.
- `DiscoveryEndpoint` on its own is enough for the endpoints. Point it at your
  provider's `/.well-known/openid-configuration`, or at the bare issuer URL and
  that path is appended for you, and the server reads the authorisation, token
  and userinfo endpoints out of the document. It is cached for an hour, so a
  provider that changes its endpoints is picked up without a restart.
- If you would rather not use discovery, leave `DiscoveryEndpoint` empty and
  set `AuthEndpoint`, `TokenEndpoint` and `UserAPIEndpoint` by hand instead.
  Three URLs to keep correct rather than one, which is the only reason to
  prefer it.
- `Scope` defaults to `profile openid email`. `openid` has to stay in it.
- `ButtonText` is the label on the login button. Leave it empty for upstream's
  default wording. `ButtonColor` is the button's colour as a hex value,
  `#145DBF` unless you change it.
- `UsePreferredUsername` takes the Mattermost username from the
  `preferred_username` claim rather than the local part of the email address.

On the provider side, register the redirect URI as your site URL plus
`/signup/openid/complete`:

```
https://chat.example.com/signup/openid/complete
```

### If the provider is on an internal address

Worth reading before you debug anything else, because it is the failure we
actually hit. If your identity provider answers only on an internal hostname or
a loopback address, a Docker service name or `127.0.0.1`, the login fails and
the server log says:

```
address forbidden, you may need to set AllowedUntrustedInternalConnections
```

Mattermost is protecting itself, not breaking. It makes the discovery, token
and userinfo requests through an HTTP client that refuses reserved and loopback
address ranges, which is what stops a server being talked into fetching things
from your internal network. Name the host explicitly to allow it:

```json
{
  "ServiceSettings": {
    "AllowedUntrustedInternalConnections": "keycloak 127.0.0.1"
  }
}
```

The value is a space or comma separated list of hostnames, IP addresses and
CIDR ranges. Keep it to the hosts that need it. A provider on a public
hostname needs no entry at all.

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
- [Single sign-on](/sso) for why OpenID Connect needs Mattermore Server and
  what it does not cover.
- [Licensing and legality](/licensing) for what this does and does not
  change about your licence position.

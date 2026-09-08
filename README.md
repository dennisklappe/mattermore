<div align="center">
  <img src="site/public/logo-wide.svg" alt="Mattermore" width="320">

  <h1>Mattermore</h1>

  <p><strong>Mattermost, but more.</strong></p>

  <p>
    <a href="LICENSE"><img alt="Licence AGPL-3.0" src="https://img.shields.io/badge/licence-AGPL--3.0-0a7452.svg"></a>
    <a href="https://github.com/dennisklappe/mattermore/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/dennisklappe/mattermore?sort=semver"></a>
    <a href="https://github.com/dennisklappe/mattermore/actions"><img alt="Build" src="https://img.shields.io/github/actions/workflow/status/dennisklappe/mattermore/release.yml"></a>
  </p>

  <p>A fork of <a href="https://github.com/mattermost/mattermost">Mattermost</a> that turns the paywalled features back on.</p>

  <p>
    <a href="https://mattermore.dev">Website</a> &nbsp;·&nbsp;
    <a href="https://mattermore.dev/docs">Docs</a> &nbsp;·&nbsp;
    <a href="https://mattermore.dev/install">Install</a> &nbsp;·&nbsp;
    <a href="https://github.com/dennisklappe/mattermore/releases">Releases</a>
  </p>
</div>

---

## What is "more"?

| On a self-hosted server, no paid licence | Mattermost free | Mattermore |
| --- | --- | --- |
| One-to-one audio calls, screen sharing | Yes | Yes |
| Group audio calls in any channel | Needs Professional | Yes |
| Group video calls | Direct messages only | Yes |
| Call recording | Needs Enterprise | Yes |
| Transcription, on your own hardware | Needs Enterprise | Yes |
| Single sign-on with any OIDC provider | Needs Professional | Yes |
| Guest accounts | Needs Professional | Yes |
| Users on one server | 250, by licence | Whatever your hardware handles |
| Message history | 10,000 on Entry | All of it |

## Install

Run the image and everything above is already on:

```bash
docker run -d --name mattermost \
  -e MM_SQLSETTINGS_DRIVERNAME=postgres \
  -e MM_SQLSETTINGS_DATASOURCE="postgres://..." \
  -e MM_SERVICESETTINGS_SITEURL="https://chat.example.com" \
  -p 8065:8065 -p 8443:8443/udp -p 8443:8443/tcp \
  ghcr.io/dennisklappe/mattermore:latest
```

Already running Mattermost and would rather not replace it? Set
`MM_CALLS_GROUP_CALLS_ALLOWED=true` and upload the calls plugin from
[Releases](https://github.com/dennisklappe/mattermore/releases). That covers
everything call-related and takes two minutes.

Full instructions: [mattermore.dev/install](https://mattermore.dev/install).

## How it works

Three mechanisms, all documented rather than hidden.

**Upstream ships some of the switches itself.** Group calls are gated by one
function that also reads an environment variable Mattermost added:

```go
func (e *LicenseChecker) GroupCallsAllowed() bool {
    return e.isAtLeastProfessionalLicensed() ||
        os.Getenv("MM_CALLS_GROUP_CALLS_ALLOWED") == "true"
}
```

**Where nothing exists, we write it.** Single sign-on was not a check to
remove: Mattermost keeps its OpenID Connect provider in a private module, so
Team Edition has no implementation and answers logins with a 501. So Mattermore
contributes one, implementing Mattermost's own four-method interface. It is our
code, under the AGPL, with discovery, standard claims, enforced https and
identity taken from the userinfo response rather than an unverified token.

**Patches, not a diverged branch.** Every change is a patch file applied to a
pinned upstream tag, one per restriction. Picking up an upstream security fix
means bumping one line in `upstream.env`. If a patch stops applying on a new
release it is dropped for that release and everything else still ships.

## Licensing

AGPL-3.0, the same licence as the code this builds on.

Mattermore changes AGPL code only. It does not modify anything under the
Mattermost Source Available Licence, and it goes further than that: upstream's
`server/enterprise` package is compiled into the calls plugin, so a bundle
built from an unmodified tree would redistribute Source Available code.
`patches/calls/0001` replaces it with an independent AGPL implementation, so it
is no longer in the dependency graph at all.

```
go list -deps ./server/ | grep -c server/enterprise   # 0
```

Some restrictions are deliberately left alone. LDAP, SAML and the dedicated
Google and Office365 providers are gated in AGPL code, but their
implementations live in Mattermost's private module. Removing those checks
would produce a menu item that fails at runtime, not a working feature.

See [NOTICE.md](NOTICE.md) and
[mattermore.dev/licensing](https://mattermore.dev/licensing).

## Building it yourself

Needs Go, Node 20+, and podman or docker.

```bash
./scripts/build-calls.sh     # the plugin bundle
./scripts/build-server.sh    # the server binary
./scripts/build-image.sh     # both, as a container image
```

`upstream.env` pins every upstream tag. `patches/README.md` explains the
series and the rules they follow.

## Be fair to Mattermost

They wrote this software and open sourced it. If your organisation can afford
Professional, buying it funds the upstream work that makes a fork like this
possible at all.

Not affiliated with, endorsed by, or supported by Mattermost, Inc.
"Mattermost" is their trademark, used here only to describe compatibility.

# Patches

Each directory holds a patch series applied to a clean checkout of the tag
named in `upstream.env`:

| Directory | Upstream | Produces |
| --- | --- | --- |
| `agents/` | `mattermost/mattermost-plugin-agents` | the Mattermore Agents plugin bundle |
| `calls/` | `mattermost/mattermost-plugin-calls` | the Mattermore calls plugin bundle |
| `playbooks/` | `mattermost/mattermost-plugin-playbooks` | the Mattermore Playbooks plugin bundle |
| `server/` | `mattermost/mattermost` | the Mattermore server binary and image |
| `transcriber/` | `mattermost/calls-transcriber` | the transcriber image |

## One patch per restriction

Every patch is independently appliable to a clean tree. If one stops applying
on a new upstream release, it is dropped for that release and everything else
still ships. A release is never blocked by one broken hunk.

A dropped patch is renamed to `*.patch.disabled`, which the build globs skip,
and goes back to `*.patch` once it is rebased. Currently disabled:
`calls/0002-group-video`. Calls v1.12.5 rewrote the call widget and expanded
view it touches, and a rebase that cannot be browser-tested is not worth
shipping. Group video is DM-only again until it is ported.

Patches delete conditions rather than adding code wherever possible. Removing
an `if` survives upstream refactoring far better than anything else.

## What is never patched

Nothing under a directory carrying `LICENSE.enterprise`, the Mattermost Source
Available Licence. In the server that is `server/enterprise/metrics`,
`elasticsearch` and `message_export/shared`.

The calls plugin went further. Upstream's `server/enterprise` package is
compiled into the plugin binary, so a bundle built from an unmodified tree
would redistribute Source Available code. `calls/0001` replaces it with an
independent AGPL implementation and drops the import, so the package is no
longer in the dependency graph at all:

```
go list -deps ./server/ | grep -c server/enterprise   # 0
```

That is what makes the bundle distributable, and it is the reason that patch
exists at all rather than simply flipping the checks.

The agents plugin has the same problem and gets the same answer.
`agents/0001` adds a `license` package of its own, switches every import to it
under the existing `enterprise` name so each file changes by one line, and
leaves upstream's `enterprise/` directory in the tree but out of the build.
`scripts/build-agents.sh` fails if that package is ever compiled back in. The
tier chart in the new package is the one published in the plugin's own
`docs/admin_guide.md`. A server with no licence installed is treated as having
every tier, while an installed licence still maps to its own.

Playbooks gets the same answer with less to replace. Its licence checker sits
behind the `app.LicenseChecker` interface, and only `server/plugin.go` names
the Source Available implementation, so `playbooks/0001` adds a `license`
package of its own that allows every feature and switches that one import.
Upstream's `server/enterprise` directory stays in the tree but out of the
build, and `scripts/build-playbooks.sh` fails if it is ever compiled back in.
Every Playbooks feature is available at every tier, so a server with no
licence has all of them, and so does one with any licence. Three more small
patches remove checks that were never behind the interface: `0002` the
startup refusal without a Professional licence, `0003` the insights check, and
`0004` the web app's licence level.

## Features whose code does not ship

Some gates are in AGPL code while the implementation lives in Mattermost's
private module: LDAP, SAML, and the dedicated Google, Office365 and OpenID
providers. Removing those checks yields a menu item that fails at runtime, not
a working feature, so they are left alone.

Single sign-on is the exception, and not by patching. `server/0001` is an
OpenID Connect provider written from scratch against Mattermost's own
four-method interface. It is our code, under the AGPL.

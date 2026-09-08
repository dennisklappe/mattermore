# Patches

Each directory holds a patch series applied to a clean checkout of the tag
named in `upstream.env`:

| Directory | Upstream | Produces |
| --- | --- | --- |
| `calls/` | `mattermost/mattermost-plugin-calls` | the Mattermore calls plugin bundle |
| `server/` | `mattermost/mattermost` | the Mattermore server binary and image |
| `transcriber/` | `mattermost/calls-transcriber` | the transcriber image |

## One patch per restriction

Every patch is independently appliable to a clean tree. If one stops applying
on a new upstream release, it is dropped for that release and everything else
still ships. A release is never blocked by one broken hunk.

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

## Features whose code does not ship

Some gates are in AGPL code while the implementation lives in Mattermost's
private module: LDAP, SAML, and the dedicated Google, Office365 and OpenID
providers. Removing those checks yields a menu item that fails at runtime, not
a working feature, so they are left alone.

Single sign-on is the exception, and not by patching. `server/0001` is an
OpenID Connect provider written from scratch against Mattermost's own
four-method interface. It is our code, under the AGPL.

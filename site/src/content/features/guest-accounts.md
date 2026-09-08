---
title: "Guest accounts on self-hosted Mattermost"
description: "How Mattermost guest accounts work, why they need a paid licence, and what lifting that gate on a self-hosted server actually involves."
label: "Guest accounts"
order: 5
---

Guest accounts let you give someone outside your organisation access to a
specific set of channels without handing them the whole team. Contractors,
clients, external collaborators and vendors get a restricted role rather than
an ordinary membership. On a self-hosted server the feature is present in the
open source code but gated behind a paid licence. This page explains what the
feature does, exactly where the gate sits, and what removing it would require.

## Scope: this is a server feature, not a plugin feature

Read this part first, because it decides whether the rest of the page is
relevant to you.

Mattermost guest accounts are implemented in the Mattermost server itself.
They are not part of the Calls plugin. That makes them different from
[group calls](/group-calls), [video calls](/video-calls),
[call recording](/call-recording) and [transcription](/transcription), where a
plugin upload is the whole job.

Lifting the guest accounts gate means running a patched Mattermost server, not
uploading a plugin. In Mattermore terms that is Mattermore Server rather than
the Mattermore calls plugin. It is a genuinely larger commitment: you would be
running our build of Mattermost instead of the official one, which changes how
you handle upgrades, security advisories and your own trust model. Decide that
deliberately.

Nothing here announces availability. For current status, check the
[Mattermore repository](https://github.com/dennisklappe/mattermore).

## What guest accounts actually give you

A guest is a distinct role, not a member with fewer channels. The permission
set is restricted by design:

- Access is limited to the channels a guest is explicitly invited to.
- Guests do not browse the wider team, its channel directory or its user list
  in the way members do.
- Guest permissions are managed separately from member permissions, so you can
  tighten them without touching your normal roles.

The practical use case is narrow and common: you want to invite external users
to Mattermost for one project, one incident or one vendor relationship, and you
do not want that person reading everything else. The alternative without guest
accounts is a separate team or a separate server, both of which cost you more
administration than they save.

## Where the licence gate sits

We checked this in the Mattermost source rather than relying on documentation.
Guest accounts are gated behind a paid licence through the `GuestAccounts`
licence feature flag. The enforcement points are:

- `server/channels/api4/user.go`, lines 2437, 2493 and 3556.
- `server/channels/api4/team.go`, line 1819.
- `server/channels/api4/role.go`, line 196, which covers guest permissions.
- `server/channels/utils/license.go`, line 257, which is what tells the web
  application whether the feature is available.

Every one of those files is AGPL-licensed. That matters for the same reason it
matters throughout [Mattermore's licensing position](/licensing): the AGPL
grants you the right to modify and run modified code, provided you meet its
conditions.

## The implementation genuinely ships in the open source repository

This is the part that makes guest accounts interesting rather than academic.

Some gated Mattermost features have their check in open source code while the
feature itself lives in a private enterprise module. Removing the check there
gets you a menu item that leads nowhere. Guest accounts are not like that. The
guest roles, the database migrations and the application layer are all present
in the open source repository. The gate is a gate, not a stub.

The web application mostly follows automatically, because it gates on the
`EnableGuestAccounts` client property derived from `utils/license.go`. Change
what the server reports and the user interface generally comes along with it.

## Be fair to Mattermost about this

Mattermost open sourced this code under the AGPL. They did not have to. The
freedom to inspect and modify these enforcement points exists precisely because
they published the implementation rather than hiding it behind a binary.

If your organisation can afford a Professional licence, buy one. It funds the
upstream work that everything here depends on, including the parts you would be
patching. Mattermore exists for the case where the licence is genuinely out of
reach, not as a way to avoid paying people who can be paid.

## Frequently asked questions

### Are Mattermost guest accounts free?

No. On a stock server, guest accounts require a paid licence. Searching for a
Mattermost guest account free option on the official builds will not turn one
up, because the `GuestAccounts` licence feature flag gates it.

### Can I use Mattermost guest access self hosted without a licence?

Not with the official server build. Self-hosting does not change the licence
check, which runs server side regardless of how you deploy.

### What licence do I need for Mattermost guest accounts?

A paid Mattermost licence that includes the `GuestAccounts` feature. Check
Mattermost's current plan comparison for which tier that is today, as plan
contents change.

### How do I invite external users to Mattermost without guest accounts?

Give them ordinary member accounts on a dedicated team, or run a separate
server for external collaboration. Both work. Both cost you more ongoing
administration than guests would.

### Does the Mattermore calls plugin enable guest accounts?

No. Guest accounts live in the server, so the plugin cannot affect them. That
would require Mattermore Server, a patched Mattermost build.

### Is the guest accounts code actually in the open source repository?

Yes. The roles, migrations and application layer are all present. The licence
check is the only thing standing between the code and a working feature.

### Where do I start if I want to try this?

Read [Mattermore's licensing position](/licensing) first, then the
[installation guide](/install) and the rest of the [documentation](/docs).
Current status for server-side work lives in the GitHub repository.

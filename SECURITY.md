# Security policy

Mattermore is a rebuild of [mattermost-plugin-calls](https://github.com/mattermost/mattermost-plugin-calls),
not a rewrite of it. Almost all of the code that runs on your server is
upstream code. Where you report a vulnerability depends on which part it is in.

## Vulnerabilities in Mattermost or upstream Calls

If the problem exists in unmodified upstream code, or anywhere in the
Mattermost server itself, report it to Mattermost through their own process:

**https://mattermost.com/security-vulnerability-report/**

They have the maintainers, the release channels, and the coordinated disclosure
process for that code. Reporting it here first only delays the fix reaching
everyone, including the majority of users who do not run Mattermore.

If you are not sure which side a problem is on, report it to Mattermost. A
report that turns out to be Mattermore specific can be forwarded here.

## Vulnerabilities specific to Mattermore

If the problem is in something Mattermore adds, report it privately here:

**https://github.com/dennisklappe/mattermore/security/advisories/new**

That covers:

- The patches in `patches/`, and any behaviour they introduce or change.
- The build scripts in `scripts/`, and the release workflow that produces bundles.
- The published bundles and their `.sha256` files, including anything that
  suggests a release artefact does not match what the patches build.
- The version stamping scheme, if it lets an unexpected plugin replace or be
  replaced by Mattermore.

Please do not open a public issue for these. Use the advisory link, which stays
private until there is a fix.

Useful things to include: the Mattermost server version, the Mattermore
version, how the server is deployed, and the smallest reproduction you have.

## Upstream security fixes

Mattermore builds from a pinned upstream tag, recorded in `upstream.env`. A
scheduled workflow watches upstream and opens an issue when a new stable
release lands, and picking it up is a version bump rather than a merge. That is
the whole reason the changes are kept as patches.

**When upstream ships a security fix, upgrade.** Watch the
[releases](https://github.com/dennisklappe/mattermore/releases) page, or the
[upstream releases](https://github.com/mattermost/mattermost-plugin-calls/releases),
and update your bundle. Running an old Mattermore build means running an old
upstream Calls build, with whatever is known about it.

## What to expect

Mattermore is a volunteer project. There is no security team, no on-call
rotation, and no response time commitment, so it would be dishonest to publish
one. Reports are read and acted on as soon as they can be, and a fix for a real
vulnerability takes priority over everything else in the project. If a report
goes unanswered for longer than you are comfortable with, and it also affects
upstream, send it to Mattermost so it is not sitting with one person.

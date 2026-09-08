# Contributing

## The rule that matters

Every change to upstream code is a patch file in `patches/`, one per
restriction, each independently appliable to a clean checkout of the tag in
`upstream.env`.

That is not bureaucracy. It is what lets a security fix upstream become a
one-line change here instead of a merge, and it means a patch that stops
applying can be dropped for one release without holding up everything else.

Keep patches small. Prefer deleting a condition over adding code: removing an
`if` survives upstream refactoring far better than anything else.

## Never patch

Anything under a directory carrying `LICENSE.enterprise`, the Mattermost
Source Available Licence. If a feature seems to need it, open an issue instead
of working around it. The calls plugin goes further and does not even compile
that package in, see `patches/README.md`.

Also leave alone any gate whose implementation is not in the open repository.
LDAP, SAML and the dedicated Google and Office365 providers are gated in AGPL
code but implemented in a private module, so removing the check produces a
broken menu item rather than a feature.

## Building

```bash
./scripts/build-calls.sh     # plugin bundle
./scripts/build-server.sh    # server binary
./scripts/build-image.sh     # both, as an image
```

Needs Go, Node 20+, and podman or docker.

## The website

`site/` is [mattermore.dev](https://mattermore.dev), an Astro project.
Documentation and feature pages are markdown in `site/src/content/`. Editing
those is the most useful contribution most people can make, and it needs no
Go toolchain.

## Picking up a new upstream release

A scheduled workflow opens an issue when any upstream publishes a stable
release, and says whether the patches still apply. To ship it, bump the tag in
`upstream.env`, confirm the build, and push a tag.

## No em dashes

Anywhere. Commit messages, comments, docs, the website. Use a comma, brackets,
a colon or a full stop.

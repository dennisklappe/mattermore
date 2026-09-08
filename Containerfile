# Mattermore: Mattermost with the paywalled features turned back on.
#
# Built on the official Team Edition image. Three things change: the server
# binary, the web app, and the calls plugin.

FROM docker.io/mattermost/mattermost-team-edition:latest AS upstream

# The guest administration screens and the licence badges live in the web app,
# so upstream's prebuilt one has to be replaced or those two patches do nothing
# at all.
#
# COPY merges rather than replaces, and the base image has no shell to delete
# with, so upstream's bundles would otherwise linger: unreachable, because
# every filename is content hashed and our root.html references only ours, but
# still around 87 MB. This stage empties them, so nothing stale is reachable.
# It does not shrink the image: layers are additive, so the base layer keeps
# the originals either way.
FROM docker.io/library/alpine:3.20 AS webapp
COPY --from=upstream /mattermost/client /old
COPY client /new
RUN set -eu; \
    mkdir -p /out; \
    cp -a /new/. /out/; \
    cd /old; \
    find . -type f | while read -r f; do \
        if [ ! -e "/out/$f" ]; then \
            mkdir -p "/out/$(dirname "$f")"; \
            : > "/out/$f"; \
        fi; \
    done

FROM docker.io/mattermost/mattermost-team-edition:latest

COPY --chown=2000:2000 mattermore-server /mattermost/bin/mattermost
COPY --from=webapp --chown=2000:2000 /out /mattermost/client

# The plugin ships as a prepackaged bundle. Upstream refuses one without a
# signature made with Mattermost's key, which no third party can produce, so
# patches/server/0007 makes the signature optional for prepackaged plugins
# while still verifying one that is present. RequirePluginSignature continues
# to govern administrator uploads, which is a different trust boundary.
#
# Upstream's own calls bundle is removed rather than left to lose on version.
# Winning on version describes where a start ends up, not how it gets there:
# with both bundles present the server installs upstream's first and then has
# to remove it again to put ours in its place. That removal is not guaranteed
# to succeed. When it fails the plugin directory is left holding an orphan
# webapp folder, the install is abandoned, and the server comes up with NO
# calls plugin at all, which is the one thing this image exists to provide.
#
#   Removing existing installation of plugin before local install (1.12.2)
#   removePlugin: unlinkat plugins/com.mattermost.calls: directory not empty
#
# One bundle per plugin id means there is no replacement step to fail.
COPY --chown=2000:2000 mattermore-calls.tar.gz /mattermost/prepackaged_plugins/mattermore-calls-linux-amd64.tar.gz
RUN rm -f /mattermost/prepackaged_plugins/mattermost-plugin-calls-v*.tar.gz \
          /mattermost/prepackaged_plugins/mattermost-plugin-calls-v*.tar.gz.sig

# Group calls are switched on by upstream's own environment variable.
ENV MM_CALLS_GROUP_CALLS_ALLOWED=true

LABEL org.opencontainers.image.title="Mattermore" \
      org.opencontainers.image.description="Mattermost with the paywalled features turned back on" \
      org.opencontainers.image.url="https://mattermore.dev" \
      org.opencontainers.image.source="https://github.com/dennisklappe/mattermore" \
      org.opencontainers.image.licenses="AGPL-3.0-only"

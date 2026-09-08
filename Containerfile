# Mattermore: Mattermost with the paywalled features turned back on.
#
# Built on the official Team Edition image. Two things change: the server
# binary and the calls plugin.
#
# The plugin ships as a prepackaged bundle, which upstream normally refuses
# without a signature made with Mattermost's own key. patches/server/0007
# changes that: a signature is still verified when present, but a prepackaged
# plugin without one is installed on the trust of the image it ships in, which
# is the same trust already placed in the binary beside it. RequirePluginSignature
# still governs administrator uploads, which is a different question.
#
# The stock calls bundle is left in place deliberately. Ours is version
# 1000.12.3 and wins on version, so there is nothing to delete.

FROM docker.io/mattermost/mattermost-team-edition:latest

COPY --chown=2000:2000 mattermore-server /mattermost/bin/mattermost

# The guest administration screens and the licence badges live in the web app,
# so the prebuilt one upstream ships has to be replaced or those patches do
# nothing at all.
COPY --chown=2000:2000 client /mattermost/client
COPY --chown=2000:2000 mattermore-calls.tar.gz /mattermost/prepackaged_plugins/mattermore-calls-linux-amd64.tar.gz

# Group calls are switched on by upstream's own environment variable.
ENV MM_CALLS_GROUP_CALLS_ALLOWED=true

LABEL org.opencontainers.image.title="Mattermore" \
      org.opencontainers.image.description="Mattermost with the paywalled features turned back on" \
      org.opencontainers.image.url="https://mattermore.dev" \
      org.opencontainers.image.source="https://github.com/dennisklappe/mattermore" \
      org.opencontainers.image.licenses="AGPL-3.0-only"

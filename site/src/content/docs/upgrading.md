---
title: "Upgrading"
description: "How to upgrade Mattermore, why it survives a Mattermost server upgrade, how to check which build is installed, and how to roll back to official Calls."
order: 5
---

## Upgrading Mattermore

There is no data migration and no state to convert. Upgrading is a download, a
checksum check, and an upload over the top of the running plugin.

```bash
curl -LO https://github.com/dennisklappe/mattermore/releases/latest/download/mattermore.tar.gz
curl -LO https://github.com/dennisklappe/mattermore/releases/latest/download/mattermore.tar.gz.sha256
sha256sum -c mattermore.tar.gz.sha256
```

Then in **System Console › Plugins › Plugin Management**, choose **Upload
Plugin** and select the file. The server replaces the existing plugin in place
and restarts it.

Notes:

- Verify the checksum before you upload, every time. It is the only integrity
  check you get on an unsigned bundle. See
  [Configuration](/configuration) for why that matters.
- The plugin restarts, which drops any call in progress. Upgrade outside
  working hours if that is a problem.
- Your plugin settings are keyed to the plugin id, which does not change, so
  `MaxCallParticipants` and the rest survive the upgrade untouched.
- `MM_CALLS_GROUP_CALLS_ALLOWED` is a server variable, so a plugin upgrade
  does not affect it.

If the upload is rejected, signature verification is on. That is a
configuration question, not an upgrade question, and it is covered in
[Configuration](/configuration).

## Version numbers

Mattermore versions are `1000.<upstream>`. Upstream `v1.12.3` is released as
Mattermore `1000.12.3`.

The `1000.` prefix is deliberate. Mattermost ships Calls as a prepackaged
plugin, and on startup the server reinstalls its prepackaged copy over an
installed plugin only when the prepackaged version is strictly higher. That
check is `shouldPersistTransitionallyPrepackagedPlugin` in
`server/channels/app/plugin.go`.

Versioning above anything upstream will realistically ship means the comparison
never favours the prepackaged copy, so a server upgrade cannot silently revert
you to official Calls. Read the second part of the version as the upstream
release Mattermore is built from.

## Upgrading the Mattermost server underneath

Upgrade the server the way you normally would. Mattermore needs no special
handling:

```bash
docker compose pull
docker compose up -d
```

Mattermore survives it for the reason above: the incoming prepackaged Calls
plugin has a lower version number, so the server leaves the installed plugin
alone.

Check these four things afterwards:

1. **The plugin is still enabled.** System Console › Plugins › Plugin
   Management. A plugin can be disabled by a failed startup.
2. **It still reports as Mattermore**, not official Calls. See the next
   section.
3. **The environment variable survived.** Package upgrades and rebuilt
   containers are where this gets lost:

    ```bash
    docker compose exec mattermost env | grep MM_CALLS
    ```

4. **A three-person call still works.** Two participants work on stock
   Mattermost, so a two-person test proves nothing.

If a major Mattermost release changes the plugin API, an older Mattermore build
can fail to start against a much newer server. Check the
[releases page](https://github.com/dennisklappe/mattermore/releases) for a build
tracking a newer upstream version before you upgrade a long-untouched server.

## Checking which build is installed

Go to **System Console › Plugins › Calls**. The plugin reports itself as
**Calls (Mattermore)**. Official Calls reports as **Calls**.

The version shown next to it tells you the rest: a `1000.` prefix is
Mattermore, anything else is upstream.

If it says **Calls** without the suffix, you are running official Calls, group
calls will be limited to two participants regardless of your environment
variable, and something reinstalled the prepackaged plugin. Upload the
Mattermore bundle again, and consider setting
`PluginSettings.AutomaticPrepackagedPlugins` to `false` as described in
[Configuration](/configuration).

## Rolling back to official Calls

Nothing is one-way. To go back:

1. In **System Console › Plugins › Plugin Management**, remove the Calls
   plugin.
2. Restart Mattermost. The server reinstalls its prepackaged official Calls
   plugin, because there is no longer a higher-versioned plugin in place.
3. Remove `MM_CALLS_GROUP_CALLS_ALLOWED` from the server environment. It has no
   effect without a plugin that honours it, but leaving stale configuration
   behind helps nobody.
4. If you set `AutomaticPrepackagedPlugins: false`, set it back to `true`, or
   the prepackaged plugin will not be installed in step 2.
5. If you set `RequirePluginSignature: false` only for Mattermore, turn it back
   on.

Calls made through Mattermore leave no records that official Calls cannot read.
Both use the same plugin id and the same storage, so channel and call history
is unaffected by the swap in either direction.

## Related pages

- [Configuration](/configuration) for the settings referenced here.
- [Install guide](/install) for a first-time installation.
- [Troubleshooting](/troubleshooting) if calls break after an upgrade.
- [Licensing and legality](/licensing) for the licence position.

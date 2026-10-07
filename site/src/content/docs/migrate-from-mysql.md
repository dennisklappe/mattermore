---
title: "Migrate from MySQL"
description: "Move Mattermost v10 on MySQL to the Mattermore image on PostgreSQL: the commands that were run, the checks that passed and how to roll back."
order: 3.5
---

Mattermost v11 and Mattermore only run on PostgreSQL. If your server is
Mattermost Team Edition v10 on MySQL, the data has to move first. This page is
the route that was run end to end and checked. It follows Mattermost's own
[migration guide](https://docs.mattermost.com/deployment-guide/postgres-migration.html)
(the `migration-assist` and `pgloader` method) and adds the last part: starting
the Mattermore image on the result.

## What was tested

- Source: `mattermost/mattermost-team-edition:10.11.24` on MySQL 8.0.46, with 304
  users, 2 teams, 8 channels, 880 posts, a file upload, a reaction, 3 bots and
  an incoming webhook.
- Target: `ghcr.io/dennisklappe/mattermore:latest` (Mattermost 11.11.1) with
  the `compose.yaml` from the [self-host guide](/selfhost) on PostgreSQL 17.
- Tools: `migration-assist` v0.8 and the `mattermost/mattermost-pgloader:latest`
  Docker image, on Debian 13 with Docker.

A direct hop from v10.11 to v11 worked. There was no intermediate PostgreSQL
step on v10: the v10.11 schema was created on PostgreSQL, the data was loaded,
and Mattermore ran its own schema upgrade when it started. A small database
like this one says nothing about timing, so rehearse on a copy of yours.

## 1. Back up first

Do all of this before you touch anything. Stop Mattermost so the dump is
consistent, but leave MySQL running.

```bash
docker compose stop mattermost          # your old v10 service, name may differ
mysqldump --single-transaction -u root -p mattermost > mattermost-mysql-backup.sql
```

Also keep the file storage and the config. The data directory holds uploads:

```bash
# named volume (replace the volume name with yours)
docker run --rm -v old_mmdata:/d alpine tar czf - -C /d . > mmdata-backup.tgz
# and keep a copy of config.json
```

Your MySQL database itself is never modified by the steps below, which is what
makes the rollback below work. Keep it until you are happy.

## 2. Make MySQL usable by pgloader

`pgloader` cannot log in to MySQL 8 with the default `caching_sha2_password`
plugin. Mattermost's guide says to switch the migration user to
`mysql_native_password`:

```sql
ALTER USER 'mmuser'@'%' IDENTIFIED WITH mysql_native_password BY 'your-password';
```

In the test the MySQL server was started with
`--default-authentication-plugin=mysql_native_password`, so this statement was
not exercised. Do it before step 4 if your user uses the default plugin.

## 3. Start only PostgreSQL

Take `compose.yaml` and `.env` from the [self-host guide](/selfhost) (or this
repository), then publish the database port locally for the migration with a
`compose.override.yaml`:

```yaml
services:
  postgres:
    ports:
      - "127.0.0.1:5432:5432"
```

```bash
docker compose up -d postgres
```

Install `migration-assist` (Linux x86_64 shown, other platforms are on the
[releases page](https://github.com/mattermost/migration-assist/releases)):

```bash
curl -sL https://github.com/mattermost/migration-assist/releases/download/v0.8/migration-assist-Linux-x86_64.tar.gz \
  | sudo tar xz -C /usr/local/bin migration-assist
```

It needs `git` on the machine, because it fetches the migration files of the
Mattermost version you name.

Set the two connection strings used below. Adjust host, user and passwords:

```bash
M="mmuser:mmpass@tcp(127.0.0.1:3306)/mattermost"
P="postgres://mmuser:mmpass@127.0.0.1:5432/mattermost?sslmode=disable"
```

## 4. Check the MySQL schema

```bash
migration-assist mysql "$M"
```

Here every check (artifacts, unicode, varchar, varchar-extended) reported
"all good". If yours reports problems, the tool prints the fix flags
(`--fix-artifacts`, `--fix-unicode`, `--fix-varchar`). Those were not needed
and so were not run.

## 5. Create the PostgreSQL schema

The migration user must own the `public` schema. The official `postgres` image
makes `mmuser` a superuser but not the schema owner, and without this step
`migration-assist` stops with
`the user "mmuser" is not owner of the "public" schema`:

```bash
docker compose exec -T postgres psql -U mmuser -d mattermost \
  -c "ALTER SCHEMA public OWNER TO mmuser; GRANT ALL ON SCHEMA public TO mmuser;"
```

Then create the schema. `--mattermost-version` must be the version your MySQL
server was running, not the one you are moving to:

```bash
migration-assist postgres "$P" --run-migrations --mattermost-version=10.11.24
```

## 6. Generate the pgloader config

```bash
migration-assist pgloader --mysql="$M" --postgres="$P" --remove-null-chars > migration.load
```

The generated file, with the test passwords, was:

```
LOAD DATABASE
    FROM       mysql://mmuser:mmpass@127.0.0.1:3306/mattermost
    INTO       pgsql://mmuser:mmpass@127.0.0.1:5432/mattermost

WITH data only,
    workers = 8, concurrency = 1,
    multiple readers per thread, rows per range = 10000,
    prefetch rows = 10000, batch rows = 2500,
    create no tables, create no indexes,
    preserve index names

SET PostgreSQL PARAMETERS
    maintenance_work_mem to '128MB',
    work_mem to '12MB'

SET MySQL PARAMETERS
    net_read_timeout  = '120',
    net_write_timeout = '120'

 CAST column Channels.Type to "channel_type" drop typemod,
    column Teams.Type to "team_type" drop typemod,
    column UploadSessions.Type to "upload_session_type" drop typemod,
    column ChannelBookmarks.Type to "channel_bookmark_type" drop typemod,
    column Drafts.Priority to text,
    type int when (= precision 11) to integer drop typemod,
    type bigint when (= precision 20) to bigint drop typemod,
    type text to varchar drop typemod using remove-null-characters,
    type tinyint when (<= precision 4) to boolean using tinyint-to-boolean,
    type json to jsonb drop typemod using remove-null-characters

EXCLUDING TABLE NAMES MATCHING ~<IR_>, ~<focalboard>, ~<calls>, 'schema_migrations', 'db_migrations', 'db_lock',
    'configurations', 'configurationfiles', 'db_config_migrations'

BEFORE LOAD DO
    $$ ALTER SCHEMA public RENAME TO mattermost; $$,
    $$ TRUNCATE TABLE mattermost.systems; $$,
    $$ DROP INDEX IF EXISTS mattermost.idx_posts_message_txt; $$,
    $$ DROP INDEX IF EXISTS mattermost.idx_fileinfo_content_txt; $$

AFTER LOAD DO
    $$ UPDATE mattermost.db_migrations set name='add_createat_to_teamembers' where version=92; $$,
    $$ ALTER SCHEMA mattermost RENAME TO public; $$,
    $$ SELECT pg_catalog.set_config('search_path', '"$user", public', false); $$,
    $$ ALTER USER mmuser SET search_path TO "$user", public; $$;
```

Use the file your own `migration-assist` generates rather than this copy. It
is shown so you know what to expect. Note the `EXCLUDING` line: the Playbooks,
Boards and Calls plugin tables are not part of this load (see "Not covered").

## 7. Load the data

Mattermost's page names the image `mattermost/pgloader`, which does not exist
on Docker Hub. The one that exists, and that was used here, is
`mattermost/mattermost-pgloader`:

```bash
docker run --rm --network host -v "$PWD:/home/migration" \
  mattermost/mattermost-pgloader:latest pgloader /home/migration/migration.load \
  > migration.log 2>&1
echo $?
```

It exited 0. The log lists a number of `WARNING` lines such as
`Source column ... is casted to type "varchar" which is not the same as "text"`.
In this run all of them were type notes and the data loaded. Read your own log
for lines containing `ERROR`, and do not continue if there are any.

Then rebuild the full-text indexes:

```bash
migration-assist postgres post-migrate --create-indexes "$P"
```

Compare the row counts. In the test these matched exactly, MySQL against
PostgreSQL, for users, teams, channels, posts, file info, reactions, bots,
incoming webhooks, team members and channel members:

```bash
# MySQL
mysql -u root -p -N mattermost -e "select count(*) from Users; select count(*) from Posts;"
# PostgreSQL
docker compose exec -T postgres psql -U mmuser mattermost -At \
  -c "select count(*) from users; select count(*) from posts;"
```

## 8. Move the files and config, then start Mattermore

Copy the uploads into the Mattermore data volume and give them to the user the
image runs as (uid 2000). The volume name is the compose project name plus the
volume, `mattermore_mattermost-data` for the stack in this repository:

```bash
docker compose create mattermore
docker run --rm -v old_mmdata:/from -v mattermore_mattermost-data:/to alpine \
  sh -c 'cp -a /from/. /to/ && chown -R 2000:2000 /to'
```

The old `config.json` was copied across as well, and Mattermore started fine
with it. The database settings in `compose.yaml` are environment variables,
which take priority over the file, so the old MySQL `DataSource` in it is
ignored:

```bash
docker run --rm -v old_mmconfig:/from -v mattermore_mattermost-config:/to alpine \
  sh -c 'cp -a /from/config.json /to/ && chown -R 2000:2000 /to'
```

Remove the `compose.override.yaml` port again if you do not want PostgreSQL
published, then start everything:

```bash
docker compose up -d
```

The first start takes a little longer: the server upgrades the v10.11 schema to
v11 itself.

## What was checked afterwards

All of this passed against the migrated database:

- The server reports version 11.11.1, and the log showed no errors apart from a
  plugin notice that `ffmpeg` is not installed.
- An old user (`user77`) logs in with the old password. The old admin account
  logs in.
- User count 304, team member counts 151 and 101, channel post count and the
  last 61 messages of a channel, including emoji and Japanese text.
- The post with the attachment still shows its file, the file downloads with
  the original content, and the reaction is still on the post.
- Search finds an old post.
- **System Console › Plugins** lists `com.mattermost.calls` as
  **Calls (Mattermore)**, version `1000.12.3`.
- Creating a new user worked, taking the server to 305 users. That is past the
  250 limit of the official image.

## Rolling back

Nothing in steps 3 to 8 writes to MySQL or to the old data volume, because the
files were copied, not moved. To go back:

```bash
docker compose stop mattermore
# start your old v10 stack again, against MySQL
```

This was tried: the old v10.11.24 server started on the untouched MySQL
database and showed the same 304 users. What you lose by rolling back is
anything that happened on Mattermore after the cutover, such as new posts and
new users. Those exist only in PostgreSQL. If you need them, export them
first.

## Not covered

- The Playbooks, Boards (Focalboard) and Calls plugin tables. The generated
  config excludes them, and `migration-assist pgloader boards|playbooks|calls`
  can generate separate loads, but these were not run. Call history from the
  old server was not moved.
- Configuration stored in the database instead of `config.json`. Mattermost
  says it is not migrated.
- Servers older than v10, or direct hops from them. Mattermost's own guide
  requires at least a v7.1 schema.
- MariaDB, MySQL 5.7 and MySQL with the default `caching_sha2_password` plugin
  (see step 2).
- Large databases. Memory, run time and the `prefetch rows = 1000` advice for
  heap errors in Mattermost's guide were not exercised on 880 posts.
- Incoming webhooks that post to mixed-case channel names. MySQL matched them
  case-insensitively and PostgreSQL does not. Mattermost lists this under
  troubleshooting.
- Clusters, Elasticsearch or OpenSearch indexes, SSO and LDAP users, and
  external file storage such as S3.
- Setting up TLS, DNS or the calls ports for the new server. The
  [self-host guide](/selfhost) covers those.

## Related pages

- [Self-host from scratch](/selfhost), the stack this page migrates into.
- [Upgrading](/upgrading), for later updates.
- [Troubleshooting](/troubleshooting).

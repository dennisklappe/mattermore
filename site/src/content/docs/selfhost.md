---
title: "Self-host from scratch"
description: "A complete Docker Compose stack running Mattermost, PostgreSQL and Mattermore, with group calls working from the first boot."
order: 3
---

If you already run Mattermost, you do not need this page. Use the
[install guide](/install) instead, which is two steps on an existing server.

## What you need

- A Linux host with Docker and the Compose plugin
- A domain pointing at it, if you want TLS
- UDP port 8443 open, plus TCP 8443 as a fallback, or calls will connect and then drop

## 1. Create the stack

Make a directory and save this as `compose.yaml`:

```yaml
services:
  postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: mmuser
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?set POSTGRES_PASSWORD in .env}
      POSTGRES_DB: mattermost
    volumes:
      - postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U mmuser -d mattermost"]
      interval: 10s
      timeout: 5s
      retries: 5

  mattermost:
    image: mattermost/mattermost-team-edition:latest
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      MM_SQLSETTINGS_DRIVERNAME: postgres
      MM_SQLSETTINGS_DATASOURCE: >-
        postgres://mmuser:${POSTGRES_PASSWORD}@postgres:5432/mattermost?sslmode=disable&connect_timeout=10
      MM_SERVICESETTINGS_SITEURL: ${SITE_URL:?set SITE_URL in .env}

      # This is what enables group calls. Mattermost reads it in the calls
      # plugin's own licence check.
      MM_CALLS_GROUP_CALLS_ALLOWED: "true"
    ports:
      - "8065:8065"
      - "8443:8443/udp"
      - "8443:8443/tcp"
    volumes:
      - mm-config:/mattermost/config
      - mm-data:/mattermost/data
      - mm-logs:/mattermost/logs
      - mm-plugins:/mattermost/plugins
      - mm-client-plugins:/mattermost/client/plugins

volumes:
  postgres:
  mm-config:
  mm-data:
  mm-logs:
  mm-plugins:
  mm-client-plugins:
```

Then a `.env` beside it:

```
POSTGRES_PASSWORD=use-a-long-random-string-here
SITE_URL=https://chat.example.com
```

`SITE_URL` must match the address people actually type. Calls will not connect
if it is wrong, and it is the single most common cause of a broken setup.

## 2. Start it

```
docker compose up -d
```

Open `SITE_URL` and create the first account. That account becomes the system
administrator.

## 3. Install Mattermore

Download the latest bundle and verify it:

```
curl -LO https://github.com/dennisklappe/mattermore/releases/latest/download/mattermore.tar.gz
curl -LO https://github.com/dennisklappe/mattermore/releases/latest/download/mattermore.tar.gz.sha256
sha256sum -c mattermore.tar.gz.sha256
```

Then in Mattermost, go to **System Console › Plugins › Plugin Management**,
choose **Upload Plugin**, and select the file. Enable it if it does not enable
itself.

Mattermore uses the same plugin id as the official calls plugin, so it replaces
it in place.

## 4. Check it works

1. Open a channel that is not a direct message
2. The call button appears in the channel header
3. Start a call and have two colleagues join

Three participants is the test that matters. Two would work on stock Mattermost
as well.

## Putting it behind TLS

Mattermost serves plain HTTP on 8065. Terminate TLS in front of it, and make
sure WebSocket upgrades pass through. A minimal Caddy config:

```
chat.example.com {
    reverse_proxy localhost:8065
}
```

Leave port 8443 alone. Calls media does not go through the reverse proxy, it
talks to the server directly on 8443, so that port must reach the host without
translation.

## Firewall

```
sudo ufw allow 443/tcp
sudo ufw allow 8443/udp
sudo ufw allow 8443/tcp
```

If calls join and then drop after a few seconds, it is almost always 8443.

## Backups

Two things matter, and one of them is easy to forget:

```
docker compose exec postgres pg_dump -U mmuser mattermost | gzip > mattermost-$(date +%F).sql.gz
docker run --rm -v mm-data:/data -v "$PWD:/backup" alpine tar czf /backup/mm-data-$(date +%F).tar.gz /data
```

The database holds your messages. The data volume holds uploaded files. A
backup of one without the other restores to a broken server.

## Upgrading

```
docker compose pull
docker compose up -d
```

Mattermore survives this. Mattermost reinstalls its own prepackaged calls
plugin only when the prepackaged version is higher than what is installed, and
Mattermore versions itself above anything upstream ships.

## Troubleshooting

**Call button missing in channels.** The environment variable is not reaching
the server. Check inside the container, not from your own shell:

```
docker compose exec mattermost env | grep MM_CALLS
```

**Calls connect then drop.** Port 8443, or a `SITE_URL` that does not match the
address people use.

**Plugin upload rejected.** Plugin signature verification is on. See the
[install guide](/install#signature) for what turning it off means before
you turn it off.

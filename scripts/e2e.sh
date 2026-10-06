#!/usr/bin/env bash
#
# Runs a built Mattermore image for real and checks what the docs promise:
# more than 250 users can be created, and the calls plugin that ships in it is
# ours and is running.
#
# Usage: ./scripts/e2e.sh [image]
# Requires: docker.

set -euo pipefail

IMAGE="${1:-mattermore:dev}"
USERS="${USERS:-255}"          # the upstream hard limit is 250
RUN="mm-e2e-$$"
PW='Passw0rd1234!'

cleanup() { docker rm -f "$RUN-mm" "$RUN-db" >/dev/null 2>&1 || true; docker network rm "$RUN" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker network create "$RUN" >/dev/null
docker run -d --name "$RUN-db" --network "$RUN" \
    -e POSTGRES_USER=mmuser -e POSTGRES_PASSWORD=pw -e POSTGRES_DB=mattermost \
    docker.io/library/postgres:17-alpine >/dev/null
for _ in $(seq 1 30); do
    docker exec "$RUN-db" pg_isready -U mmuser -d mattermost >/dev/null 2>&1 && break; sleep 2
done

docker run -d --name "$RUN-mm" --network "$RUN" \
    -e MM_SQLSETTINGS_DRIVERNAME=postgres \
    -e MM_SQLSETTINGS_DATASOURCE="postgres://mmuser:pw@$RUN-db:5432/mattermost?sslmode=disable&connect_timeout=10" \
    -e MM_SERVICESETTINGS_SITEURL=http://localhost:8065 \
    "$IMAGE" >/dev/null

mmctl() { docker exec "$RUN-mm" /mattermost/bin/mmctl --local "$@"; }

echo "==> waiting for the server"
for _ in $(seq 1 60); do mmctl system version >/dev/null 2>&1 && break; sleep 3; done
mmctl system version >/dev/null || { docker logs --tail 40 "$RUN-mm"; echo "server never came up" >&2; exit 1; }

echo "==> creating $USERS users"
created=0
for i in $(seq 1 "$USERS"); do
    if err="$(mmctl user create --email "e2e$i@example.com" --username "e2e$i" --password "$PW" 2>&1)"; then
        created=$((created + 1))
    else
        echo "user $i refused: $err" >&2; break
    fi
done
[ "$created" -eq "$USERS" ] || { echo "FAIL: only $created of $USERS users created" >&2; exit 1; }

echo "==> checking the calls plugin"
# The output lists enabled plugins first, then disabled ones.
enabled="$(mmctl plugin list | awk '/^Listing disabled/ {exit} {print}')"
echo "$enabled"
grep -q "com.mattermost.calls: Calls (Mattermore)" <<<"$enabled" \
    || { echo "FAIL: Mattermore calls plugin is not enabled" >&2; exit 1; }

echo "PASS: $created users created, calls plugin enabled"

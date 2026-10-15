set -e
mm() { docker exec mattermore-mattermore-1 /mattermost/bin/mmctl --local "$@"; }
for i in $(seq 1 60); do mm system version >/dev/null 2>&1 && break; sleep 3; done
mm system version
mm user create --email admin@example.com --username admin --password 'Passw0rd1234!' --system-admin
mm user create --email u1@example.com --username u1 --password 'Passw0rd1234!'
mm user create --email u2@example.com --username u2 --password 'Passw0rd1234!'
mm team create --name t1 --display-name T1 --email admin@example.com
mm team users add t1 admin u1 u2
mm channel create --team t1 --name town --display-name Town || true
mm channel users add t1:town admin u1 u2
mm post create t1:town --message "seed post before upgrade" 
echo SEEDED

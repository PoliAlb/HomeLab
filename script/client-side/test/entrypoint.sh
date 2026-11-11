#!/bin/bash
set -euo pipefail

# Rendere risolvibile netbird.home.arpa (come nella guida: riga in /etc/hosts)
if [ -n "${NB_SERVER_IP:-}" ] && ! grep -q 'netbird\.home\.arpa' /etc/hosts; then
    echo "$NB_SERVER_IP  netbird.home.arpa" >> /etc/hosts
fi

# Avvia il demone NetBird (in una VM/PC lo farebbe systemd)
netbird service run &
DAEMON_PID=$!
trap 'netbird down 2>/dev/null || true; kill "$DAEMON_PID" 2>/dev/null || true' TERM INT

# Attendi il socket del demone
for _ in $(seq 1 30); do
    [ -S /var/run/netbird.sock ] && break
    sleep 1
done

# Come nella guida: netbird up --management-url ... [--setup-key ...]
# Senza setup key stampa il link di login SSO da aprire nel browser (vedi `docker logs`).
if [ -n "${NB_SETUP_KEY:-}" ]; then
    netbird up --management-url "$NB_MANAGEMENT_URL" --setup-key "$NB_SETUP_KEY"
else
    netbird up --management-url "$NB_MANAGEMENT_URL"
fi

netbird status || true

# Tieni vivo il container: i test si fanno con `docker exec`
wait "$DAEMON_PID"
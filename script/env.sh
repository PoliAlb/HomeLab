#!/usr/bin/env bash
# Genera lab/.env e netbird/.env, ognuno con le sole variabili che i suoi servizi leggono.
# Non sovrascrive i file esistenti.
set -euo pipefail
cd "$(dirname "$0")"

NB_HOST=netbird.home.arpa
rand() { openssl rand -hex 24; }

# Scrive stdin in $1 (permessi 600), a meno che il file esista già.
write_env() {
  local f=$1
  if [ -e "$f" ]; then
    echo "$f esiste già: non l'ho toccato"
    cat >/dev/null
    return
  fi
  ( umask 077; cat > "$f" )
  echo "creato $f"
}

# ---------------------------------------------------------------- lab/homelab.yml
write_env lab/.env <<EOT
LAB_DOMAIN=lab.internal
DOCKER_SOCK=/run/user/$(id -u)/docker.sock
PASSBOLT_DB_PASSWORD=$(rand)
GITLAB_DB_PASSWORD=$(rand)
NEXTCLOUD_DB_PASSWORD=$(rand)
GITLAB_ROOT_EMAIL=tu@example.com
GITLAB_ROOT_PASSWORD=$(rand)
NEXTCLOUD_ADMIN_PASSWORD=$(rand)
PIHOLE_PASSWORD=$(rand)
# Beszel: da compilare dopo il primo avvio dell'hub (Add system -> KEY e TOKEN)
BESZEL_KEY=""
BESZEL_TOKEN=
EOT

# ------------------------------------------------ netbird/netbird.yml e peer.yml
write_env netbird/.env <<EOT
NB_SERVER_HOST=${NB_HOST}
NB_AUTH_SECRET='$(openssl rand -base64 32)'
NB_ENCRYPTION_KEY='$(openssl rand -base64 32)'
NB_MANAGEMENT_URL=https://${NB_HOST}:8443
# da compilare dopo aver avviato il server NetBird (setup key del peer)
NB_SETUP_KEY=
EOT
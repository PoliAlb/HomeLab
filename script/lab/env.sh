#!/usr/bin/env bash
# Genera un unico .env (accanto a questo script) per laboratorio e server NetBird.
# Non sovrascrive un .env esistente.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p ../netbird && ln -sfn ../lab/.env ../netbird/.env

NB_HOST=netbird.home.arpa

if [ -e .env ]; then
  echo ".env esiste già: non l'ho toccato"
  exit 0
fi

DOZZLE_PW=$(openssl rand -hex 12)
DOZZLE_HASH=$(docker run --rm amir20/dozzle:v11.3.5 generate admin \
  --password "$DOZZLE_PW" --email admin@example.com --name Admin \
  | awk '/password:/{print $2}')

cat > .env <<EOT
# ---------------------------------------------------------------- laboratorio
LAB_DOMAIN=lab.internal
DOCKER_SOCK=/run/user/$(id -u)/docker.sock
PASSBOLT_DB_PASSWORD=$(openssl rand -hex 24)
GITLAB_DB_PASSWORD=$(openssl rand -hex 24)
NEXTCLOUD_DB_PASSWORD=$(openssl rand -hex 24)
GITLAB_ROOT_EMAIL=tu@example.com
GITLAB_ROOT_PASSWORD=$(openssl rand -hex 24)
NEXTCLOUD_ADMIN_PASSWORD=$(openssl rand -hex 24)
PIHOLE_PASSWORD=$(openssl rand -hex 24)
DOZZLE_ADMIN_EMAIL=admin@example.com
DOZZLE_ADMIN_HASH='${DOZZLE_HASH}'
DOZZLE_ADMIN_PASSWORD=${DOZZLE_PW}

# ------------------------------------------------------------- server NetBird
NB_SERVER_HOST=${NB_HOST}
NB_AUTH_SECRET='$(openssl rand -base64 32)'
NB_ENCRYPTION_KEY='$(openssl rand -base64 32)'

# ------------------------------------------------------- peer del laboratorio
NB_MANAGEMENT_URL=https://${NB_HOST}:8443
# da compilare dopo aver avviato il server NetBird (vedi istruzioni sotto)
NB_SETUP_KEY=
EOT
chmod 600 .env

cat <<EOT
EOT
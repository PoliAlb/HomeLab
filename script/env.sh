if [ -e script/.env ]; then echo "script/.env esiste già"; else
  DOZZLE_PW=$(openssl rand -hex 12)
  DOZZLE_HASH=$(docker run --rm amir20/dozzle generate admin \
    --password "$DOZZLE_PW" --email admin@example.com --name Admin \
    | awk '/password:/{print $2}')

  cat > script/.env <<EOF
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
EOF
  chmod 600 script/.env
fi
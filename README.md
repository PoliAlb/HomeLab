# HomeLab

```bash
docker compose exec passbolt su -m -c "/usr/share/php/passbolt/bin/cake \
  passbolt register_user \
  -u tuaemail@example.com \
  -f Nome \
  -l Cognome \
  -r admin" -s /bin/sh www-data
```

```bash
cat > .env <<EOF
POSTGRES_ADMIN_PASSWORD=$(openssl rand -hex 24)
PASSBOLT_DB_PASSWORD=$(openssl rand -hex 24)
GITLAB_DB_PASSWORD=$(openssl rand -hex 24)
NEXTCLOUD_DB_PASSWORD=$(openssl rand -hex 24)
NEXTCLOUD_ADMIN_PASSWORD=$(openssl rand -hex 16)
EOF
```
# Passbolt in Docker

```bash
cat > .env <<EOF
POSTGRES_ADMIN_PASSWORD=$(openssl rand -hex 24)
PASSBOLT_DB_PASSWORD=$(openssl rand -hex 24)
GITLAB_DB_PASSWORD=$(openssl rand -hex 24)
EOF
```
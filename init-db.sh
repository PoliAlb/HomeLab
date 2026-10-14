#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
  CREATE USER passbolt WITH PASSWORD '$PASSBOLT_DB_PASSWORD';
  CREATE DATABASE passbolt OWNER passbolt ENCODING 'UTF8';

  CREATE USER gitlab WITH PASSWORD '$GITLAB_DB_PASSWORD';
  CREATE DATABASE gitlabhq_production OWNER gitlab ENCODING 'UTF8';
EOSQL

# GitLab richiede alcune estensioni
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d gitlabhq_production <<-EOSQL
  CREATE EXTENSION IF NOT EXISTS pg_trgm;
  CREATE EXTENSION IF NOT EXISTS btree_gist;
EOSQL
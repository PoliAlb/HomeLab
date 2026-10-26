# HomeLab

## Setup

### 🔑 crazioni delle chiavi 

```bash
cat > .env <<EOF
POSTGRES_ADMIN_PASSWORD=$(openssl rand -hex 24)
PASSBOLT_DB_PASSWORD=$(openssl rand -hex 24)
GITLAB_DB_PASSWORD=$(openssl rand -hex 24)
NEXTCLOUD_DB_PASSWORD=$(openssl rand -hex 24)
NEXTCLOUD_ADMIN_PASSWORD=$(openssl rand -hex 16)
GITLAB_ROOT_EMAIL=tuaemail@example.com
GITLAB_ROOT_PASSWORD=$(openssl rand -hex 16)
EOF
```
Questa operazione può essere fatta una sola volta per ogni homelab.

### Avvio dei servizi
```bash
docker compose -f compose.yml up -d
```

## 🔐 [Passbolt](https://localhost:8443)

La pagina di passbolt ci chiederà il login o di resettare la passphrase di un utente già esistente quindi per creare un nuovo utente va eseguito questo comando.

```bash
docker compose exec passbolt su -m -c "/usr/share/php/passbolt/bin/cake \
  passbolt register_user \
  -u tuaemail@example.com \
  -f Nome \
  -l Cognome \
  -r admin" -s /bin/sh www-data
```
Restituirà un link da copiare e incollare su browser , basterà seguire la procedura di creazione dell'account e sarete apposto.


## ☁️ [NextCloud](http://localhost:8082)

## 🦊 [GitLab](http://localhost:8081)

## 🌐 NextDNS
# HomeLab

Questo homelab non gestisce anche le misure di sicurezza che per come è gestito il progetto vengono gestite su un'altra macchina che funge da reverse proxy

## 🚨 REQUISITI MINIMI DI HARDWARE 🚨

- **RAM**: 4,3 GB 

## Setup

### 🔑 crazioni delle chiavi 

```bash
chmod +x env.sh
./env.sh
```
Questa operazione può essere fatta una sola volta per ogni homelab.

### Avvio dei servizi
```bash
docker compose -f compose.yml up -d
```

## 📊🎛️ [Dozzle (control pannel)](https://dozzle.dev/)

## 🔐 [Passbolt](https://www.passbolt.com/)

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


## ☁️ [NextCloud](https://nextcloud.com/)

Al primo avvio viene creato l'utente `admin` (l'installazione richiede 1-2 minuti).
La password è `NEXTCLOUD_ADMIN_PASSWORD` nel file `.env`.

## 🦊 [GitLab](https://about.gitlab.com/)

Al primo avvio (alcuni minuti) viene creato l'utente `root`, con email e password
`GITLAB_ROOT_EMAIL` / `GITLAB_ROOT_PASSWORD` del file `.env`.

## 🌐 [Pi-hole (DNS)](https://pi-hole.net/)

Resolver DNS locale con interfaccia web. La password è `PIHOLE_PASSWORD` nel file `.env`.
I record locali si aggiungono da Settings → Local DNS → DNS Records.
Test: `dig @127.0.0.1 example.com` (se la porta 53 è occupata, vedi la mappatura 5353).
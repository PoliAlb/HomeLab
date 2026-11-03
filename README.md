# HomeLab

Questo homelab non gestisce anche le misure di sicurezza che per come è gestito il progetto vengono gestite su un'altra macchina che funge da reverse proxy

## 🚨 REQUISITI MINIMI DI HARDWARE 🚨

- **RAM**: 4,3 GB 

## Setup

### Porte

```bash
# controllo valore attuale
sudo sysctl net.ipv4.ip_unprivileged_port_start
```

```bash
sudo sysctl -w net.ipv4.ip_unprivileged_port_start=22
```

```bash
# permanente
echo 'net.ipv4.ip_unprivileged_port_start=443' | sudo tee /etc/sysctl.d/99-rootless-ports.conf
sudo sysctl --system
```

```bash
echo '127.0.0.1  passbolt.lab.internal gitlab.lab.internal cloud.lab.internal pihole.lab.internal logs.lab.internal git-ssh.lab.internal' | sudo tee -a /etc/hosts
```

```bash
sudo sed -i '/lab\.internal/d' /etc/hosts
```

```bash
docker compose -f script/lab/homelab.yml -f script/lab/homelab.local.yml cp caddy:/data/caddy/pki/authorities/local/root.crt script/lab/caddy-lab-root.crt
```

### Servizi

```bash
chmod +x script/env.sh
./script/env.sh
```

```bash
docker compose --env-file script/.env -f script/netbird/netbird.yml up -d
#docker compose -f homelab.yml -f homelab.local.yml up -d 
```

```bash
echo "NB_PEER_IP=$(docker compose --env-file script/.env -f script/homelab.yml exec -T netbird sh -c "ip -4 -o addr show wt0 | awk '{print \$4}' | cut -d/ -f1")" >> script/.env
```


```bash
docker compose --env-file script/.env -f script/homelab.yml up -d
```

```bash
curl -fsSL https://pkgs.netbird.io/install.sh | sh
netbird up --management-url https://netbird.home.arpa:8443 --setup-key
```

## 📊🎛️ [Dozzle (pannello di controllo)](https://dozzle.dev/)

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
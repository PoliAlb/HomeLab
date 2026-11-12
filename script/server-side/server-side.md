# Configurazione lato server

Questa guida riguarda la macchina che ospita il laboratorio: requisiti, avvio dei servizi, server NetBird e configurazione di ogni servizio. Per collegare un client vedi [client-side.md](../client-side/client-side.md).

Contenuto della cartella:

| File | Ruolo |
|---|---|
| `homelab.yml` | servizi del laboratorio e reverse proxy Caddy (non dipende dalla VPN) |
| `peer.yml` | peer NetBird: instrada i client VPN verso la rete del laboratorio |
| `netbird/netbird.yml` | server NetBird self-hosted (progetto separato) |
| `proxy/Dockerfile` | immagine di Caddy con il modulo `caddy-l4` |

**Tutti i comandi di questo documento si eseguono da `script/server-side/`.**

## Requisiti

### Hardware

| Risorsa | Minimo | Consigliato |
|---|---|---|
| RAM | 8 GB | 16 GB |
| CPU | 4 vCPU | 6–8 vCPU |
| Disco | 40 GB liberi | 100 GB (SSD) |

> Con 8 GB di RAM il laboratorio funziona, ma i servizi più pesanti (GitLab, Nextcloud, Stirling-PDF) possono essere riavviati per mancanza di memoria se sono sotto carico contemporaneamente.

### Software

- Docker Engine in modalità rootless
- Docker Compose 2.23.1 o successivo
- cgroup v2 con i controller `cpu`, `memory`, `io` e `pids` delegati
- Dispositivo `/dev/net/tun` (per il peer NetBird)

### Rete

- Porte `443/tcp` e `3478/udp` libere e aperte sull'host per il server NetBird
- Il nome `netbird.home.arpa` risolvibile dai client

## Starting point

### 1. Scarica il repository

```bash
git clone https://github.com/PoliAlb/HomeLab.git
cd HomeLab/script/server-side/
```

### 2. Verifica i prerequisiti

```bash
docker info --format '{{.SecurityOptions}}'   # deve contenere name=rootless
docker compose version                        # 2.23.1 o successiva
stat -fc %T /sys/fs/cgroup                    # deve stampare cgroup2fs
ls /dev/net/tun                               # necessario per NetBird
echo "$XDG_RUNTIME_DIR/docker.sock"           # socket del demone rootless
```

### 3. Genera il file `.env`

```bash
chmod +x ../env.sh
../env.sh
```

Lo script richiede `openssl` e non sovrascrive un `.env` esistente. Crea password e chiavi casuali (permessi `600`) in `script/server-side/.env`: **non** versionare il file.

Modifica subito una sola riga:

| Variabile | Cosa fare |
|---|---|
| `GITLAB_ROOT_EMAIL` | sostituisci `tu@example.com` con la tua email |

Controlla anche che `DOCKER_SOCK` punti al socket stampato dall'ultimo comando del passo 2: serve all'agent di Beszel.

Le password generate (`GITLAB_ROOT_PASSWORD`, `NEXTCLOUD_ADMIN_PASSWORD`, `PIHOLE_PASSWORD`, ...) si leggono nel `.env`:

```bash
grep -E 'PASSWORD' .env
```

Queste variabili restano vuote e si compilano più avanti:

| Variabile | Quando |
|---|---|
| `NB_SETUP_KEY` | dopo aver avviato il server NetBird (solo con VPN) |
| `BESZEL_KEY`, `BESZEL_TOKEN` | dopo il primo avvio di Beszel |

### 4. Consenti a Docker rootless di usare la 443

Docker rootless non può pubblicare porte sotto la 1024, e la 443 serve sia al server NetBird sia, senza VPN, al laboratorio. Controlla che sia libera e abbassa il limite:

```bash
ss -ltn '( sport = :443 )'                        # deve stampare solo l'intestazione
sysctl net.ipv4.ip_unprivileged_port_start
sudo sysctl -w net.ipv4.ip_unprivileged_port_start=443
```

Il valore vale per **tutti** gli utenti dell'host e dopo il riavvio torna a `1024`: rendilo permanente, altrimenti dopo un riavvio i container non riescono più a pubblicare la 443.

```bash
echo 'net.ipv4.ip_unprivileged_port_start=443' | sudo tee /etc/sysctl.d/99-rootless-ports.conf
sudo sysctl --system
```

### Avvio

Il laboratorio non pubblica nessuna porta: i client entrano da un tunnel NetBird. L'ordine dei passi conta, perché ogni progetto crea una rete o un volume usati dal successivo.

#### 1. Prepara la rete

- I client devono risolvere `netbird.home.arpa` verso l'IP LAN dell'host (record sul router o in `/etc/hosts`).
- Se i client si collegano da fuori dalla LAN, sul router inoltra `443/tcp` e `3478/udp` verso l'host. Se la 443 del router è già inoltrata alla macchina che fa da reverse proxy, non puoi usarla qui. Con client solo in LAN l'inoltro non serve.
- Sull'host aprile nel firewall:

```bash
sudo ufw allow 443/tcp
sudo ufw allow 3478/udp

# per eliminarli
sudo ufw delete allow 443/tcp
sudo ufw delete allow 3478/udp
```

#### 2. Avvia il server NetBird

```bash
docker compose -f script/server-side/netbird.yml up -d
```

Crea la rete `nbnet` e il volume `nb_caddy_data`.

#### 3. Crea l'amministratore e la setup key

Apri `https://netbird.home.arpa` (dopo aver installato la CA di NetBird, vedi [Distribuire le CA](#distribuire-le-ca-ai-client)), crea l'utente admin e una **setup key** (assegnale il gruppo `lab-gw`). Scrivila nel `.env`:

```
NB_SETUP_KEY=la-tua-chiave
```

#### 4. Avvia i servizi

Crea la rete `homelab_net`.

```bash
docker compose -f script/server-side/homelab.yml up -d --build
docker compose -f script/server-side/homelab.yml exec dns dig +short @127.0.0.1 gitlab.lab.internal   # atteso: 172.30.10.3
```

#### 5. Avvia il peer

```bash
docker compose -f script/server-side/peer.yml up -d
docker compose -f script/server-side/peer.yml exec netbird netbird status   # Management: Connected
```

#### 6. Configura la dashboard NetBird

I nomi delle voci possono variare con la versione.

1. **Groups:** `lab-gw` (il peer `homelab-gw`) e `lab-users` (i client degli utenti).
2. **Networks:** crea una rete `homelab` con routing peer `homelab-gw` e masquerade attivo. Aggiungi come risorse `172.30.10.3/32` (Caddy) e `172.30.10.53/32` (Pi-hole).
3. **Access control:** una policy da `lab-users` verso le risorse della rete.
4. **DNS → Nameservers:** `172.30.10.53` con dominio `lab.internal`, assegnato a `lab-users`.

A questo punto i client possono collegarsi: vedi [client-side.md](../client-side/client-side.md).

### Distribuire le CA ai client

I certificati sono firmati da due CA interne di Caddy, una per il server NetBird e una per il laboratorio. Ogni client deve installarle entrambe (vedi [client-side.md](../client-side/client-side.md#installare-le-ca)), quindi vanno consegnate agli utenti.

CA del server NetBird (serve prima di collegare un client):

```bash
docker compose -f script/server-side/netbird.yml cp caddy:/data/caddy/pki/authorities/local/root.crt script/server-side/cert/netbird-ca.crt
```

CA del laboratorio:

```bash
docker compose -f scritp/server-side/homelab.yml cp caddy:/data/caddy/pki/authorities/local/root.crt script/server-side/cert/caddy-lab-root.crt
```

Sono certificati pubblici: si possono consegnare senza particolari cautele, ma verifica che l'utente riceva quelli giusti da una fonte fidata.
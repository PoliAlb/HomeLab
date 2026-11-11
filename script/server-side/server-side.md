# Configurazione lato server

Questa guida riguarda la macchina che ospita il laboratorio: requisiti, avvio dei servizi, server NetBird e configurazione di ogni servizio. Per collegare un client vedi [client-side.md](../client-side/client-side.md).

Contenuto della cartella:

| File | Ruolo |
|---|---|
| `homelab.yml` | servizi del laboratorio e reverse proxy Caddy (non dipende dalla VPN) |
| `homelab.local.yml` | overlay per l'uso senza VPN (porte su `127.0.0.1`) |
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

### Rete (solo con VPN)

- Porte `443/tcp` e `3478/udp` libere e aperte sull'host per il server NetBird
- Il nome `netbird.home.arpa` risolvibile dai client

## Preparazione

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

## Avvio con VPN

Il laboratorio non pubblica nessuna porta: i client entrano da un tunnel NetBird. L'ordine dei passi conta, perché ogni progetto crea una rete o un volume usati dal successivo.

### 1. Prepara la rete

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

### 2. Avvia il server NetBird

```bash
docker compose -f script/server-side/netbird.yml up -d
```

Crea la rete `nbnet` e il volume `nb_caddy_data`.

### 3. Crea l'amministratore e la setup key

Apri `https://netbird.home.arpa` (dopo aver installato la CA di NetBird, vedi [Distribuire le CA](#distribuire-le-ca-ai-client)), crea l'utente admin e una **setup key** (assegnale il gruppo `lab-gw`). Scrivila nel `.env`:

```
NB_SETUP_KEY=la-tua-chiave
```

### 4. Avvia il laboratorio

Crea la rete `homelab_net`.

```bash
docker compose -f script/server-side/homelab.yml up -d --build
docker compose -f script/server-side/homelab.yml exec dns dig +short @127.0.0.1 gitlab.lab.internal   # atteso: 172.30.10.3
```

### 5. Avvia il peer

```bash
docker compose -f script/server-side/peer.yml up -d
docker compose -f script/server-side/peer.yml exec netbird netbird status   # Management: Connected
```

### 6. Configura la dashboard NetBird

I nomi delle voci possono variare con la versione.

1. **Groups:** `lab-gw` (il peer `homelab-gw`) e `lab-users` (i client degli utenti).
2. **Networks:** crea una rete `homelab` con routing peer `homelab-gw` e masquerade attivo. Aggiungi come risorse `172.30.10.3/32` (Caddy) e `172.30.10.53/32` (Pi-hole).
3. **Access control:** una policy da `lab-users` verso le risorse della rete.
4. **DNS → Nameservers:** `172.30.10.53` con dominio `lab.internal`, assegnato a `lab-users`.

A questo punto i client possono collegarsi: vedi [client-side.md](../client-side/client-side.md).

## Distribuire le CA ai client

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

## Configurazione dei servizi

### Beszel

L'hub parte con il laboratorio; l'agent si avvia dopo aver ottenuto chiave e token.

1. Apri `https://monitor.lab.internal` e crea l'utente amministratore.
2. Aggiungi un nuovo sistema. Beszel mostra la chiave pubblica e un token. Come host usa il socket Unix `/beszel_socket/beszel.sock`, condiviso con l'agent.
3. Scrivi `BESZEL_KEY` e `BESZEL_TOKEN` nel `.env`.
4. Avvia l'agent:

```bash
docker compose -f homelab.yml up -d beszel-agent
```

### Passbolt

La pagina di Passbolt chiede il login o il reset della passphrase di un utente già esistente. Per creare il primo utente (o uno nuovo) esegui:

```bash
docker compose -f homelab.yml exec passbolt su -m -c "/usr/share/php/passbolt/bin/cake \
  passbolt register_user \
  -u <tuaemail@example.com> \
  -f <Nome> \
  -l <Cognome> \
  -r admin" -s /bin/sh www-data
```

Il comando restituisce un link: aprilo nel browser e segui la procedura di creazione dell'account.

### Nextcloud

Al primo avvio viene creato l'utente `admin` (l'installazione richiede 1-2 minuti). La password è `NEXTCLOUD_ADMIN_PASSWORD` nel `.env`:

```bash
grep NEXTCLOUD_ADMIN_PASSWORD .env
```

Il compose imposta già dominio, protocollo HTTPS e proxy fidato (Caddy, `172.30.10.3`), e il limite di upload è 2 GB.

### GitLab

Al primo avvio (alcuni minuti) viene creato l'utente **root**, con l'email `GITLAB_ROOT_EMAIL` e la password `GITLAB_ROOT_PASSWORD` del `.env`:

```bash
grep -E 'GITLAB_ROOT_(EMAIL|PASSWORD)' .env
```

L'SSH passa da Caddy (`caddy-l4`, porta 22 del peer VPN verso `gitlab:22`) ed è annunciato come `git-ssh.lab.internal`.

### Pi-hole

La password dell'interfaccia (`https://pihole.lab.internal/admin`) è `PIHOLE_PASSWORD` nel `.env`:

```bash
grep PIHOLE_PASSWORD .env
```

Il dominio interno è un wildcard verso Caddy, impostato dal compose. I record locali aggiuntivi si creano da Settings → Local DNS → DNS Records.

Test dal container:

```bash
docker compose -f homelab.yml exec dns dig +short @127.0.0.1 example.com
```

## Backup

Oltre ai volumi dei database, includi nei backup:

- `caddy_data`: contiene la CA interna del laboratorio. Se la perdi, devi reinstallare la nuova CA su tutti i client.
- i dati del server NetBird (`netbird_data`: database e chiavi) e il volume `nb_caddy_data`, che contiene la CA del server NetBird.
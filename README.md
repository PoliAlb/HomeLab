# HomeLab

Laboratorio self-hosted con password manager, cloud, GitLab, DNS, strumenti PDF e monitoraggio. Tutti i servizi stanno dietro un unico reverse proxy (Caddy) e si raggiungono da un tunnel VPN NetBird.

> Le misure di sicurezza perimetrali non sono gestite da questo laboratorio: nel progetto sono affidate a un'altra macchina che funge da reverse proxy.

## Documentazione

| Documento | Per chi | Contenuto |
|---|---|---|
| [server-side.md](./script/server-side/server-side.md) | chi installa il laboratorio sull'host | requisiti, file `.env`, avvio con e senza VPN, server NetBird, configurazione dei servizi |
| [client-side.md](./script/client-side/client-side.md) | chi deve accedere al laboratorio | installazione delle CA, client NetBird, verifica dell'accesso, SSH di GitLab |

## Come funziona

Nessuna porta del laboratorio è pubblicata sull'host. L'ingresso è Caddy (con `caddy-l4` per l'SSH di GitLab), che termina l'HTTPS con una CA interna. I client entrano da un peer NetBird che instrada verso Caddy e Pi-hole; Pi-hole risolve il dominio interno verso Caddy.

Gli indirizzi qui sotto usano il dominio predefinito `lab.internal`, modificabile con la variabile `LAB_DOMAIN`.

## Servizi

| Servizio | Indirizzo | Container |
|---|---|---|
| Beszel (monitoraggio) | `monitor.lab.internal` | Zeus, Aquila (agent) |
| Passbolt (password manager) | `passbolt.lab.internal` | Ade |
| Nextcloud (cloud) | `cloud.lab.internal` | Demetra |
| GitLab (forge Git) | `gitlab.lab.internal`, SSH su `git-ssh.lab.internal` | Efesto |
| Pi-hole (DNS) | `pihole.lab.internal` | Apollo |
| Stirling-PDF (strumenti PDF) | `pdf.lab.internal` | Dedalo |
| Caddy (reverse proxy) | — | Ermes |

## CONFIGURAZIONE SERVIZI

### 📊🎛️ [Beszel (pannello di controllo)](https://www.beszel.dev/)

Monitoraggio leggero dell'host e dei container: CPU, memoria, disco, rete e stato di ogni servizio, in un'unica dashboard. È composto da un hub web e da un agent che legge le metriche dal demone Docker.

L'hub parte con il laboratorio; l'agent si avvia dopo aver ottenuto chiave e token.

1. Apri `https://monitor.lab.internal` e crea l'utente amministratore.
2. Aggiungi un nuovo sistema. Beszel mostra la chiave pubblica e un token. Come host usa il socket Unix `/beszel_socket/beszel.sock`, condiviso con l'agent.
3. Scrivi `BESZEL_KEY` e `BESZEL_TOKEN` nel `.env`.
4. Avvia l'agent:

![](./imgs/beszel-1.png)

![](./imgs/beszel-2.png)

![](./imgs/beszel-3.png)

![](./imgs/beszel-4.png)

Configurazione: [server-side.md → Beszel](./script/server-side/server-side.md#beszel)

### 🔐 [Passbolt](https://www.passbolt.com/)

Password manager open source pensato per i team, basato su OpenPGP: le credenziali si condividono tra utenti e gruppi restando cifrate end-to-end.

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

![](./imgs/passbolt-1.png)

![](./imgs/passbolt-2.png)

![](./imgs/passbolt-3.png)

![](./imgs/passbolt-4.png)

Configurazione e creazione degli utenti: [server-side.md → Passbolt](./script/server-side/server-side.md#passbolt)

### ☁️ [Nextcloud](https://nextcloud.com/)

Cloud personale per file, calendari e contatti, con sincronizzazione da desktop e mobile (WebDAV, CalDAV e CardDAV).

Al primo avvio viene creato l'utente `admin` (l'installazione richiede 1-2 minuti). La password è `NEXTCLOUD_ADMIN_PASSWORD` nel `.env`:

```bash
grep NEXTCLOUD_ADMIN_PASSWORD .env
```

Il compose imposta già dominio, protocollo HTTPS e proxy fidato (Caddy, `172.30.10.3`), e il limite di upload è 2 GB.

![](./imgs/nc-1.png)

![](./imgs/nc-2.png)

Configurazione e primo accesso: [server-side.md → Nextcloud](./script/server-side/server-side.md#nextcloud)

### 🦊 [GitLab](https://about.gitlab.com/)

Gestione di repository Git, issue e pipeline CI/CD. L'accesso via SSH passa da Caddy sulla porta 22, con un nome dedicato (`git-ssh.lab.internal`).

Al primo avvio (alcuni minuti) viene creato l'utente **root**, con l'email `GITLAB_ROOT_EMAIL` e la password `GITLAB_ROOT_PASSWORD` del `.env`:

```bash
grep -E 'GITLAB_ROOT_(EMAIL|PASSWORD)' .env
```

L'SSH passa da Caddy (`caddy-l4`, porta 22 del peer VPN verso `gitlab:22`) ed è annunciato come `git-ssh.lab.internal`.

![](./imgs/gitlab-1.png)

![](./imgs/gitlab-2.png)

![](./imgs/gitlab-3.png)

![](./imgs/gitlab-4.png)

Configurazione e primo accesso: [server-side.md → GitLab](./script/server-side/server-side.md#gitlab) · Uso dell'SSH: [client-side.md](./script/client-side/client-side.md#usare-gitlab-via-ssh)

### 🌐 [Pi-hole (DNS)](https://pi-hole.net/)

Resolver DNS locale con interfaccia web. Risolve tutto il dominio interno verso Caddy e inoltra il resto ai resolver pubblici, con il blocco di pubblicità e tracker.

La password dell'interfaccia (`https://pihole.lab.internal/admin`) è `PIHOLE_PASSWORD` nel `.env`:

```bash
grep PIHOLE_PASSWORD .env
```

Il dominio interno è un wildcard verso Caddy, impostato dal compose. I record locali aggiuntivi si creano da Settings → Local DNS → DNS Records.

Test dal container:

```bash
docker compose -f homelab.yml exec dns dig +short @127.0.0.1 example.com
```

![](./imgs/dns-1.png)

![](./imgs/dns-2.png)

Configurazione e record locali: [server-side.md → Pi-hole](./script/server-side/server-side.md#pi-hole)

### 📄 [Stirling-PDF](https://www.stirlingpdf.com/)

Strumenti per i PDF in locale: unire, dividere, convertire, comprimere, firmare, OCR. I file non lasciano il laboratorio. L'interfaccia è in italiano e le lingue OCR aggiuntive si installano nel volume `stirling_tessdata`.
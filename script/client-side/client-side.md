# Configurazione lato client

Questa guida riguarda chi deve accedere al laboratorio da un computer: installazione delle CA, collegamento alla VPN NetBird e verifica. Per installare il laboratorio vedi [server-side.md](../server-side/server-side.md).

## Cosa ti serve dall'amministratore

- l'URL di gestione di NetBird: `https://netbird.home.arpa:8443`
- il file `netbird-ca.crt` (CA del server NetBird)
- il file `caddy-lab-root.crt` (CA del laboratorio)
- solo per un client senza interfaccia grafica: una setup key

L'amministratore li ottiene con i comandi in [server-side.md → Distribuire le CA](../server-side/server-side.md#distribuire-le-ca-ai-client).

## Installare le CA

Le CA vanno installate **prima** di collegarsi, altrimenti il client NetBird e il browser rifiutano i certificati. Il file `netbird-ca.crt` serve per il server NetBird, `caddy-lab-root.crt` per i servizi del laboratorio. Per annullare tutto vedi [Rimuovere le CA](#rimuovere-le-ca).

Le due CA sono generate entrambe da Caddy e potrebbero avere lo stesso nome: per distinguerle usa l'impronta digitale.

```bash
openssl x509 -in script/server-side/cert/netbird-ca.crt -noout -subject -fingerprint -sha256
openssl x509 -in script/server-side/cert/caddy-lab-root.crt -noout -subject -fingerprint -sha256
```

### Firefox

Firefox usa un archivio proprio: importa i file da Impostazioni → Privacy e sicurezza → Certificati → Mostra certificati → Autorità.

## Rimuovere le CA

Dopo la rimozione, `curl -I https://gitlab.lab.internal` deve segnalare un errore di certificato. Riavvia i browser già aperti. I comandi per macOS e Windows leggono i file `.crt`: se li hai cancellati, rimuovi le CA dall'app Accesso Portachiavi (macOS) o da `certmgr.msc` (Windows), riconoscendole dall'impronta digitale.

### Firefox

Impostazioni → Privacy e sicurezza → Certificati → Mostra certificati → Autorità: seleziona la CA di Caddy (controlla l'impronta con Visualizza) e scegli **Elimina o non considerare attendibile**. Ripeti per la seconda.

## Rendere risolvibile `netbird.home.arpa`

Il nome del server NetBird deve puntare all'IP LAN dell'host. Se non c'è un record sul router, aggiungilo a `/etc/hosts`:

```
192.168.x.x  netbird.home.arpa
```

Sostituisci l'indirizzo con quello dell'host.

Per annullare: `sudo sed -i '/netbird\.home\.arpa/d' /etc/hosts`.

## Collegare il client NetBird

Installa NetBird seguendo le istruzioni ufficiali (se usi lo script `curl | sh`, leggilo prima di eseguirlo), poi:

```bash
netbird up --management-url https://netbird.home.arpa:8443
```

Si apre il browser per l'accesso. Per un client senza interfaccia grafica aggiungi `--setup-key LA_TUA_CHIAVE`.

## Verifica

```bash
nslookup gitlab.lab.internal           # atteso: 172.30.10.3
curl -I https://gitlab.lab.internal
```

Se `nslookup` non restituisce `172.30.10.3`, il client non sta usando Pi-hole: controlla che sia nel gruppo `lab-users` e che il nameserver `172.30.10.53` sia assegnato a quel gruppo. Se `curl` segnala un errore di certificato, la CA del laboratorio non è installata. Se il browser non apre i servizi ma `nslookup` risponde, controlla `netbird status`.

## Usare GitLab via SSH

L'SSH passa da un nome dedicato. Aggiungi la tua chiave pubblica da GitLab (Profilo → SSH Keys), poi:

```bash
ssh -T git@git-ssh.lab.internal
git clone git@git-ssh.lab.internal:<gruppo>/<progetto>.git
```

## ! TEST !

```bash
docker build -f script/client-side/test/Dockerfile -t netbird-client-test .
```

```bash
docker run -it --rm --name nb-client \
  --cap-add NET_ADMIN --cap-add SYS_ADMIN --cap-add SYS_RESOURCE \
  --device /dev/net/tun \
  -e NB_SERVER_IP=192.168.x.x \
  -e NB_SETUP_KEY=la_tua_chiave \
  netbird-client-test
```
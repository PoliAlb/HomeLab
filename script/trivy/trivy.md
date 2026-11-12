```bash
alias trivy='docker run --rm -v trivy-cache:/home/trivy/.cache/trivy argo-panoptes'
```

```bash
unalias trivy
```

## Build

```bash
# Ultima versione
docker build -t argo-panoptes .

# Versione specifica (consigliato)
docker build --build-arg TRIVY_VERSION=<versione> -t argo-panoptes .
```

## Cache del database

Trivy scarica il DB delle vulnerabilità a ogni run. Un volume nominato evita di riscaricarlo ogni volta:

```bash
docker volume create trivy-cache
```

## Scansione di immagini container

```bash
trivy image nginx:latest
trivy image --severity HIGH,CRITICAL nginx:latest
trivy image --ignore-unfixed nginx:latest          # solo CVE con fix disponibile
trivy image --exit-code 1 --severity CRITICAL nginx:latest   # fallisce la CI se trova CRITICAL
```

Per scansionare un’immagine locale (non su un registry), monta il socket Docker:

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/home/trivy/.cache/trivy argo-panoptes image mia-immagine:tag
```

## Scansione di filesystem e repository

```bash
# Cartella locale (dipendenze, secret, misconfigurazioni)
docker run --rm -v "$PWD":/work -v trivy-cache:/home/trivy/.cache/trivy \
  argo-panoptes fs /work

# Repository Git remoto
trivy repo https://github.com/utente/repo

# Solo secret
docker run --rm -v "$PWD":/work -v trivy-cache:/home/trivy/.cache/trivy \
  argo-panoptes fs --scanners secret /work
```

## Misconfigurazioni

Per Dockerfile, Terraform, Kubernetes, Compose e simili. Nota che il tuo compose.yml è un buon candidato:

```bash
docker run --rm -v "$PWD":/work -v trivy-cache:/home/trivy/.cache/trivy argo-panoptes config /work
```

## Kubernetes

```bash
trivy k8s --report summary cluster
```

(richiede il kubeconfig montato nel container, cioè -v ~/.kube:/home/trivy/.kube:ro)

## SBOM e license

```bash
# Generare una SBOM
trivy image --format cyclonedx --output sbom.json nginx:latest

# Scansionare una SBOM esistente
trivy sbom sbom.json

# Controllo licenze
trivy image --scanners license nginx:latest
```

## Formati di output

```bash
docker run --rm -v "$PWD":/out -v trivy-cache:/home/trivy/.cache/trivy argo-panoptes image --format json --output /out/report.json nginx:latest
```

Formati disponibili: table (default), json, sarif, cyclonedx, spdx-json, template (es. HTML con --template "@contrib/html.tpl").

Se scrivi su un bind mount, la cartella deve essere scrivibile dall’utente trivy dentro il container (uid non-root). Se dà errore di permessi, aggiungi --user $(id -u):$(id -g) al docker run.

## Gestione del database

```bash
trivy image --download-db-only         # scarica solo il DB
trivy image --skip-db-update nginx     # usa il DB già in cache (utile offline)
trivy clean --all                      # pulisce la cache
```

## Ignorare falsi positivi

Crea un file .trivyignore nella cartella scansionata, con un CVE per riga:

```bash
CVE-2024-12345
```

Trivy lo legge in automatico, oppure lo indichi con --ignorefile.

## Altri comandi utili

```bash
trivy version
trivy image --help
trivy image --list-all-pkgs nginx:latest   # elenca anche i pacchetti senza vulnerabilità
```
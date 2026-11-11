# Client di test: simula un utente Debian che segue script/client-side/client-side.md
# Build dalla radice del repo:
#   docker build -f Dockerfile.client -t netbird-client-test .
FROM debian:12-slim

ARG DEBIAN_FRONTEND=noninteractive

# Strumenti di base + quelli usati nella sezione "Verifica" e "Usare GitLab via SSH"
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg \
        dnsutils iproute2 iputils-ping procps \
        openssh-client git \
    && rm -rf /var/lib/apt/lists/*

# --- Installare le CA (prima di collegarsi) -------------------------------
# netbird-ca.crt = CA del server NetBird, caddy-lab-root.crt = CA dei servizi del lab
COPY script/server-side/cert/netbird-ca.crt     /usr/local/share/ca-certificates/netbird-ca.crt
COPY script/server-side/cert/caddy-lab-root.crt /usr/local/share/ca-certificates/caddy-lab-root.crt
RUN update-ca-certificates

# --- Installare NetBird (repository apt ufficiale) ------------------------
RUN curl -fsSL https://pkgs.netbird.io/debian/public.key \
        | gpg --dearmor -o /usr/share/keyrings/netbird-archive-keyring.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/netbird-archive-keyring.gpg] https://pkgs.netbird.io/debian stable main' \
        > /etc/apt/sources.list.d/netbird.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends netbird \
    && rm -rf /var/lib/apt/lists/*

# --- Rendere risolvibile netbird.home.arpa --------------------------------
# /etc/hosts è gestito da Docker a runtime: non si può scrivere nella build.
# Usa:  docker run --add-host netbird.home.arpa:<IP LAN dell'host> ...

# --- Collegare il client --------------------------------------------------
# Il demone e "netbird up" partono a runtime (servono NET_ADMIN e /dev/net/tun).
ENV NB_MANAGEMENT_URL=https://netbird.home.arpa:8443
COPY script/client-side/test/entrypoint.sh /usr/local/bin/client-entrypoint.sh
RUN chmod +x /usr/local/bin/client-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/client-entrypoint.sh"]
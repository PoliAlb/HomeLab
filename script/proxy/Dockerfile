# Caddy ufficiale + plugin caddy-l4 (proxy TCP/UDP per SSH di GitLab e DNS di Pi-hole)
# Tag "2" = ultima 2.x: l'ultima versione di caddy-l4 richiede Caddy >= 2.11
FROM caddy:2-builder AS builder
# Dopo la prima prova funzionante, fissa un commit: --with github.com/mholt/caddy-l4@<commit>
RUN xcaddy build \
    --with github.com/mholt/caddy-l4

FROM caddy:2-alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
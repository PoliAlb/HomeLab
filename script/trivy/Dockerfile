# Versione di Trivy: usa un tag specifico (es. 0.xx.x) per build riproducibili
ARG TRIVY_VERSION=0.76.2

FROM aquasec/trivy:${TRIVY_VERSION} AS trivy

FROM alpine:3.20

# git serve per scansionare repository remoti, jq per elaborare i report JSON
RUN apk add --no-cache git ca-certificates curl jq \
 && addgroup -S trivy \
 && adduser -S trivy -G trivy

COPY --from=trivy /usr/local/bin/trivy /usr/local/bin/trivy

ENV TRIVY_CACHE_DIR=/home/trivy/.cache/trivy \
    TRIVY_NO_PROGRESS=true

RUN mkdir -p "$TRIVY_CACHE_DIR" /work \
 && chown -R trivy:trivy /home/trivy /work

USER trivy
WORKDIR /work

ENTRYPOINT ["trivy"]
CMD ["--help"]
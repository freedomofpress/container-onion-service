# sha256 as of 2026-10-12
FROM docker.io/library/debian:trixie-slim@sha256:918311b7b6c4c6f68b232ba516584925f6c78ad82b6fd534b98979df6438e483

# The SHELL directive is only supported in Docker build mode, but
# still worth including for that case
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
        curl \
        gnupg2 \
        apt-transport-https \
        ca-certificates && \
    # Since we are only doing this once, we don't install deb.torproject.org-keyring.
    curl -sS https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc \
        | gpg --dearmor \
        | tee /tor-archive-keyring.gpg > /dev/null

FROM docker.io/library/debian:trixie-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a AS final

COPY --from=prepare /tor-archive-keyring.gpg /usr/share/keyrings/tor-archive-keyring.gpg

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
        apt-transport-https \
        ca-certificates && \
    echo "deb [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org trixie main" \
        >/etc/apt/sources.list.d/tor.list && \
    apt-get update && \
    apt-get install --yes --no-install-recommends \
        tor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/man/* && \
    rm -rf /usr/share/doc/*

# Deb package configures the "debian-tor" user
# hadolint ignore=DL3066
USER debian-tor

COPY tor-entrypoint /usr/local/bin/tor-entrypoint
COPY gen-service-keypair /usr/local/bin/gen-service-keypair

CMD ["/usr/local/bin/tor-entrypoint"]

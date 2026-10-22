ARG VERSION_DEBIAN

FROM docker.io/library/debian:${VERSION_DEBIAN} AS prepare

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

ARG VERSION_DEBIAN

FROM docker.io/library/debian:${VERSION_DEBIAN} AS final

ARG VERSION_TOR

COPY --from=prepare /tor-archive-keyring.gpg /usr/share/keyrings/tor-archive-keyring.gpg

# The SHELL directive is only supported in Docker build mode, but
# still worth including for that case
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
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
    rm -rf /usr/share/doc/* && \
    tor --version 2>&1 | grep "${VERSION_TOR}"

LABEL org.opencontainers.image.version="${VERSION_TOR}"
LABEL org.opencontainers.image.licenses="AGPL-3.0"
LABEL org.opencontainers.image.vendor="Freedom of the Press Foundation"
LABEL org.opencontainers.image.title="Onion Service"

# Deb package configures the "debian-tor" user
# hadolint ignore=DL3066
USER debian-tor

COPY tor-entrypoint /usr/local/bin/tor-entrypoint
COPY gen-service-keypair /usr/local/bin/gen-service-keypair
COPY gen-client-keypair /usr/local/bin/gen-client-keypair

CMD ["/usr/local/bin/tor-entrypoint"]

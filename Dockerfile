# sha256 as of 2025-11-11
FROM debian:bookworm-slim@sha256:936abff852736f951dab72d91a1b6337cf04217b2a77a5eaadc7c0f2f1ec1758

RUN apt-get update && apt-get install -y curl gnupg2 apt-transport-https && \
    # Since we are only doing this once, we don't install deb.torproject.org-keyring.
    curl -sS https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc \
    | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org bookworm main" >/etc/apt/sources.list.d/tor.list && \
    apt-get update && \
    apt-get install -y tor && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Deb package configures the "debian-tor" user
USER debian-tor

COPY tor-entrypoint /usr/local/bin/tor-entrypoint
COPY gen-service-keypair /usr/local/bin/gen-service-keypair

CMD ["/usr/local/bin/tor-entrypoint"]

# sha256 as of 2022-01-28
FROM debian:bullseye-slim@sha256:125f346eac7055d8e1de1b036b1bd39781be5bad3d36417c109729d71af0cd73

RUN apt-get update && apt-get install -y curl gnupg2 apt-transport-https

# Since we are only doing this once, we don't install deb.torproject.org-keyring.
RUN curl -sS https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc \
    | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org bullseye main" >/etc/apt/sources.list.d/tor.list && \
    apt-get update && \
    apt-get install -y tor=0.4.7.8-1~d11.bullseye+1

# Deb package configures the "debian-tor" user
USER debian-tor

COPY tor-entrypoint /usr/local/bin/tor-entrypoint
COPY gen-service-keypair /usr/local/bin/gen-service-keypair

CMD ["/usr/local/bin/tor-entrypoint"]

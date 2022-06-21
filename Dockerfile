# sha256 as of 2022-06-21
FROM debian:bullseye-slim@sha256:89e9d812b34f393bddc3ff289f0036a3d9efc7e2f7289ec902c6427b69f39649

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

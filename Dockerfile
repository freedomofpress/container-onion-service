# sha256 as of 2021-12-14
FROM debian:bullseye-slim@sha256:6ce27fb7f6d0c9c2da4d44481680ea47c0e8f818088372a7a67798fbab5ca322

RUN apt-get update && apt-get install -y curl gnupg2 apt-transport-https

# Note that https://support.torproject.org/apt/tor-deb-repo/ has not yet been
# updated for the deprecation of apt-key(8). Also, since we are only doing
# this once, we don't install deb.torproject.org-keyring.
RUN curl -sS -o /usr/share/keyrings/torproject.asc https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc && \
    echo "deb [signed-by=/usr/share/keyrings/torproject.asc] https://deb.torproject.org/torproject.org bullseye main" >/etc/apt/sources.list.d/tor.list && \
    apt-get update && \
    apt-get install -y tor=0.4.6.8-1~d11.bullseye+1

# Deb package configures the "debian-tor" user
USER debian-tor

COPY tor-entrypoint /usr/local/bin/tor-entrypoint
COPY gen-service-keypair /usr/local/bin/gen-service-keypair

CMD ["/usr/local/bin/tor-entrypoint"]

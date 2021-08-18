# sha256 as of 2021-08-18
FROM debian:bullseye-slim@sha256:2a6fd917bbc6b8c0c4f5d05b2f831b27003dc24df486e3ec8b3f563fe9c06503

RUN apt-get update && apt-get install -y curl gnupg2 apt-transport-https

# See https://support.torproject.org/apt/tor-deb-repo/
# TODO: we should explicitly pin a version here
# For now, record the actual resulting version in version.txt
RUN printf '%s https://deb.torproject.org/torproject.org bullseye main\n' deb deb-src > /etc/apt/sources.list.d/tor.list && \
    curl -s https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y tor deb.torproject.org-keyring

# Deb package configures the "debian-tor" user
USER debian-tor

COPY tor-entrypoint /usr/local/bin/tor-entrypoint
COPY tor-generate-onion /usr/local/bin/tor-generate-onion

CMD ["/usr/local/bin/tor-entrypoint"]

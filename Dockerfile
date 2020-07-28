# sha256 of buster-slim as of 2020-07-28
FROM debian@sha256:79326248a982be0b36e8280f906916fceffdd5c17a298b14446e5e72cc822fe7

# Installing python3 for easier scripting when generating configs
RUN apt-get update && apt-get install -y curl gnupg2 apt-transport-https python3 python3-yaml

# Reference https://support.torproject.org/apt/tor-deb-repo/
RUN printf '%s https://deb.torproject.org/torproject.org buster main\n' deb deb-src > /etc/apt/sources.list.d/tor.list && \
    curl -s https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y tor deb.torproject.org-keyring

# Deb package configures the "debian-tor" user
USER debian-tor

COPY tor-entrypoint /usr/local/bin/tor-entrypoint
COPY tor-generate-onion /usr/local/bin/tor-generate-onion
COPY tor-generate-onion-config /usr/local/bin/tor-generate-onion-config

CMD ["/usr/local/bin/tor-entrypoint"]

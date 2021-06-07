# sha256 as of 2021-06-07 for buster-slim
FROM debian@sha256:33965bf1eaadb19ce2f9396595c4a669e3e04c1ab8cc073b8929f529c58404bb

RUN apt-get update && apt-get install -y curl gnupg2 apt-transport-https

# Reference https://support.torproject.org/apt/tor-deb-repo/
# Todo: we should explicitly pin a version here.
RUN printf '%s https://deb.torproject.org/torproject.org buster main\n' deb deb-src > /etc/apt/sources.list.d/tor.list && \
    curl -s https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y tor deb.torproject.org-keyring

# Deb package configures the "debian-tor" user
USER debian-tor

COPY tor-entrypoint /usr/local/bin/tor-entrypoint
COPY tor-generate-onion /usr/local/bin/tor-generate-onion

CMD ["/usr/local/bin/tor-entrypoint"]

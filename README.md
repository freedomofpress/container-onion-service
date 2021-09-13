# Onion Service

To run, set the following (here are some example values):

    TOR_ONION_NAME=myservice
    TOR_ONION_HOSTNAME=<...>.onion
    TOR_ONION_V3_PUBLIC_KEY=<base64...>
    TOR_ONION_V3_SECRET_KEY=<base64...>
    TOR_ONION_REMOTE_PORT=80
    WEB_FRONTEND_HOST=nginx.internal
    WEB_FRONTEND_PORT=8000

## Client authentication

To enable client authentication (which will prevent all clients without
a key from accessing the service), mount some `*.auth` files into
`/authorized_clients` when running the container.

## Generating a key and hidden service name

To create new service names and their associated keys, run:

    docker build -t onion-service.local .
    docker run --rm --entrypoint tor-generate-onion onion-service.local

TODO: we should be able to generate client keys easily as well.

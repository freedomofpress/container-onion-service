# Onion Service

A container that runs a [Tor Onion Service](https://community.torproject.org/onion-services/)
as a proxy in front of another web application to allow a standard HTTP/S web service to 
be exposed as an onion service on the Tor network.

[![CI/CD](https://github.com/freedomofpress/container-onion-service/actions/workflows/publish.yaml/badge.svg)](https://github.com/freedomofpress/container-onion-service/actions/workflows/publish.yaml)
[![Tor Version](https://img.shields.io/gitlab/v/tag/tpo%2Fcore%2Ftor?gitlab_url=https%3A%2F%2Fgitlab.torproject.org&label=Tor&color=%2359316b
)](https://gitlab.torproject.org/tpo/core/tor)
[![Image Version](https://img.shields.io/github/v/tag/freedomofpress/container-onion-service?label=Image&color=%232aae48
)](https://github.com/freedomofpress/container-onion-service/tags/)
[![License](https://img.shields.io/github/license/freedomofpress/container-onion-service)](LICENSE.md)

> [!IMPORTANT]
> Connecting to any onion service requires using the 
> [The Tor Browser](https://download.torproject.org/tor-browser-for-desktop/). Please
> ensure it is installed before continuing.

- [Onion Service](#onion-service)
  - [Image Tags](#image-tags)
  - [Quick Start](#quick-start)
  - [Configuration](#configuration)
    - [Initial Setup](#initial-setup)
    - [Restricting Access](#restricting-access)
    - [Reference](#reference)
  - [Licenses](#licenses)

## Image Tags

The official registry for this image is located at `ghcr.io/freedomofpress/onion-service`.

The image is only built for the `amd64` architecture.

The `latest` tag will always point to the image built with the latest version of Tor.
See the [Tor repository tags](https://gitlab.torproject.org/tpo/core/tor/-/tags) for
specific version information.

Version tags are be provided for each version of Tor, for example the tag `0.4.9.14`
corresponds to the [`tor-0.4.9.14`](https://gitlab.torproject.org/tpo/core/tor/-/tags/tor-0.4.9.14)
tag in the Tor repository.

The image is periodically rebuilt to incorporate updates from the latest Debian base image.

> [!NOTE]
> Prior to `0.4.9.14` tags were also available for specific Debian versions. These are no
> longer maintained and should be removed from any configurations.

## Quick Start

1. Start the demo Docker Compose stack:

```bash
docker compose -f compose.demo.yaml up --detach
```

2. Fetch the newly generated onion hostname from the container logs:

```bash
docker compose -f compose.demo.yaml logs onion | grep hostname
```

3. Copy the onion hostname into Tor Browser to see the Nginx welcome page

> [!WARNING]
> The demo server will regenerate its private key and onion hostname every time
> it is restarted making it inappropriate for real world usage. See the
> [#configuration](#configuration) section for information on setting up a real 
> onion service.

## Configuration

### Initial Setup

Running an onion service requires a keypair with a derived onion hostname. This 
container includes a script that can be used to generate these values automatically. 
To generate the keypair and derive the hostname run the following command:

```bash
podman run --rm ghcr.io/freedomofpress/onion-service:latest \
    gen-service-keypair
```

This command will give output that looks like this:

```bash
TOR_ONION_HOSTNAME=<base32...>.onion
TOR_ONION_V3_PUBLIC_KEY=<base64...>
TOR_ONION_V3_SECRET_KEY=<base64...>
```

The onion service container also needs to be informed where it can connect to the
clear-net site being proxied. This may be a public hostname (ex: `mysite.example.com`),
an internal hostname (ex: `mysite.example.local`), or a container service name (ex:
`mystack_nginx`) depending on the exact setup. Note that the provided hostname for
the site needs to be accessible from where the container is running, which may be
different from the hostname clear-net clients use to connect to the site.

To inform the onion service container about the proxied site set the `WEB_FRONTEND_HOST` 
environment variable to the hostname of the clear-net site and optionally
`WEB_FRONTEND_PORT` to the port where the clear-net site application is listening
(if unspecified it will default to port `80`).

Now the onion service container can be started:

```bash
podman run --name onion-service --detach \
    --env TOR_ONION_HOSTNAME=<base32...>.onion \
    --env TOR_ONION_V3_PUBLIC_KEY=<base64...> \
    --env TOR_ONION_V3_SECRET_KEY=<base64...> \
    --env WEB_FRONTEND_HOST=mysite.example.com \
    --env WEB_FRONTEND_PORT=80 \
    ghcr.io/freedomofpress/onion-service:latest
```

Once the container is started, copy the value of the `TOR_ONION_HOSTNAME` environment 
variable into the address bar of [Tor Browser](https://download.torproject.org/tor-browser-for-desktop/)
and connect to the proxied clear-net site over the Tor network!

> [!NOTE]
> Once a web service is exposed as an onion service, the clear-net web service can
> provide the `Onion-Location` header to point compatible clear-net clients to the
> Tor onion service. See the 
> [Tor documentation](https://community.torproject.org/onion-services/advanced/onion-location/) 
> for more information.

### Restricting Access

By default all onion services are publicly available to all users on the Tor network. To 
restrict access to the onion service in the container to only pre-approved users 
[Tor client authorization](https://community.torproject.org/onion-services/advanced/client-auth/) 
needs to be configured. Each client that is approved to access an onion service will need
a client keypair generated for them.

> [!CAUTION]
> The _"client keypair"_ used for client authorization is different than the _"service keypair"_ 
> used by the onion service and generated in the [#initial-setup](#initial-setup) section. 
> **Never share the service keypair!**

To generate a new client keypair for an onion service run the following command, replacing
the value of `ONION_HOSTNAME` with the hostname of the onion service that the client needs
to access:

```bash
podman run --rm ghcr.io/freedomofpress/onion-service \
    gen-client-keypair <ONION_HOSTNAME>.onion
```

This command will give output that looks like this:

```bash
CLIENT_PUBLIC_KEY=descriptor:x25519:<public key>
CLIENT_PRIVATE_KEY=<onion hostname>:descriptor:x25519:<private key>
CLIENT_PRIVATE_KEY_BROWSER=<private key>
```

Save the client public key to a local file with the extension `.auth`:

```bash
echo $CLIENT_PUBLIC_KEY >./my_client.auth
```

Once one or more client keypairs are generated the onion service needs to be updated to
inform it that client authorization is required. To do this, delete the onion-service
container and then recreate it with the below command that mounts the client public key
file into the `authorized_clients` directory:

```bash
podman run --name onion-service --detach ghcr.io/freedomofpress/onion-service:latest \
    --env TOR_ONION_HOSTNAME=<base32...>.onion \
    --env TOR_ONION_V3_PUBLIC_KEY=<base64...> \
    --env TOR_ONION_V3_SECRET_KEY=<base64...> \
    --env WEB_FRONTEND_HOST=mysite.example.com \
    --env WEB_FRONTEND_PORT=80 \
    --volume $(pwd)/my_client.auth:/authorized_clients/my_client.auth
```

Now when clients connect to the onion service in Tor Browser they will be prompted to
provide a key to access the site. Clients must provide the `CLIENT_PRIVATE_KEY_BROWSER`
value when prompted to access the site.

> [!NOTE]
> If a client needs access to multiple onion services, a single client keypair can be 
> generated that grants access to all of them by passing multiple onion service names
> to the script, like `gen-client-keypair <service1>.onion <service2>.onion ...`.
> 
> To successfully access the services the client keypair's public key will need to be 
> added to each onion service container.

> [!WARNING]
> This section is provided for demonstration purposes only.
> 
> It is **not recommended** to have onion service administrators generate client keypairs
> and then distribute the private keys to end users. Instead end users should generate 
> their own client keypair and send _only_ the public key to the onion service administrator.

### Reference

Complete configuration environment variable reference:

| Variable | Default | Usage |
| --- | --- | --- |
| `TOR_ONION_HOSTNAME` | - | Hostname of the onion service, must end in `.onion` |
| `TOR_ONION_V3_PUBLIC_KEY` | - | Public service key for the onion service |
| `TOR_ONION_V3_SECRET_KEY` | - | Private service key for the onion service |
| `TOR_ONION_V3_SECRET_KEY_FILE` | - | Path to the file to read the private service key from. If set, overrides the value of `TOR_ONION_V3_SECRET_KEY` |
| `WEB_FRONTEND_HOST` | - | Hostname of the upstream site server to expose as the onion service |
| `WEB_FRONTEND_PORT` | `80` | Port to connect to the upstream site server |
| `TOR_ONION_REMOTE_PORT` | `80` | Port that Tor should listen on for connections |
| `TOR_ONION_NAME` | `onion1` | Name of the  onion service configuration directory |
| `TOR_ONION_AUTHORIZED_CLIENTS_DIR` | `/authorized_clients/` | Path to where client authorization files (ending in `.auth`) are stored |
| `IS_DEMO` | `false` | Whether to run the container in demo mode. Not recommended for real world use |

## Licenses

This image is maintained by [The Freedom of the Press Foundation](https://freedom.press)
and is available under the [AGPL v3 License](LICENSE).

Submit issues in the source repository at [https://github.com/freedomofpress/container-onion-service/](https://github.com/freedomofpress/container-onion-service/).

"Tor" and "Tor Onion Service" are trademarks of [The Tor Project](https://torproject.org); 
all rights reserved.

The Tor software distributed by this container image ("tor core") is maintained by 
[The Tor Project](https://gitlab.torproject.org/tpo/core/tor) under the 
[BSD-3-Clause License](https://gitlab.torproject.org/tpo/core/tor/-/blob/main/LICENSE).

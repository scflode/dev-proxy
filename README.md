# dev-proxy

This repository contains a reverse proxy setup via
[traefik](https://traefik.io) that allows to have services with the same port
running locally at once.

## Prerequisites

In order to use the `dev-proxy` you need to have installed the following:

- Docker and docker-compose
- Install [mkcert](https://mkcert.dev):
  - `brew install mkcert nss` (macOS)
  - `choco install mkcert` (Win)
  - [Linux](https://github.com/FiloSottile/mkcert#linux)
- Clone this repository

## Usage

In order to use the dev-proxy use `make up` or `make up logs`. 

> This requires the dev-proxy to be setup properly as described in the section 
> "Setup".

### Add a new domain

To add a new domain you can use `make add domain="my-domain.localhost`.

### Remove a domain

To remove a domain you can use `make remove domain="my-domain.localhost"`.

### Persistent domains

All domains that are configured via the Makefile (see "Add a new domain") are 
also saved in a local `domains` file. This can also be ported between systems.

## Setup

To setup everything described below at once you can use `make setup`.

## Manual setup

### Init mkcert

In order to have TLS enabled you need to have `mkcert` set up and ready.

Create and setup local root certificate: `mkcert -install`

### Create certificates

Certificates are generated via [mkcert](https://mkcert.dev). For installation
instructions head there.

Install the default `localhost` certificate serving as fallback.

```
mkcert -cert-file certs/local-cert.pem -key-file certs/local-key.pem localhost 127.0.0.1 ::1
```

Install the wildcard certificate for `*.domain.localhost` domains.

```
mkcert -cert-file certs/wildcard.domain.localhost-cert.pem -key-file certs/wildcard.domain.localhost-key.pem "*.domain.localhost"
```

## Manual steps

### Add domains to `/etc/hosts/`

Although some browsers (like Chrome, Edge) are able to automatically point
`*.localhost` to `127.0.0.1` or `localhost` others like Safari are not. Also CLI
tools like `curl`, `ping` etc. cannot resolve these addresses.

Open your `/etc/hosts` file and add the following:

```
127.0.0.1 		my_app.domain.localhost my_other_app.domain.localhost
```

### Use dnsmasq instead hosts file (Homebrew)

To setup a real DNS server you can use `dnsmasq`.

The advantage is that for new domains no other step is need as to add it to the
project (see "Add new services").

For macOS use the following commands in order:

```
# Install dnsmasq via Homebrew
brew install dnsmasq
mkdir -pv $(brew --prefix)/etc/
# Configure `.localhost` resolving
echo 'address=/.localhost/127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf
echo 'port=53' >> $(brew --prefix)/etc/dnsmasq.conf
# Start persistent service
sudo brew services start dnsmasq
sudo mkdir -v /etc/resolver
# Add the nameserver to the resolver for `.localhost` domains
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/localhost'
scutil --dns
```

> For details and discussion see https://gist.github.com/ogrrd/5831371

## Add new services

To add additional services add the following (adapted) labels to the project's
`docker-compose.yml`:

```
version: "3.7"
services:
  my-app:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ./application:/app:delegated
  my-app-nginx:
    image: nginx:latest
    links:
      - my-app
    networks:
      - default
      - dev-proxy
    volumes:
      - ./application:/app:delegated
      - ./nginx-local-dev.conf:/etc/nginx/conf.d/default.conf
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=dev-proxy"
      - "traefik.http.routers.my-app-insecure.rule=Host(`my-app.domain.localhost`)"
      - "traefik.http.routers.my-app-insecure.entrypoints=web"
      - "traefik.http.routers.my-app-insecure.middlewares=my-app-secure"
      - "traefik.http.middlewares.my-app-secure.redirectscheme.scheme=https"
      - "traefik.http.routers.my-app.entrypoints=web-ssl"
      - "traefik.http.routers.my-app.rule=Host(`my-app.domain.localhost`)"
      - "traefik.http.routers.my-app.tls=true"

networks:
  dev-proxy:
    external: true
```

A short explanation:

- use the external (global) `dev-proxy` network
- the `labels` control how traefik will route the traffic
- the example above shows addtionally the SSL redirect
  (from `my-app-insecure` to `my-app-secure` via `https`
- the `networks` must contain both the external proxy (for routing) and the
  `default` one for inter-service communication (in this case php-fpm <-> nginx)

> You need to update the `/etc/hosts` file with the new subdomain as well.
> The `dev-proxy` does not need to get restarted as it watches any changes on
> the `dev-proxy` network.

## License

MIT


# dev-proxy

This repository contains a reverse proxy setup via
[traefik](https://traefik.io) that allows to have services with the same port
running locally at once.

## Prerequisites

In order to use the `dev-proxy` you need to have installed the following:

- Docker
- Install [mkcert](https://mkcert.dev):
  - `brew install mkcert nss` (macOS)
  - `choco install mkcert` (Win)
  - [Linux](https://github.com/FiloSottile/mkcert#linux)
- Clone this repository

## Setup

With the prerequisites satisfied you can run `make setup`. This automatically 
sets up everything needed to use the `dev-proxy`.

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

To setup everything described below at once you can use `make setup`. This 
target is idempotent.

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

### Configure reverse proxy

For each new domain you need to add a configuration to the reverse proxy.

This is done in the folder `config/dynamic` with a file named 
`domain.localhost.yml` having content like this:

```
tls:
  certificates:
    - certFile: "/etc/certs/wildcard.domain.localhost-cert.pem"
      keyFile: "/etc/certs/wildcard.domain.localhost-key.pem"
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
  app:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ./application:/app:delegated
  nginx:
    image: nginx:latest
    links:
      - my-app
    volumes:
      - ./application:/app:delegated
      - ./nginx-local-dev.conf:/etc/nginx/conf.d/default.conf
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=myapp"
      - "traefik.http.routers.my-app-insecure.rule=Host(`my-app.domain.localhost`)"
      - "traefik.http.routers.my-app-insecure.entrypoints=web"
      - "traefik.http.routers.my-app-insecure.middlewares=my-app-secure"
      - "traefik.http.middlewares.my-app-secure.redirectscheme.scheme=https"
      - "traefik.http.routers.my-app.entrypoints=web-ssl"
      - "traefik.http.routers.my-app.rule=Host(`my-app.domain.localhost`)"
      - "traefik.http.routers.my-app.tls=true"

networks:
  default:
    name: myapp
```

A short explanation:

- name the `default` network to something static like `myapp` in this case
- the `labels` control how traefik will route the traffic
- the example above shows addtionally the SSL redirect
  (from `my-app-insecure` to `my-app-secure` via `https`

> You need to update the `/etc/hosts` file with the new subdomain as well.

> Naming the `default` network is important as the reverse proxy needs to be
> configured to using it.

### Networking

> As described above the network (even the `default`) should have a completely
defined name.

Each network that should be resolved via the `dev-proxy` needs to be added via
`make add-network network=myapp`. The `dev-proxy` is restarted automatically. 

> The networks are saved in the `networks` file and will be connected on each
> start of the `dev-proxy`.

To remove a network again call `make remove-network network=myapp`. This will
remove the network from `networks` and restart the `dev-proxy`.

### Access to database (PostgreSQL) containers

An important part of development with databases is to access those. This is
possible by configuring exposed ports in the `docker-compose.yml` but leads to
overlapping ports (e.g. `5432` for PostreSQL might be used as port for 
different projects).

One solution would be to have random ports assigned (with the downside to look
those up every time), another could be to have a "global" database server 
handling all the databases of all the projects, a third to reserve / 
"namespace" different ports, like `5432`, `5433` etc.. Neither of those is very 
elegant.

The latest Traefik version (3, currently in beta) allows Host SNI routing that
can be used especially for PostgreSQL database server (as those are not HTTP 
but only TCP).

The project setup looks like the following:

```
version: "3.7"
services:
  my-app:
    build:
      context: .
      dockerfile: Dockerfile
    depends_on:
      - db
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=myapp"
      - "traefik.http.routers.my-app-insecure.rule=Host(`my-app.domain.localhost`)"
      - "traefik.http.routers.my-app-insecure.entrypoints=web"
      - "traefik.http.routers.my-app-insecure.middlewares=my-app-secure"
      - "traefik.http.middlewares.my-app-secure.redirectscheme.scheme=https"
      - "traefik.http.routers.my-app.entrypoints=web-ssl"
      - "traefik.http.routers.my-app.rule=Host(`my-app.domain.localhost`)"
      - "traefik.http.routers.my-app.tls=true"

  db:
    image: postgres:14.5-alpine
    command: 'postgres -c "max_connections=200"'
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - type: volume
        source: postgres-data
        target: /var/lib/postgresql/data
        volume:
          nocopy: true
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=myapp"
      - "traefik.tcp.routers.my-app-db.rule=HostSNI(`my-app-db.domain.localhost`)"
      - "traefik.tcp.routers.my-app-db.entryPoints=postgres"
      - "traefik.tcp.routers.my-app-db.tls=true"
      - "traefik.tcp.services.my-app-db-svc.loadbalancer.server.port=5432"
      
networks:
  default:
    name: myapp
```

The example above will expose `my-app.domain.localhost` as usual via port `443`
but also expose `my-app-db.domain.localhost` on port `5432` for the database.
With this you can establish a database connection from the tool of your choice.

## License

MIT


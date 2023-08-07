# dev-proxy

> **Warning**
> This is the next iteration with HostSNI support for easier local database 
> access. This might still have rough edges. Refer to `main` if you encounter 
> issues.

This repository contains a reverse proxy setup via [traefik](https://traefik.io) 
that allows to have multiple services with the same port running locally at 
once without port juggling.

Further it allows to have full TLS support by leveraging [mkcert](https://mkcert.dev).

The Docker container start when the Docker daemon starts (so maybe on startup). This means you do not need to worry about it.

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
sets up everything needed to use the `dev-proxy`. This target is idempotent.

## Usage

In order to use the dev-proxy use `make up` or `make up logs`. 

> This requires the dev-proxy to be setup properly as described in the section 
> "Setup".

### Add a new domain and network

To add a new domain you can use `make add domain="my-domain.localhost network="my_network"`.

### Example setup of an existing project

To setup an already configured project (see [Services](./docs/04_services.md)) 
called `app` (this is the container service you want to access) with the 
network called `my_network` and the desired domain `my_domain` you run:

```
make add domain=my_domain network=my_network
make up
```

> **Important**
> Next please check [Domains](./docs/02_domains.md) for information about mapping 
> the domains to `127.0.0.1` either via `/etc/hosts` or `dnsmasq`.

The you can access the project via your browser as [https://app.my_domain.localhost].

If the project has the database labels also configured (or has a database at 
all) you can then given the database service is configured as `db` access 
the database locally via the host `db.my_domain.localhost` port `15432` (!) and 
the respective username and password as well as other project specific settings.

### Remove a domain and network

To remove a domain you can use `make remove domain="my-domain.localhost" network="my_network"`.

## Troubleshooting

When you encounter problems with not reachable services you can open 
[https://localhost]. This shows the Traefik dashboard.

Another useful thing could be to run `make logs` that tails the Traefik 
container logs.

## More information

For all available targets you can run `make` or `make help`.

- [Setup](./docs/01_setup.md)
- [Domains](./docs/02_domains.md)
- [Networking](./docs/03_networking.md)
- [Services](./docs/04_services.md)
- [Databases](./docs/05_databases.md)
- [Internals](./docs/06_internals.md)

## License

MIT


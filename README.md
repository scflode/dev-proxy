# dev-proxy

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

### Add a new domain

To add a new domain you can use `make add domain="my-domain.localhost`.

### Remove a domain

To remove a domain you can use `make remove domain="my-domain.localhost"`.

### Add a new network

To add a new network you can use `make add-network network=mynetwork`.

### Remove a network

To remove a network you can use `make remove-network network=mynetwork`.

### Example setup of an existing project

To setup an already configured project (see [services](docs/04_services.md)) 
called `app` (this is the container service you want to access) with the 
network called `my_network` and the desired domain `my_domain` you run:

```
make add domain=my_domain
make add-network network=my_network
```

The you can access the project via your browser as [https://app.my_domain.localhost].

If the project has the database labels also configured (or has a database at 
all) you can then given the database service is configured as `db` access 
the database locally via the host `db.my_domain.localhost` port `5432` and the 
respective username and password as well as other project specific settings.

## More information

- [Setup](docs/01_setup.md)
- [Domains](docs/02_domains.md)
- [Networking](docs/03_networking.md)
- [Services](docs/04_services.md)
- [Postgres](docs/05_postgres.md)
- [Internals](docs/06_internals.md)

## License

MIT


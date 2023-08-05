# Setup

This documentation takes a look at how to manually setup what the `make setup`
target does automatically.

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


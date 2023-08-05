# Internals

## How does `dev-proxy` work

`dev-proxy` uses some files to keep track what is being routed as well as 
the certificates and their mapping.

### Domains

All domains that are configured via the `Makefile` (see "Add a new domain") are 
also saved in a local `domains` file. This can also be ported between systems.

### Networks

Configured networks are placed in the `networks` file. When the `dev-proxy` is
started it traverses this file and sets all the networks to be visible to 
Traefik.

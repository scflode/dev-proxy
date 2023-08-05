# Networking

To avoid different projects interfering with each other (e.g. services have the
same service name) each project needs to define their own (statically named) 
network. This allows for complete separation of those projects.

Each network that should be resolved via the `dev-proxy` needs to be added via
`make add domain=my_domain network=my_network`. The `dev-proxy` is restarted 
automatically.

> The networks are saved in the `networks` file and will be connected on each
> start of the `dev-proxy`.

To remove a network call `make remove domain=my_domain network=my_network`. 
This will remove the network from `networks` file and restart the `dev-proxy`.


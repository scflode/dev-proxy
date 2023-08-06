# Services

This section describes how new services or apps are setup. This mainly 
resembles how Traefik is configured.

### Configure new service

To add services take and adapt the following labels to the project's
`docker-compose.yml`:

```
version: "3.7"
services:
  app:
    image: my_image:latest
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=myapp"
      - "traefik.http.service_names.my-app.loadbalancer.server.port=80"
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
  (from `my-app-insecure` to `my-app-secure` via `https`)

> You need to update the `/etc/hosts` file if you do not have setup `densmask`
with the new subdomain as well.

> Naming the `default` network is important as the reverse proxy needs to access 
it. The Docker Compose dynamic network naming (`FOLDER_default`) might cause 
issues when it is changed.


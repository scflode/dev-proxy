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
      - "traefik.docker.network=my_network"
      - "traefik.http.service_names.my_project_app_service.loadbalancer.server.port=80"
      - "traefik.http.routers.my_project_app_unsecure.rule=Host(`app.my-domain.localhost`)"
      - "traefik.http.routers.my_project_app_unsecure.entrypoints=web"
      - "traefik.http.routers.my_project_app_unsecure.middlewares=my_project_app_secure_middleware"
      - "traefik.http.middlewares.my_project_app_secure_middleware.redirectscheme.scheme=https"
      - "traefik.http.routers.my_project_app_secure.entrypoints=web-ssl"
      - "traefik.http.routers.my_project_app_secure.rule=Host(`app.my-domain.localhost`)"
      - "traefik.http.routers.my_project_app_secure.tls=true"

networks:
  default:
    name: my_network
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


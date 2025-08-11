# Databases

> [!NOTE]
> Currently out of the box PostgreSQL is configured only. For supporting e.g.
> MySQL you can adapt the `config/base.yml` and `scripts/start` accordingly.

## Access to database (PostgreSQL) containers

An important part of development with databases is to access those from outside.
This is possible by configuring exposed ports in the `docker-compose.yml` but 
leads to overlapping ports (e.g. `5432` for PostreSQL might be used as port for 
different projects).

One solution would be to have random ports assigned (with the downside to look
those up every time), another could be to have a "global" database server 
handling all the databases of all the projects, a third to reserve / 
"namespace" different ports, like `5432`, `5433` etc.. Neither of those is very 
elegant and might differ for different developers in the team.

The latest Traefik version (3, currently in beta) allows Host SNI routing that
can be used especially for PostgreSQL database server (as those are not HTTP 
but only TCP).

The project setup looks like the following (for completeness the main service 
is included as well):

```
version: "3.7"
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    depends_on:
      - db
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=my_network"
      - "traefik.http.services.my_project_app_service.loadbalancer.server.port=4000"
      - "traefik.http.routers.my_project_app_unsecure.rule=Host(`app.my-domain.localhost`)"
      - "traefik.http.routers.my_project_app_unsecure.entrypoints=web"
      - "traefik.http.routers.my_project_app_unsecure.middlewares=my_project_app_secure_middleware"
      - "traefik.http.middlewares.my_project_app_secure_middleware.redirectscheme.scheme=https"
      - "traefik.http.routers.my_project_app_secure.entrypoints=web-ssl"
      - "traefik.http.routers.my_project_app_secure.rule=Host(`app.my-domain.localhost`)"
      - "traefik.http.routers.my_project_app_secure.tls=true"

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
      - "traefik.docker.network=my_network"
      - "traefik.tcp.routers.my_project_db.rule=HostSNI(`db.my-domain.localhost`)"
      - "traefik.tcp.routers.my_project_db.entryPoints=postgres"
      - "traefik.tcp.routers.my_project_db.tls=true"
      - "traefik.tcp.services.my_project_db_service.loadbalancer.server.port=5432"
      
networks:
  default:
    name: my_network
```

The example above will expose `app.my-domain.localhost` as usual via port `443`
but also expose `db.my-domain.localhost` on port `15432` for the database.
With this you can establish a database connection from the tool of your choice.

> [!IMPORTANT]
> Note that for compatibility reasons the exposed port for PostgreSQL is
> `15432` instead of `5432`. That is because one off tests without the proxy
> should be as easy as possible and some people might have a local PostgreSQL
> installation that might not be desired to be uninstalled.
> 
> Another advantage is that also here as for normal services you have TLS setup 
which might save you from some headaches when deploying to production (in case 
the database is TLS secured that is).


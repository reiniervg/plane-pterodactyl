# Plane CE True All-In-One — Pterodactyl ptero4

This is the version where **everything really runs in one Pterodactyl server/container**.

Inside the single container:

- Plane CE v1.4.0 application stack
- PostgreSQL
- Redis
- RabbitMQ
- MinIO

No separate Pterodactyl database, Redis server, RabbitMQ server, MinIO server or Docker Compose stack is required.

Plane's official deployment normally runs these as separate containers. The ptero4 wrapper deliberately combines them because this egg is designed for a simple one-server Pterodactyl deployment.

## Pterodactyl configuration

Recommended:

```text
RAM: 8192 MB
CPU: 400% if available
Disk: 30 GB minimum
Allocation: one TCP port, e.g. 30080
```

Only one allocation is needed.

Internal services are loopback-only:

```text
127.0.0.1:5432  PostgreSQL
127.0.0.1:6379  Redis
127.0.0.1:5672  RabbitMQ
127.0.0.1:9000  MinIO API
127.0.0.1:9090  MinIO console (not published)
```

They do not need firewall rules or extra Pterodactyl allocations.

## Egg variables

Normally change only:

```text
DOMAIN_NAME=plane.district046.nl
```

Everything else is generated/configured automatically.

The image generates unique random values for:

- PostgreSQL password
- Redis password
- RabbitMQ password
- MinIO access/secret keys
- Django SECRET_KEY
- Plane LIVE_SERVER_SECRET_KEY

They are persisted in:

```text
/home/container/.plane-internal-secrets
```

Do not delete that file on an existing installation.

## GitHub build

Put these files in the root of `reiniervg/plane-pterodactyl` and push to main.

The workflow publishes:

```text
ghcr.io/reiniervg/pterodactyl-plane:v1.4.0-ptero4
```

Then change the existing Plane Pterodactyl server Docker image to that tag.

For a clean switch from the old external-dependency test build, a Pterodactyl reinstall is recommended because the new version creates its own persistent embedded service directories.

## SSL

Plane listens on the primary Pterodactyl allocation as HTTP.

Example:

```text
Internet HTTPS :443
   -> Nginx on host
   -> http://57.131.143.33:30080
   -> Plane
```

Keep `APP_PROTOCOL=https`.

Do not expose PostgreSQL, Redis, RabbitMQ or MinIO publicly.

## Backups

Back up the complete Pterodactyl server directory. Most importantly:

```text
/home/container/services/postgres
/home/container/services/redis
/home/container/services/rabbitmq
/home/container/services/minio
/home/container/.plane-internal-secrets
/home/container/plane.env
```

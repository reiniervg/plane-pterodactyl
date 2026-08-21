# Plane CE on Pterodactyl

This package contains a Pterodactyl egg for **Plane Community Edition v1.4.0**.

## Why a wrapper image is required

Plane's official AIO image is not directly compatible with current Pterodactyl Wings:

- Wings runs server containers as the Pterodactyl UID/GID.
- Wings uses a read-only root filesystem.
- Plane's official AIO writes runtime state under `/app`.
- Plane's AIO Supervisor config contains `user=root`.

The included Dockerfile keeps Plane's official application filesystem but redirects writable state to `/home/container`, removes the root-only Supervisor setting, and uses a Pterodactyl-compatible entrypoint.

## Important: Plane still needs four external services

Plane's AIO image combines the Plane application components, but it still requires:

1. PostgreSQL
2. Valkey/Redis
3. RabbitMQ
4. S3-compatible object storage, for example MinIO

An optional Compose stack is included under `dependencies/`.

## 1. Build the Pterodactyl-compatible Plane image

Create a GitHub repository and upload:

- `Dockerfile`
- `ptero-entrypoint.sh`
- `.github/workflows/build.yml`

Push to `main` or manually run the workflow.

It publishes:

```text
ghcr.io/YOUR_GITHUB_OWNER/pterodactyl-plane:v1.4.0
ghcr.io/YOUR_GITHUB_OWNER/pterodactyl-plane:latest
```

Make the GHCR package public, or configure GHCR credentials in Wings.

Then edit `egg-plane-pterodactyl.json` and replace:

```text
ghcr.io/replace-me/pterodactyl-plane:v1.4.0
```

with your actual image.

## 2. Optional dependency stack

Copy:

```text
dependencies/.env.example
```

to:

```text
dependencies/.env
```

Change all passwords and set `BIND_IP` to a private IP reachable from Plane.

Start:

```bash
cd dependencies
docker compose up -d
```

Do not publicly expose ports 5432, 6379, 5672 or 9000.

Example Plane variables for `BIND_IP=10.0.0.10`:

```text
DATABASE_URL=postgresql://plane:POSTGRES_PASSWORD@10.0.0.10:5432/plane
REDIS_URL=redis://:REDIS_PASSWORD@10.0.0.10:6379/0
AMQP_URL=amqp://plane:RABBITMQ_PASSWORD@10.0.0.10:5672/plane
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=plane
AWS_SECRET_ACCESS_KEY=MINIO_SECRET_KEY
AWS_S3_BUCKET_NAME=uploads
AWS_S3_ENDPOINT_URL=http://10.0.0.10:9000
```

URL-encode reserved characters in passwords before putting them in a URL.

## 3. Import the egg

In Pterodactyl:

```text
Admin Panel
→ Nests
→ choose/create an Applications nest
→ Import Egg
→ egg-plane-pterodactyl.json
```

Create a Plane server with one TCP allocation, for example:

```text
30080
```

Do not use port 80 or 443 inside the Pterodactyl container.

Recommended starting resources:

```text
Memory: 4096 MB minimum, 6144–8192 MB preferred
CPU:    200%+ depending on the node
Disk:   10 GB+
Port:   one TCP allocation, e.g. 30080
```

## 4. Configure Plane

Set:

```text
DOMAIN_NAME=plane.example.com
APP_PROTOCOL=https
```

and fill in the PostgreSQL, Redis, RabbitMQ and S3 variables.

`SECRET_KEY` and `LIVE_SERVER_SECRET_KEY` can stay blank. Plane generates secure random values on first boot and the wrapper persists `plane.env` in `/home/container`.

The Pterodactyl backend is plain HTTP:

```text
http://PTERODACTYL_NODE_IP:PTERODACTYL_ALLOCATION
```

## 5. HTTPS with Nginx + Let's Encrypt

Copy `nginx-plane.conf.example` into your Nginx config.

Replace:

```text
plane.example.com
127.0.0.1:30080
```

with the real domain and Plane allocation.

Install Nginx and Certbot:

```bash
apt update
apt install -y nginx certbot python3-certbot-nginx
```

Check and reload Nginx:

```bash
nginx -t
systemctl reload nginx
```

Request the certificate:

```bash
certbot --nginx -d plane.example.com
```

Certbot installs the certificate and can enable HTTP → HTTPS redirect.

TLS intentionally terminates at Nginx. Plane talks HTTP only between Nginx and the Pterodactyl allocation, while `APP_PROTOCOL=https` makes Plane generate public HTTPS URLs.

The Nginx example forwards WebSocket headers for Plane's live/collaboration traffic.

## 6. First administrator

After Plane starts, open:

```text
https://plane.example.com/god-mode/
```

Use the trailing slash.

Complete the setup and create the first administrator.

## Updating Plane

The package is pinned to Plane v1.4.0.

For an update:

1. Back up `plane.env` and the external dependency data.
2. Change `PLANE_VERSION` in the build workflow.
3. Build/push a new wrapper image.
4. Point the egg/server at the new pinned image tag.
5. Restart and verify migrations.

Avoid switching production directly to RC/prerelease tags.
